# netflow 服务的默认配置。模块在 pkgs/netflow/module.nix 里 import 进来当 options 默认值。
# 用 { pkgs }: { ... } 形式(不是裸 attrset),这样 mihomoPath / mihomoData 能引用 pkgs.mihomo。
{ pkgs }:
{
  apiPort = 9091;
  apiSecret = "netflow_secret";
  backendPort = 9190;
  redirPort = 7892;
  dnsPort = 7874;
  mixedPort = 9050;
  proxyMode = "global";
  runMode = "redir";
  tunEnabled = false;
  lanProxy = false;
  ipv6Proxy = false;
  mihomoPath = "${pkgs.mihomo}/bin/mihomo";
  mihomoData = "${pkgs.mihomo}/share/mihomo";
  configDir = "/etc/netflow/config";
  ossUrl = "https://ocdn01.llguangli25o.com:59991/saos/qyt_news.json,https://cdno01.llguanglisf.com/saos/qyt_news.json,https://tcdn.getxlx.com/saos/qyt_news.json,https://apisa.cnossfile.com/saos/qyt_news.json";
}
