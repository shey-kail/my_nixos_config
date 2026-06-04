"""netflow web UI - Flask port of upstream LuCI controller (netflow.lua).

Routes:
  GET  /              render main page (template built from upstream main.htm)
  POST /api           forward form to backend /api/{action} (KNOWN_KEYS whitelist)
  POST /upload_core   forward multipart corefile to backend /api/core_install_upload
"""

import os

import requests
from flask import Flask, jsonify, request

app = Flask(__name__)

BACKEND_PORT = os.environ.get("NETFLOW_API_PORT", "9190")
API_BASE = f"http://127.0.0.1:{BACKEND_PORT}"

# build-time 注入的模板路径(由 ui-module.nix 的 pkgs.substitute 生成)
TEMPLATE_PATH = os.environ.get("NETFLOW_TEMPLATE", "")
with open(TEMPLATE_PATH, encoding="utf-8") as _f:
    TEMPLATE = _f.read()

# 对齐 upstream netflow.lua:action_api 接受的 known_keys(白名单防注入)
KNOWN_KEYS = ("email", "password", "group", "node", "mode", "state", "run_mode", "source")


@app.route("/")
def index():
    return TEMPLATE


@app.route("/api", methods=["POST"])
def api():
    """对齐 upstream netflow.lua:action_api()
    1. 读 form 里的 'action' 字段
    2. 从 KNOWN_KEYS 白名单读允许的字段
    3. POST JSON 到 http://127.0.0.1:{BACKEND_PORT}/api/{action}
    4. 透传 backend 响应
    """
    action = request.form.get("action", "")
    if not action or not action.replace("_", "").isalnum():
        return jsonify({"status": "error", "message": "invalid action"}), 400

    params = {k: request.form.get(k) for k in KNOWN_KEYS if request.form.get(k)}
    try:
        r = requests.post(f"{API_BASE}/api/{action}", json=params, timeout=45)
    except requests.RequestException as e:
        return jsonify({"status": "error", "message": f"后端未响应: {e}"}), 502

    return (r.text, r.status_code, {"Content-Type": "application/json"})


@app.route("/upload_core", methods=["POST"])
def upload_core():
    """对齐 upstream netflow.lua:action_upload_core()
    接收 multipart 'corefile' 字段,流式转发到 backend /api/core_install_upload。
    """
    if "corefile" not in request.files:
        return jsonify({"status": "error", "message": "no corefile"}), 400

    f = request.files["corefile"]
    try:
        r = requests.post(
            f"{API_BASE}/api/core_install_upload",
            files={"corefile": (f.filename or "core.gz", f.stream, f.mimetype or "application/octet-stream")},
            timeout=300,
        )
    except requests.RequestException as e:
        return jsonify({"status": "error", "message": f"后端未响应: {e}"}), 502

    return (r.text, r.status_code, {"Content-Type": "application/json"})


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=int(os.environ.get("PORT", 9090)), debug=False)
