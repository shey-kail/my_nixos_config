#!/usr/bin/env python3
"""dae 托盘图标。

功能:
  - 图标实时反映 dae.service 的运行状态(network-vpn / network-offline)
  - 菜单里可直接启动 / 停止 / 重启 dae(经 pkexec 走 polkit 认证弹窗)
  - "当前节点"调用 which-node.py,把结果弹窗展示
  - "查看日志"用 konsole 打开 journalctl -u dae -f

由 systemd 用户服务(登录图形会话后自启)拉起,见 home/linux/gui/base/dae-tray.nix。
"""

import os
import subprocess
import threading

import gi

gi.require_version("Gtk", "3.0")
gi.require_version("AyatanaAppIndicator3", "0.1")
from gi.repository import AyatanaAppIndicator3 as AppIndicator  # noqa: E402
from gi.repository import GLib, Gtk  # noqa: E402

SERVICE = "dae.service"
POLL_SECONDS = 5

SYSTEMCTL = os.environ.get("DAETRAY_SYSTEMCTL", "/run/current-system/sw/bin/systemctl")
PKEXEC = os.environ.get("DAETRAY_PKEXEC", "/run/current-system/sw/bin/pkexec")
KONSOLE = os.environ.get("DAETRAY_KONSOLE", "konsole")
PYTHON = os.environ.get("DAETRAY_PYTHON", "python3")
WHICH_NODE = os.environ.get("DAETRAY_WHICH_NODE", "")
ICON_ON = "network-vpn"
ICON_OFF = "network-offline"


def is_active() -> bool:
    try:
        return (
            subprocess.run(
                [SYSTEMCTL, "is-active", "--quiet", SERVICE],
                timeout=5,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            ).returncode
            == 0
        )
    except Exception:
        return False


def control(action: str) -> None:
    """start / stop / restart,经 pkexec 触发 polkit 密码弹窗。"""
    try:
        subprocess.Popen(
            [PKEXEC, SYSTEMCTL, action, SERVICE],
            start_new_session=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    except Exception:
        pass


class Tray:
    def __init__(self) -> None:
        self.indicator = AppIndicator.Indicator.new(
            "dae-tray", ICON_OFF, AppIndicator.IndicatorCategory.SYSTEM_SERVICES
        )
        self.indicator.set_status(AppIndicator.IndicatorStatus.ACTIVE)

        self.menu = Gtk.Menu()

        self.status_item = Gtk.MenuItem(label="dae: 检测中…")
        self.status_item.set_sensitive(False)
        self.menu.append(self.status_item)

        self.menu.append(Gtk.SeparatorMenuItem())
        for label, action in (("启动 dae", "start"), ("停止 dae", "stop"), ("重启 dae", "restart")):
            item = Gtk.MenuItem(label=label)
            item.connect("activate", lambda _w, a=action: control(a))
            self.menu.append(item)

        self.menu.append(Gtk.SeparatorMenuItem())

        node_item = Gtk.MenuItem(label="当前节点…")
        node_item.connect("activate", self.on_which_node)
        self.menu.append(node_item)

        log_item = Gtk.MenuItem(label="查看日志")
        log_item.connect("activate", self.on_logs)
        self.menu.append(log_item)

        self.menu.append(Gtk.SeparatorMenuItem())
        quit_item = Gtk.MenuItem(label="退出托盘")
        quit_item.connect("activate", lambda _w: Gtk.main_quit())
        self.menu.append(quit_item)

        self.menu.show_all()
        self.indicator.set_menu(self.menu)

        self.refresh()
        GLib.timeout_add_seconds(POLL_SECONDS, self.refresh)

    # ---------- 状态 ----------
    def refresh(self) -> bool:
        active = is_active()
        self.indicator.set_icon_full(ICON_ON if active else ICON_OFF, "dae")
        self.status_item.set_label("dae: 运行中" if active else "dae: 已停止")
        self.indicator.set_title("dae 运行中" if active else "dae 已停止")
        return True  # 继续轮询

    # ---------- 当前节点 ----------
    def on_which_node(self, _widget) -> None:
        if not WHICH_NODE:
            self.show_dialog("当前节点", "未配置 which-node.py 路径")
            return
        self.show_dialog("当前节点", "正在查询…（如弹密码框请输入）")
        threading.Thread(target=self._which_node_worker, daemon=True).start()

    def _which_node_worker(self) -> None:
        try:
            proc = subprocess.run(
                [PKEXEC, PYTHON, WHICH_NODE],
                capture_output=True,
                text=True,
                timeout=90,
            )
            text = (proc.stdout or "").strip() or (proc.stderr or "").strip() or "(无输出)"
        except Exception as exc:  # noqa: BLE001
            text = f"查询失败: {exc}"
        GLib.idle_add(self.show_dialog, "当前节点", text)

    # ---------- 日志 ----------
    def on_logs(self, _widget) -> None:
        try:
            subprocess.Popen(
                [KONSOLE, "-e", "journalctl", "-u", "dae", "-f"],
                start_new_session=True,
            )
        except Exception:
            pass

    # ---------- 弹窗 ----------
    def show_dialog(self, title: str, text: str) -> bool:
        dialog = Gtk.MessageDialog(
            message_type=Gtk.MessageType.INFO,
            buttons=Gtk.ButtonsType.CLOSE,
            text=title,
        )
        dialog.format_secondary_text(text[:4000])
        dialog.connect("response", lambda d, _r: d.destroy())
        dialog.show()
        return False


def main() -> int:
    Tray()
    Gtk.main()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
