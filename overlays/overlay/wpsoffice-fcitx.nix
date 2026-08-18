# WPS 在 Wayland + Fcitx5 下需要显式注入输入法环境变量。
# 参考 https://www.anysets.tech/?p=541
#
# Wayland 下 Fcitx5 建议全局只保留 XMODIFIERS,但 WPS 的 Qt/GTK 组件
# 依赖这些变量,所以在 WPS 自己的 desktop 入口里注入,不影响其他应用。
final: prev: {
  wpsoffice-cn = prev.wpsoffice-cn.overrideAttrs (old: {
    postFixup =
      (old.postFixup or "")
      + ''
        for desktop in $out/share/applications/wps-office-*.desktop; do
          sed -i 's|^Exec=|Exec=env XMODIFIERS="@im=fcitx" GTK_IM_MODULE="fcitx" QT_IM_MODULE="fcitx" SDL_IM_MODULE=fcitx GLFW_IM_MODULE=ibus |' "$desktop"
        done
      '';
  });
}
