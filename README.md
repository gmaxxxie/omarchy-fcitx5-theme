# omarchy-fcitx5-theme

让 fcitx5 输入法候选框（候选词面板）**自动跟随 Omarchy 系统主题**。

`omarchy theme set <主题>` 后候选框即时换肤，无需手动操作。

![preview](preview.png)

## 原理

本扩展是一个 **Omarchy shell 插件（`service` 类型）**，注册在插件市场中：

1. `omarchy theme set` 会把当前主题的配色写入
   `~/.local/state/omarchy/current/theme/colors.toml`
2. 插件的服务组件用 `FileView`（Quickshell 文件监视）监听该文件变化
3. 变化时调用内置生成器，从主题 `colors.toml` 生成匹配的 fcitx5 候选框主题
   （`~/.local/share/fcitx5/themes/omarchy-<主题>/theme.conf`）
4. 写入 `~/.config/fcitx5/conf/classicui.conf` 的 `Theme=` 并重启 fcitx5 应用

生成器是**幂等**的：主题没变时不重启 fcitx5，可被反复调用。

## 安装

### 方式一：插件安装（主机制，推荐）

```bash
omarchy plugin add https://github.com/gmaxxxie/omarchy-fcitx5-theme.git --enable
```

插件自带完整功能：监视 + 生成 + 应用。

### 方式二：完整安装（插件 + 兜底 hook）

```bash
git clone https://github.com/gmaxxxie/omarchy-fcitx5-theme && cd omarchy-fcitx5-theme
./install.sh
```

额外安装一个 `theme-set` hook 作为兜底：当 `omarchy theme set` 在 shell 未运行
的环境（如 SSH、脚本）里执行时，hook 仍然会同步候选框主题。

## 卸载

```bash
omarchy plugin remove gmaxxxie.fcitx5-theme
```

或使用仓库内的 `./uninstall.sh`（同时清理 hook、生成的主题和配置，恢复默认）。

## 效果

| 元素 | 映射（colors.toml） |
|------|---------------------|
| 面板底色 | `background`（深色主题）/ `lighter_background`（浅色主题） |
| 候选文字 | `foreground`（深色主题）/ `dark_foreground`（浅色主题） |
| 选中候选高亮底 | `accent` |
| 选中候选文字 | `darker_background`（深色主题）/ `dark_foreground`（浅色主题） |
| 面板边框 | `selection`（缺失时回退 `muted`） |
| 菜单分隔线 | `bright_foreground`（缺失时回退边框色） |

深浅主题均支持：`mode = "light"` 的主题自动使用浅色面板 + 深色文字。

## 手动操作

```bash
# 手动为当前主题重新生成
~/.config/omarchy/plugins/gmaxxxie.fcitx5-theme/fcitx5-classicui-theme.sh current

# 生成指定主题
~/.config/omarchy/plugins/gmaxxxie.fcitx5-theme/fcitx5-classicui-theme.sh tokyo-night
```

手动编辑生成的主题文件可微调（字号、内边距等），然后重启 fcitx5：

```bash
systemctl --user restart omarchy-fcitx5.service
```

> 注意：重新运行生成器会覆盖手动修改。

## 常见问题

**Q: 候选框没变化？**
重启 fcitx5：`systemctl --user restart omarchy-fcitx5.service`。
classicui 只在启动时读主题，`fcitx5-remote -r` 重载配置不会换主题。

**Q: 插件已启用但切主题没反应？**
检查服务组件是否加载：`omarchy plugin list` 应显示
`gmaxxxie.fcitx5-theme enabled third-party service`。
若不在列表中，运行 `omarchy-shell shell rescanPlugins` 后重新启用。

**Q: 想跟随的 rime 配置改在 `custom/` 目录不生效？**
`~/.local/share/fcitx5/rime/custom/` 只是模板仓库（librime 不扫描子目录），
生效的 `<方案>.custom.yaml` 必须放在 rime 根目录（与 `wanxiang.schema.yaml` 同级）。

## 文件结构

```
omarchy-fcitx5-theme/
├── manifest.json                # 插件清单 (service)
├── Service.qml                  # 服务组件: 文件监视 + 调用生成器
├── fcitx5-classicui-theme.sh    # 核心生成器（幂等，可独立运行）
├── install.sh                   # 完整安装（插件 + 兜底 hook）
├── uninstall.sh                 # 完整卸载
├── preview.png                  # 效果预览
├── LICENSE                      # MIT
└── README.md
```
