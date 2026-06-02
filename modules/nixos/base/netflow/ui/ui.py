#!/usr/bin/env python3
"""Simplified netflow web UI - proxies to backend API"""

import os
import requests
from flask import Flask, render_template_string, jsonify, request

app = Flask(__name__)

BACKEND_PORT = os.environ.get('NETFLOW_API_PORT', '9190')
API_BASE = f'http://127.0.0.1:{BACKEND_PORT}'

HTML_TEMPLATE = '''
<!DOCTYPE html>
<html>
<head>
  <title>Netflow Control Panel</title>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #1a1a2e; color: #eee; }
    .container { max-width: 800px; margin: 0 auto; }
    h1 { color: #00d4ff; }
    .card { background: #16213e; padding: 20px; border-radius: 10px; margin: 10px 0; }
    .status { display: flex; justify-content: space-between; }
    .btn { padding: 10px 20px; border: none; border-radius: 5px; cursor: pointer; margin: 5px; }
    .btn-on { background: #00d4ff; color: #000; }
    .btn-off { background: #e94560; color: #fff; }
    .node { background: #0f3460; padding: 10px; margin: 5px 0; border-radius: 5px; }
    .error { color: #e94560; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Netflow Control Panel</h1>

    <div class="card">
      <h2>Service Status</h2>
      <div class="status">
        <span>Backend API:</span>
        <span id="api-status">Checking...</span>
      </div>
    </div>

    <div class="card">
      <h2>Quick Actions</h2>
      <button class="btn btn-on" onclick="switchMode('rule')">Rule Mode</button>
      <button class="btn btn-on" onclick="switchMode('global')">Global Mode</button>
      <button class="btn btn-off" onclick="switchMode('disable')">Disable</button>
    </div>

    <div class="card">
      <h2>Nodes</h2>
      <div id="nodes">Loading...</div>
    </div>
  </div>

  <script>
    async function api(method, path, data) {
      try {
        const r = await fetch(API_BASE + path, { method, headers: {'Content-Type': 'application/json'}, body: data ? JSON.stringify(data) : undefined });
        return await r.json();
      } catch (e) {
        return { error: e.message };
      }
    }

    async function updateStatus() {
      const status = await api('GET', '/api/status');
      document.getElementById('api-status').textContent = status.error || 'Online';
    }

    async function switchMode(mode) {
      if (mode === 'disable') {
        await api('POST', '/api/disable');
      } else {
        await api('POST', '/api/enable', { mode });
      }
      updateStatus();
    }

    updateStatus();
    setInterval(updateStatus, 5000);
  </script>
</body>
</html>
'''

@app.route('/')
def index():
    return render_template_string(HTML_TEMPLATE)

@app.route('/api/<path:path>', methods=['GET', 'POST'])
def proxy(path):
    try:
        url = f'{API_BASE}/api/{path}'
        if request.method == 'POST':
            r = requests.post(url, json=request.json, timeout=5)
        else:
            r = requests.get(url, timeout=5)
        return jsonify(r.json())
    except Exception as e:
        return jsonify({'error': str(e)})

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 9090)), debug=False)