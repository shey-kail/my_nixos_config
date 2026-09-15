{
  inputs,
  lib,
  ...
}: let
  inherit (lib) strings;
  inherit (lib.attrsets) filterAttrs attrNames;
  overlayDir = ./overlay;
  files = attrNames (
    filterAttrs (path: type: type == "regular" && strings.hasSuffix ".nix" path) (
      builtins.readDir overlayDir
    )
  );

  # 本地手写 overlay:从 overlay/*.nix 自动 import
  localOverlays = map (f: import (toString overlayDir + "/${f}")) files;

  # 浩辰CAD 2027:注入 deb 分片源(cadsoft flake 输入)后重新 callPackage
  gstarOverlay = final: prev: let
    gstarSrc = inputs.cadsoft;
  in {
    gstar-cad = prev.callPackage ../pkgs/gstar-cad {src = gstarSrc;};
  };

  # 第三方 flake overlay:在这里集中登记
  flakeOverlays = [
    # office-fonts:基于 chinese-fonts-overlay 的字体集(含全部上游字体
    # + 自定义的仿宋_GB2312 / 楷体_GB2312 公文国标字体)
    inputs.office-fonts.overlays.default

    # printer-drivers:佳能 UFR II + 得力 GDI 私有打印驱动
    inputs.printer-drivers.overlays.default

    # llm-agents:numtide 维护的 AI 编码 agent 工具集
    # (DeepSeek Harness dsh / codex / opencode / claude-code 等,每日自动更新)
    inputs.llm-agents.overlays.shared-nixpkgs

    # openviking:agent 记忆/上下文数据库(提供 pkgs.openviking / ov-cli)
    inputs.openviking.overlays.default
  ];
in
  localOverlays ++ flakeOverlays ++ [gstarOverlay]
