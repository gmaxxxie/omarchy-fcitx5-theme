# 仓库约定（omarchy-fcitx5-theme）

omarchy 的 fcitx5 主题跟随插件：把 omarchy 当前主题映射成 fcitx5 classicui 主题，主题一变就跟着变。

## 结构

- `Service.qml`：shell 插件主体。监听主题状态文件，主题变化时调用生成器（主机制）
- `fcitx5-classicui-theme.sh`：生成器。幂等——主题没变就不重启 fcitx5
- `manifest.json`：插件元数据
- `install.sh` / `uninstall.sh`：安装 shell 插件 +（可选）`theme-set` hook 兜底
- `README.md` / `README.zh-CN.md`：中英双份，**改动必须同步两边**

## 开发与检查

本仓无构建系统与测试框架，QML 由 Quickshell 直接加载。等价检查：

```sh
bash -n install.sh uninstall.sh fcitx5-classicui-theme.sh   # 脚本语法
python3 -m json.tool manifest.json > /dev/null              # 元数据合法
./fcitx5-classicui-theme.sh                                 # 按当前主题重新生成
grep '^Theme=' ~/.config/fcitx5/conf/classicui.conf         # 确认写入结果
omarchy restart xcompose                                    # 让 fcitx5 真正换肤
```

改主题映射后，用 `grim` 截图输入法候选框（`grim -g "x,y wxh" /tmp/x.png`，再用 read 工具看图）确认配色。

## 验证改动

1. 跑上面的语法/生成检查。
2. `omarchy restart xcompose` 后确认候选框样式生效。
3. 切一个 omarchy 主题，确认自动跟随（这是插件的主机制，必须实测）。

**注意**：不要用 `systemctl --user restart omarchy-fcitx5.service` 换肤——fcitx5 由 omarchy 持有，旧进程仍占着 `org.fcitx.Fcitx5`，旧主题会继续生效（见 README FAQ）。

## 风格与提交

- 脚本 bash，`set -euo pipefail`；生成器保持幂等。
- 生成出来的主题文件可手工微调（字号、内边距），但下次生成会覆盖——需要长期保留的调整要写回生成器。
- 提交用 `type(scope): lowercase imperative`，如 `fix(theme): ...`；文档改动用 `docs: ...`。
