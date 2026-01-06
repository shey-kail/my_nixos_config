#!/usr/bin/env bash

# singbox subscription update script
# This script fetches, processes and updates the singbox configuration

set -e

# 物理存放路径
persistSubDir="/var/lib/singbox/subscriptions"

# singbox config file
configFile="${persistSubDir}/config.json"
configTmpFile="${persistSubDir}/config.json.new"

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  --secret-path)
    secret_path="$2"
    shift 2
    ;;
  --dashboard-path)
    dashboard_path="$2"
    shift 2
    ;;
  *)
    echo "Unknown option: $1"
    exit 1
    ;;
  esac
done

# Check if required parameters are provided
if [ -z "$secret_path" ] || [ -z "$dashboard_path" ]; then
  echo "Error: Missing required parameters"
  echo "Usage: $0 --secret-path <secret_path> --dashboard-path <dashboard_path>"
  exit 1
fi

mkdir -p ${persistSubDir}

# 获取订阅配置并应用一系列转换（合并为单个jq命令以避免多行管道语法问题）
# 1. 移除 type 为 "tun" 的 inbounds
# 2. 将 type 为 "mixed" 的 inbounds 绑定到 127.0.0.1:9050
# 3. 设置日志配置：启用日志、级别为 error、带时间戳
# 4. 设置默认域名解析器为 dns_direct，并移除所有包含 clash_mode 字段的规则
# 5. 设置AI服务默认为新加坡节点
# 6. 设置测试延迟的地址为http://www.google.com/generate_204
# 7. 启用 Clash API，配置外部控制地址、Web UI 路径和空 secret
curl -s "$(cat "${secret_path}")" |
  jq --arg dashboard "${dashboard_path}" '.inbounds |= map(select(.type != "tun")) | .inbounds |= map(if .type == "mixed" then (.listen = "127.0.0.1" | .listen_port = 9050) else . end) | .log = {"disabled": false, "level": "error", "timestamp": true} | .route |= (.default_domain_resolver = "dns_direct" | .rules |= map(select(.clash_mode | not?))) | .outbounds |= map(if (.type == "selector" and .tag == "💬 AI 服务") then .default = "🇸🇬 Singapore" else . end) | .experimental.clash_api.default_latency_url //= "http://www.google.com/generate_204" | .experimental += { "clash_api": { "external_controller": "127.0.0.1:9090", "external_ui": $dashboard, "secret": "" } }' >"${configTmpFile}"

# Check if the generation was successful AND the new file is not empty
if [ -s ${configTmpFile} ]; then
  echo "Config file Update successful."
else
  echo "Warning: Update fetch failed or produced an empty file. Keeping existing config."
  rm -f ${configTmpFile} # Clean up the failed artifact
  exit 0                 # Exit successfully without applying changes or reloading
fi

# check valid nodes
HAS_VALID_NODES=$(jq '.outbounds | any(.type == "vmess" or .type == "shadowsocks" or .type == "trojan" or .type == "hysteria" or .type == "hysteria2") ' ${configTmpFile})

if [ "$HAS_VALID_NODES" = "true" ]; then
  echo "Found valid nodes. Reloading service."
  mv ${configTmpFile} ${configFile}
else
  echo "No valid node found. Keeping existing config."
  rm -f ${configTmpFile} # Clean up the failed artifact
  exit 0                 # Exit successfully without applying changes or reloading
fi

# Finalize permissions and reload. This only runs on successful update.
echo "Finalizing permissions and reloading service."
chown singbox:singbox ${configFile}
systemctl reload-or-try-restart singbox.service
