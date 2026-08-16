#!/usr/bin/env bash
# install.sh — 安装 omarchy-fcitx5-theme 扩展
# 安装两部分:
#   1. shell 插件 (service) — 监视主题状态文件, 实时跟随 (主机制)
#   2. theme-set hook — 无 shell 环境下(SSH/脚本)切主题的兜底 (可选)
# 用法: ./install.sh
set -euo pipefail

REPO_URL="https://github.com/gmaxxxie/omarchy-fcitx5-theme.git"
PLUGIN_ID="gmaxxxie.fcitx5-theme"
PLUGIN_DIR="$HOME/.config/omarchy/plugins/$PLUGIN_ID"

echo "== 检查依赖 =="
command -v omarchy >/dev/null || { echo "错误: 未找到 omarchy 命令"; exit 1; }
command -v fcitx5-remote >/dev/null || { echo "错误: 未安装 fcitx5"; exit 1; }

echo "== 安装 shell 插件 (service) =="
if [[ -d "$PLUGIN_DIR" ]]; then
  echo "  插件已存在: $PLUGIN_DIR"
else
  omarchy plugin add "$REPO_URL" --enable --yes
fi
omarchy plugin enable "$PLUGIN_ID" >/dev/null 2>&1 || true

echo "== 安装 theme-set hook (兜底) =="
omarchy hook install theme-set "$PLUGIN_DIR/fcitx5-classicui-theme.sh"

echo "== 为当前主题生成候选框主题 =="
"$PLUGIN_DIR/fcitx5-classicui-theme.sh" current

echo
echo "✅ 安装完成。"
echo "   - 切换主题 (omarchy theme set) 后候选框自动跟随 (shell 监视) "
echo "   - 手动重新生成: $PLUGIN_DIR/fcitx5-classicui-theme.sh current"
echo "   - 卸载: $PLUGIN_DIR/uninstall.sh 或 ./uninstall.sh"
