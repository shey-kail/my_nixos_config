#!/usr/bin/env bash

# singbox subscription update script
# Fetches and processes main and backup subscriptions using subpipe

set -e

# 物理存放路径
persistSubDir="/var/lib/singbox/subscriptions"

# 默认参数
main_secret_path=""
backup_secret_path=""
main_template=""
backup_template=""
dashboard_path=""

# Parse command line arguments
while [[ $# -gt 0 ]]; do
  case $1 in
  --main-secret-path)
    main_secret_path="$2"
    shift 2
    ;;
  --backup-secret-path)
    backup_secret_path="$2"
    shift 2
    ;;
  --main-template)
    main_template="$2"
    shift 2
    ;;
  --backup-template)
    backup_template="$2"
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
if [ -z "$main_secret_path" ] || [ -z "$backup_secret_path" ] || [ -z "$dashboard_path" ]; then
  echo "Error: Missing required parameters"
  echo "Usage: $0 --main-secret-path <path> --backup-secret-path <path> --main-template <path> --backup-template <path> --dashboard-path <path>"
  exit 1
fi

mkdir -p ${persistSubDir}

echo "[singbox-update] Starting subscription update..."

# ========== 主订阅 ==========
echo "[singbox-update] Processing main subscription..."
main_url=$(cat "${main_secret_path}")
main_tmp="${persistSubDir}/config_main.json.new"

curl -sL "$main_url" | subpipe convert -f singbox --template "${main_template}" -o "${main_tmp}"

if [ -s "${main_tmp}" ]; then
  # 用 jq 设置 Dashboard 为 metacubexd
  jq --arg dashboard "${dashboard_path}" '.experimental.clash_api.external_ui = $dashboard' "${main_tmp}" > "${main_tmp}.tmp"
  mv "${main_tmp}.tmp" "${main_tmp}"

  echo "[singbox-update] Main subscription update successful."
else
  echo "[singbox-update] Warning: Main subscription fetch failed."
  rm -f "${main_tmp}"
fi

# ========== 备份订阅 ==========
echo "[singbox-update] Processing backup subscription..."
backup_url=$(cat "${backup_secret_path}")
backup_tmp="${persistSubDir}/config_backup.json.new"

curl -sL "$backup_url" | subpipe convert -f singbox --template "${backup_template}" -o "${backup_tmp}"

if [ -s "${backup_tmp}" ]; then
  # 用 jq 设置 Dashboard 为 metacubexd
  jq --arg dashboard "${dashboard_path}" '.experimental.clash_api.external_ui = $dashboard' "${backup_tmp}" > "${backup_tmp}.tmp"
  mv "${backup_tmp}.tmp" "${backup_tmp}"

  echo "[singbox-update] Backup subscription update successful."
else
  echo "[singbox-update] Warning: Backup subscription fetch failed."
  rm -f "${backup_tmp}"
fi

# ========== 应用配置并验证节点 ==========
# 主订阅
if [ -s "${main_tmp}" ]; then
  HAS_VALID_NODES=$(jq '.outbounds | any(.type == "vmess" or .type == "shadowsocks" or .type == "trojan" or .type == "hysteria" or .type == "hysteria2") ' "${main_tmp}")

  if [ "$HAS_VALID_NODES" = "true" ]; then
    echo "[singbox-update] Main: found valid nodes. Updating config."
    mv "${main_tmp}" "${persistSubDir}/config_main.json"
    chown singbox:singbox "${persistSubDir}/config_main.json"
  else
    echo "[singbox-update] Main: no valid node found. Keeping existing config."
    rm -f "${main_tmp}"
  fi
fi

# 备份订阅
if [ -s "${backup_tmp}" ]; then
  HAS_VALID_NODES=$(jq '.outbounds | any(.type == "vmess" or .type == "shadowsocks" or .type == "trojan" or .type == "hysteria" or .type == "hysteria2") ' "${backup_tmp}")

  if [ "$HAS_VALID_NODES" = "true" ]; then
    echo "[singbox-update] Backup: found valid nodes. Updating config."
    mv "${backup_tmp}" "${persistSubDir}/config_backup.json"
    chown singbox:singbox "${persistSubDir}/config_backup.json"
  else
    echo "[singbox-update] Backup: no valid node found. Keeping existing config."
    rm -f "${backup_tmp}"
  fi
fi

# ========== Reload 服务 ==========
echo "[singbox-update] Reloading services..."
systemctl reload-or-try-restart singbox.service || true
systemctl reload-or-try-restart singbox-backup.service || true

echo "[singbox-update] Done."
