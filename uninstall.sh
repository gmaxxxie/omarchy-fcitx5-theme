#!/usr/bin/env bash
# uninstall.sh — 卸载 omarchy-fcitx5-theme 扩展
# 移除: shell 插件、theme-set hook、生成的 fcitx5 主题、classicui 配置
# 用法: ./uninstall.sh
set -euo pipefail

PLUGIN_ID="gmaxxxie.fcitx5-theme"
HOOK="$HOME/.config/omarchy/hooks/theme-set.d/fcitx5-classicui-theme.sh"
CONF="$HOME/.config/fcitx5/conf/classicui.conf"
THEMES_DIR="$HOME/.local/share/fcitx5/themes"

echo "== 移除 shell 插件 =="
if omarchy plugin list --json 2>/dev/null | jq -e --arg id "$PLUGIN_ID" 'any(.id == $id)' >/dev/null 2>&1; then
  omarchy plugin remove "$PLUGIN_ID" --yes
else
  echo "  (未安装，跳过)"
fi

echo "== 移除 theme-set hook =="
if [[ -f "$HOOK" ]]; then
  rm -f "$HOOK"
  echo "  已移除: $HOOK"
else
  echo "  (不存在，跳过)"
fi

echo "== 移除生成的 fcitx5 主题 =="
found=0
for d in "$THEMES_DIR"/omarchy-*; do
  if [[ -d "$d" ]]; then
    rm -rf "$d"
    echo "  已移除: $d"
    found=1
  fi
done
[[ $found == 1 ]] || echo "  (未找到，跳过)"

echo "== 恢复 classicui.conf =="
if [[ -f "$CONF" ]] && grep -qE '^Theme=omarchy-' "$CONF"; then
  sed -i '/^Theme=omarchy-/d' "$CONF"
  echo "  已删除指向生成主题的 Theme= 行"
else
  echo "  (无生成主题引用，跳过)"
fi

echo "== 重启 fcitx5 恢复默认主题 =="
if systemctl --user restart omarchy-fcitx5.service 2>/dev/null; then
  echo "  已重启 omarchy-fcitx5.service"
else
  fcitx5-remote -r 2>/dev/null || true
  echo "  已通过 fcitx5-remote 重载"
fi

echo
echo "✅ 卸载完成。候选框已恢复默认主题。"
