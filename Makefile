# 用于管理 NixOS flake 的 Makefile

# 定义要重建系统的主机名。
# 您可以根据需要修改此值。
HOST := wujie

# .PHONY 告诉 make 这些目标不是文件名。
.PHONY: all rebuild update update-nur update-rebuild help

# 默认目标
all: help

# 重建 NixOS 系统
# 这会将当前的 flake 配置应用到系统中。
rebuild:
	@echo "正在为 主机 $(HOST) 重建系统..."
	sudo nixos-rebuild switch --flake .#$(HOST)

# 全面升级所有 flake 输入
# 这会获取 flake.nix 中定义的所有依赖项的最新版本。
update:
	@echo "正在更新所有 flake 输入..."
	sudo nix flake update

# 仅更新 NUR (Nix User Repository) 输入
update-nur:
	@echo "正在更新 NUR flake 输入..."
	sudo nix flake update nur

# 仅更新 mysecret 输入
update-mysecrets:
	@echo "正在更新 NUR flake 输入..."
	sudo nix flake update mysecrets

# 组合操作：先升级所有输入，然后重建系统
update-rebuild: update
	@echo "更新完毕，开始重建系统..."
	$(MAKE) rebuild

# 显示帮助信息
help:
	@echo "NixOS Flake 管理"
	@echo "----------------------"
	@echo "用法: make [target]"
	@echo ""
	@echo "可用目标:"
	@echo "  rebuild              - 为主机 '''$(HOST)''' 重建 NixOS 系统"
	@echo "  update               - 全面升级所有 flake 输入 (nix flake update)"
	@echo "  update-nur           - 仅更新 '''nur''' flake 输入"
	@echo "  update-mysecrets     - 仅更新 '''nur''' flake 输入"
	@echo "  update-rebuild       - 依次执行 '''update''' 和 '''rebuild'''"
	@echo "  help                 - 显示此帮助信息"
