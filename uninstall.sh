#!/usr/bin/env bash
# uninstall.sh — 卸载 omarchy-fcitx5-theme 扩展
# 移除: shell 插件、theme-set hook、本扩展生成的 fcitx5 主题、classicui 配置
#   并还原为安装前使用的主题 (或 fcitx5 默认主题)
# 用法: ./uninstall.sh
set -euo pipefail

PLUGIN_ID="gmaxxxie.fcitx5-theme"
HOOK="$HOME/.config/omarchy/hooks/theme-set.d/fcitx5-classicui-theme.sh"
CONF="$HOME/.config/fcitx5/conf/classicui.conf"
THEMES_DIR="$HOME/.local/share/fcitx5/themes"
STATE_DIR="$HOME/.local/state/omarchy-fcitx5-theme"
STATE_FILE="$STATE_DIR/state"

# 只删除由本扩展生成的主题目录: theme.conf 内带
# "Generated from Omarchy theme:" 标记。其它以 omarchy-* 命名的目录
# 视为用户自己的主题, 一律保留, 绝不触碰。
GENERATOR_MARKER='^Description=Generated from Omarchy theme:'
GENERATED_FILES=(theme.conf .theme.conf.tmp arrow.png next.png prev.png radio.png)

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

echo "== 移除本扩展生成的 fcitx5 主题 =="
found=0
for d in "$THEMES_DIR"/omarchy-*; do
  [[ -e "$d" && -d "$d" ]] || continue
  if [[ -f "$d/theme.conf" ]] && grep -q "$GENERATOR_MARKER" "$d/theme.conf"; then
    # 只删除我们写入的文件; 若目录里还有用户自己的文件, 保留目录本体
    for f in "${GENERATED_FILES[@]}"; do
      rm -f "$d/$f"
    done
    if rmdir "$d" 2>/dev/null; then
      echo "  已移除生成主题: $d"
    else
      echo "  已清理生成文件(目录仍保留其他文件): $d"
    fi
    found=1
  else
    echo "  跳过非本扩展生成(保留): $d"
  fi
done
[[ $found == 1 ]] || echo "  (未找到，跳过)"

echo "== 还原 classicui.conf =="
prev_theme=""
[[ -f "$STATE_FILE" ]] && prev_theme="$(sed -nE 's/^prev_theme=(.*)$/\1/p' "$STATE_FILE" | head -1 || true)"

current_theme=""
[[ -f "$CONF" ]] && current_theme="$(sed -nE 's/^Theme=([^[:space:]]+)[[:space:]]*$/\1/p' "$CONF" | head -1 || true)"

if [[ -z "$current_theme" ]]; then
  echo "  (classicui.conf 无 Theme= 行, 跳过)"
elif [[ "$current_theme" == omarchy-* ]]; then
  if [[ -n "$prev_theme" ]]; then
    sed -i "s|^Theme=.*|Theme=$prev_theme|" "$CONF"
    echo "  已还原之前使用的主题: $prev_theme"
  else
    sed -i '/^Theme=/d' "$CONF"
    echo "  无记录的上一个主题, 已移除 Theme= 行, 回退 fcitx5 默认主题"
  fi
else
  echo "  当前主题 ($current_theme) 不是本扩展设置, 保持不变"
fi

# 清理状态文件
if [[ -n "$STATE_DIR" ]]; then
  rm -rf "$STATE_DIR"
fi

echo "== 重启 fcitx5 应用主题 =="
if systemctl --user restart omarchy-fcitx5.service 2>/dev/null; then
  echo "  已重启 omarchy-fcitx5.service"
else
  fcitx5-remote -r 2>/dev/null || true
  echo "  已通过 fcitx5-remote 重载"
fi

echo
echo "✅ 卸载完成。候选框已恢复为安装前主题(或默认主题)。"
