#!/usr/bin/env python3
"""校验 config.dae 里 group 过滤器分层是否符合预期。

dae 的优先级是用「同一 group 内叠加 add_latency 偏置」实现的:层越靠前偏置越小,
同层内再按实时延迟优选。这个脚本把 config.dae 里的 filter 行解析出来,对一批
真实节点名逐条求值,输出:

  * 每个节点落在哪一层(即最终偏置多少 ms)
  * 是否有节点同时命中多层(那会让 dae 行为不确定,属于设计缺陷)
  * 被排除的节点(假节点/不该用的区域)

用法:
    # 1) 从 sing-box 的 Clash API 导出节点名(任选其一,只要一行一个名字)
    curl -s http://127.0.0.1:9090/proxies | \\
      python3 -c 'import json,sys; d=json.load(sys.stdin)["proxies"]; \\
        print("\\n".join(k for k,v in d.items() if v.get("type") not in
        ("Selector","URLTest","Direct","Reject","Compatible","Pass")))' > /tmp/nodes.txt

    # 2) 校验
    python3 modules/nixos/base/dae/verify-filters.py /tmp/nodes.txt

注意:节点名的区域/倍率写法要与 config.dae 里的关键词对得上,否则会落到"其他"层。
"""

import pathlib
import re
import sys

CONFIG = pathlib.Path(__file__).with_name("config.dae")


def parse_group(text: str, group: str) -> list[dict]:
    """取出 <group> { ... } 块里的所有 filter 行。"""
    m = re.search(rf"\n    {group} \{{(.*?)\n    \}}", text, re.S)
    if not m:
        return []
    out = []
    for raw in m.group(1).split("\n"):
        raw = raw.strip()
        if not raw.startswith("filter:"):
            continue
        line = raw[len("filter:") :].strip()
        off = 0
        mo = re.search(r"\[add_latency:\s*(-?\d+)s\]", line)
        if mo:
            off = int(mo.group(1))
        line = re.sub(r"\[add_latency:[^\]]*\]", "", line).strip()

        sub = re.search(r"subtag\((\w+)\)", line)
        clauses = []
        for cl in line.split(" && "):
            cl = cl.strip()
            neg = cl.startswith("!")
            cl2 = cl[1:] if neg else cl
            if (mr := re.match(r"name\(regex:\s*'([^']*)'\)", cl2)):
                clauses.append(("regex", neg, mr.group(1)))
            elif (mk := re.match(r"name\(keyword:\s*'([^']*)'\)", cl2)):
                clauses.append(("substr", neg, mk.group(1)))
            elif (me := re.match(r"name\(([^)]*)\)", cl2)):
                clauses.append(("exact", neg, [x.strip().strip("'") for x in me.group(1).split(",")]))
        out.append({"sub": sub.group(1) if sub else None, "clauses": clauses, "off": off})
    return out


def matches(f: dict, name: str, sub: str) -> bool:
    if f["sub"] and f["sub"] != sub:
        return False
    for kind, neg, val in f["clauses"]:
        if kind == "regex":
            hit = re.search(val, name) is not None
        elif kind == "substr":
            hit = val in name
        else:
            hit = name in val
        if neg == hit:
            return False
    return True


def main() -> int:
    nodes_file = pathlib.Path(sys.argv[1] if len(sys.argv) > 1 else "/tmp/nodes.txt")
    nodes = [n for n in nodes_file.read_text().split("\n") if n.strip() and n != "GLOBAL"]
    cfg = CONFIG.read_text()

    problems = 0
    for group in ("proxy", "proxy_ai"):
        filters = parse_group(cfg, group)
        print(f"===== {group} ({len(filters)} 条过滤器) =====")
        for sub in ("main_sub", "backup_sub"):
            label = "主订阅" if sub == "main_sub" else "副订阅"
            tiers: dict[int, list[str]] = {}
            excluded, overlap = [], []
            for n in nodes:
                hits = [f for f in filters if matches(f, n, sub)]
                if len(hits) > 1:
                    overlap.append((n, [h["off"] for h in hits]))
                if hits:
                    tiers.setdefault(min(h["off"] for h in hits), []).append(n)
                else:
                    excluded.append(n)
            print(f"  【{label}】")
            for off in sorted(tiers):
                print(f"    +{off:>4}s  {', '.join(tiers[off])}")
            print(f"    不入组: {', '.join(excluded) if excluded else '(无)'}")
            if overlap:
                problems += 1
                print(f"    ⚠ 有节点命中多层,优先级不确定: {overlap}")
            else:
                print("    ✓ 分层互斥")
        print()

    # 额外检查:AI 组不允许出现港澳台
    ai = parse_group(cfg, "proxy_ai")
    hmt = re.compile(r"(香港|澳门|澳門|台湾|台灣|Hong ?Kong|Macau|Taiwan)")
    leaked = [n for n in nodes if hmt.search(n) and any(matches(f, n, "main_sub") for f in ai)]
    if leaked:
        problems += 1
        print(f"⚠ AI 组混入港澳台节点: {leaked}")
    else:
        print("✓ AI 组已排除全部港澳台节点")

    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main())
