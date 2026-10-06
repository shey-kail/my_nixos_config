#!/usr/bin/env python3
"""看 dae 当前在用哪个节点。

思路:
  1. 从 dae 的活跃 TCP 连接里找出它正在连的服务器 IP(dae 用 eBPF 转发,
     但到节点的出站连接仍是普通 socket,`ss` 能看到)
  2. 解析订阅文件(/etc/dae/{main,backup}.sub)里的节点链接,得到
     节点名 → 服务器地址
  3. 解析服务器地址为 IP 并匹配,得出"当前使用: <节点名>"

用法(需要 root 才能读 /etc/dae/*.sub):
    sudo python3 modules/nixos/base/dae/which-node.py

可选参数:
    --subs-dir DIR   订阅目录(默认 /etc/dae)
    --list           只列出所有节点及其服务器 IP,不做匹配
"""

import argparse
import base64
import json
import pathlib
import re
import socket
import subprocess
import sys
import urllib.parse


def b64pad(s: str) -> str:
    return s + "=" * (-len(s) % 4)


def decode_sub(path: pathlib.Path) -> list[str]:
    """订阅内容可能是 base64 整体编码,也可能是明文;两种都兼容。"""
    raw = path.read_text(errors="ignore")
    text = raw
    if not re.search(r"^[a-z0-9]+://", raw.strip(), re.M | re.I):
        try:
            text = base64.b64decode(b64pad(raw.strip())).decode(errors="ignore")
        except Exception:
            text = raw
    return [ln.strip() for ln in text.splitlines() if ln.strip()]


def parse_link(link: str) -> tuple[str, str] | None:
    """从节点链接里取出 (名字, 服务器地址)。"""
    scheme = link.split("://", 1)[0].lower()
    rest = link.split("://", 1)[1] if "://" in link else link
    frag = ""
    if "#" in rest:
        rest, frag = rest.split("#", 1)
        frag = urllib.parse.unquote(frag)

    # vmess://<base64 json>
    if scheme == "vmess":
        try:
            js = json.loads(base64.b64decode(b64pad(rest)).decode(errors="ignore"))
            return (js.get("ps") or frag or "vmess", js.get("add") or "")
        except Exception:
            return None

    # 去掉查询串,取 userinfo@host:port
    rest = rest.split("?", 1)[0]
    if "@" not in rest:
        return None
    hostport = rest.rsplit("@", 1)[1]
    if hostport.startswith("["):  # IPv6
        host = hostport[1 : hostport.find("]")]
    else:
        host = hostport.rsplit(":", 1)[0]
    return (frag or scheme, host)


def resolve(host: str) -> list[str]:
    if not host:
        return []
    if re.fullmatch(r"[\d.]+", host):
        return [host]
    try:
        infos = socket.getaddrinfo(host, None)
    except Exception:
        return []
    return sorted({i[4][0] for i in infos if ":" not in i[4][0]})


def active_peers() -> list[str]:
    """dae 正在连的服务器 IP(排除本机/内网)。"""
    try:
        out = subprocess.run(
            ["ss", "-tnH", "state", "established"],
            capture_output=True,
            text=True,
            timeout=10,
        ).stdout
    except Exception:
        return []
    peers = []
    for line in out.splitlines():
        cols = line.split()
        if len(cols) < 4:
            continue
        peer = cols[-1]  # 最后一列是 Peer Address:Port(有无 State 列都适用)
        ip = peer[1 : peer.find("]")] if peer.startswith("[") else peer.rsplit(":", 1)[0]
        if ip.startswith(("127.", "10.", "192.168.", "172.16.", "172.17.", "172.18.", "172.19.")) or ip.startswith("169.254"):
            continue
        peers.append(ip)
    return peers


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("--subs-dir", default="/etc/dae")
    ap.add_argument("--list", action="store_true", help="只列出节点与服务器 IP")
    args = ap.parse_args()

    subdir = pathlib.Path(args.subs_dir)
    files = []
    for name in ("main.sub", "backup.sub"):
        p = subdir / name
        try:
            if p.is_file():
                files.append(p)
        except OSError:
            pass
    if not files:
        print(f"读不到订阅文件({subdir}/{{main,backup}}.sub)。", file=sys.stderr)
        print(f"该目录是 0700 root,请用 root 运行:", file=sys.stderr)
        print(f"    sudo python3 {sys.argv[0]}", file=sys.stderr)
        return 2

    nodes: list[tuple[str, str, list[str]]] = []
    for f in files:
        tag = f.stem  # main / backup
        for link in decode_sub(f):
            parsed = parse_link(link)
            if parsed:
                name, host = parsed
                nodes.append((f"[{tag}] {name}", host, resolve(host)))

    if not nodes:
        print("订阅里没解析出节点;格式可能不支持,可手动查看:", file=sys.stderr)
        for f in files:
            print(f"    sudo base64 -d {f} | head", file=sys.stderr)
        return 1

    if args.list:
        print(f"共 {len(nodes)} 个节点:")
        for name, host, ips in nodes:
            print(f"  {name:<40} {host:<28} {'/'.join(ips) if ips else '(未解析)'}")
        return 0

    peers = active_peers()
    if not peers:
        print("没有抓到达 dae 的活跃出站连接(可能当前无流量,先 curl 一下再试)")
        return 1

    counts: dict[str, int] = {}
    for ip in peers:
        counts[ip] = counts.get(ip, 0) + 1

    hit = [(n, h, ip) for (n, h, ips) in nodes for ip in ips if ip in counts]
    print("dae 当前活跃出站(按连接数):")
    for ip, c in sorted(counts.items(), key=lambda kv: -kv[1])[:5]:
        print(f"  {ip:<20} {c} 条连接")
    if hit:
        print("\n→ 当前使用节点:")
        for name, host, ip in sorted(hit, key=lambda x: -counts[x[2]]):
            print(f"  {name}   ({host} = {ip}, {counts[ip]} 条连接)")
    else:
        print("\n没能把 IP 对回节点名(节点前面可能有 CDN/中转)。上面第一个 IP 就是当前服务器。")
    return 0


if __name__ == "__main__":
    sys.exit(main())
