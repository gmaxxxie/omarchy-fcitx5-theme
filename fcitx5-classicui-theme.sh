#!/usr/bin/env bash
# fcitx5-classicui-theme.sh — 让 fcitx5 候选框主题跟随 Omarchy 当前主题
# 用法:
#   fcitx5-classicui-theme.sh [主题slug] [--quiet]
#   - 主题slug 省略时使用当前主题 (omarchy theme current)
#   - --quiet 时跳过桌面通知
# 幂等: 主题未变化时不会重启 fcitx5, 可安全被 hook / service / 定时器反复调用
set -euo pipefail

quiet=0
slug=""
for arg in "$@"; do
  case "$arg" in
    --quiet|-q) quiet=1 ;;
    -h|--help)
      echo "Usage: fcitx5-classicui-theme.sh [theme-slug] [--quiet]"
      exit 0 ;;
    *) slug="$arg" ;;
  esac
done

if [[ -z "$slug" || "$slug" == "current" ]]; then
  current="$(omarchy theme current 2>/dev/null || true)"
  slug="$(printf '%s' "$current" | tr '[:upper:] ' '[:lower:]-')"
fi
slug="$(printf '%s' "$slug" | tr '[:upper:] ' '[:lower:]-')"

theme_dir="$(omarchy theme dir "$slug" 2>/dev/null || true)"
if [[ -z "$theme_dir" || ! -f "$theme_dir/colors.toml" ]]; then
  echo "fcitx5-theme: theme '$slug' colors.toml not found" >&2
  exit 1
fi
colors="$theme_dir/colors.toml"

get() {
  sed -nE "s/^$1[[:space:]]*=[[:space:]]*[\"']?([^\"']*)[\"']?[[:space:]]*$/\1/p" "$colors" | head -1
}

mode="$(get mode)";   [[ -n "$mode" ]]   || mode=dark
bg="$(get background)"; [[ -n "$bg" ]]   || bg="#1e1e2e"
fg="$(get foreground)"; [[ -n "$fg" ]]   || fg="#cdd6f4"
accent="$(get accent)"; [[ -n "$accent" ]] || accent="#89b4fa"
sel="$(get selection)"; [[ -n "$sel" ]]  || sel="$(get muted)"
[[ -n "$sel" ]] || sel="#313244"
dark_bg="$(get darker_background)"; [[ -n "$dark_bg" ]] || dark_bg="$(get dark_background)"
[[ -n "$dark_bg" ]] || dark_bg="#11111b"

# 高亮（选中候选）文字颜色：深色主题用深底深字，浅色主题用深色文字
if [[ "$mode" == "light" ]]; then
  hl_text="$(get dark_foreground)"; [[ -n "$hl_text" ]] || hl_text="#1e1e2e"
  panel_bg="$(get lighter_background)"; [[ -n "$panel_bg" ]] || panel_bg="$bg"
  panel_fg="$hl_text"
else
  hl_text="$dark_bg"
  panel_bg="$bg"
  panel_fg="$fg"
fi
hl_bg="$accent"
border="$sel"
menu_sep="$(get bright_foreground)"; [[ -n "$menu_sep" ]] || menu_sep="$border"

out="$HOME/.local/share/fcitx5/themes/omarchy-$slug"
mkdir -p "$out"

tmp="$out/.theme.conf.tmp"
cat > "$tmp" <<EOF
[Metadata]
Name=Omarchy $slug
Version=1
Author=Omarchy theme hook
Description=Generated from Omarchy theme: $slug
ScaleWithDPI=True

[InputPanel]
NormalColor=$panel_fg
HighlightCandidateColor=$hl_text
HighlightColor=$panel_fg
HighlightBackgroundColor=$hl_bg
PageButtonAlignment=Last Candidate

[InputPanel/TextMargin]
Left=10
Right=10
Top=8
Bottom=8

[InputPanel/ContentMargin]
Left=4
Right=4
Top=4
Bottom=4

[InputPanel/Background]
Color=$panel_bg
BorderColor=$border
BorderWidth=1

[InputPanel/Background/Margin]
Left=4
Right=4
Top=4
Bottom=4

[InputPanel/Highlight]
Color=$hl_bg

[InputPanel/Highlight/Margin]
Left=8
Right=8
Top=6
Bottom=6

[InputPanel/PrevPage]
Image=prev.png

[InputPanel/PrevPage/ClickMargin]
Left=5
Right=5
Top=4
Bottom=4

[InputPanel/NextPage]
Image=next.png

[InputPanel/NextPage/ClickMargin]
Left=5
Right=5
Top=4
Bottom=4

[Menu]
NormalColor=$panel_fg
HighlightCandidateColor=$hl_text

[Menu/Background]
Color=$panel_bg
BorderColor=$border
BorderWidth=1

[Menu/Background/Margin]
Left=4
Right=4
Top=4
Bottom=4

[Menu/ContentMargin]
Left=4
Right=4
Top=4
Bottom=4

[Menu/CheckBox]
Image=radio.png

[Menu/SubMenu]
Image=arrow.png

[Menu/Highlight]
Color=$hl_bg

[Menu/Highlight/Margin]
Left=8
Right=8
Top=6
Bottom=6

[Menu/Separator]
Color=$border

[Menu/TextMargin]
Left=8
Right=8
Top=6
Bottom=6

[AccentColorField]
0=Input Panel Border
1=Input Panel Highlight Candidate Background
2=Input Panel Highlight
3=Menu Border
4=Menu Separator
5=Menu Selected Item Background
EOF

changed=0
if [[ -f "$out/theme.conf" ]] && cmp -s "$tmp" "$out/theme.conf"; then
  rm -f "$tmp"
else
  mv "$tmp" "$out/theme.conf"
  changed=1
fi

# 翻页按钮等图标从默认主题复制（幂等）
for img in arrow.png next.png prev.png radio.png; do
  src="/usr/share/fcitx5/themes/default/$img"
  if [[ -f "$src" && ! -f "$out/$img" ]]; then
    cp "$src" "$out/"
  fi
done

# 写入 classicui 配置
conf="$HOME/.config/fcitx5/conf/classicui.conf"
mkdir -p "$(dirname "$conf")"
if [[ -f "$conf" ]] && grep -q "^Theme=omarchy-$slug\$" "$conf"; then
  : # 已指向当前主题
elif [[ -f "$conf" ]] && grep -q "^Theme=" "$conf"; then
  sed -i "s|^Theme=.*|Theme=omarchy-$slug|" "$conf"
  changed=1
else
  printf 'Theme=omarchy-%s\n' "$slug" >> "$conf"
  changed=1
fi

# 仅在主题实际变化时重启 fcitx5（classicui 只在启动时读主题）
if [[ $changed == 1 ]]; then
  if systemctl --user restart omarchy-fcitx5.service 2>/dev/null; then
    :
  else
    fcitx5-remote -r 2>/dev/null || true
  fi
  if [[ $quiet != 1 ]]; then
    notify-send "fcitx5 主题" "候选框已跟随主题: $slug" 2>/dev/null || true
  fi
fi

exit 0
