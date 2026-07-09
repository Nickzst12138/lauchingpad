# lauchingpad

一个给 macOS 27 beta 准备的轻量 Launchpad 替代工具。

macOS 27 beta 中，部分用户反馈系统自带的 Launchpad / Apps launcher 点不开、行为不稳定，或者新版 Apps 取代旧 Launchpad 后体验不符合原来的使用习惯。`lauchingpad` 通过独立的小窗口恢复一个更接近旧 Launchpad 的入口：从 Dock 点击打开，再点一次收回，支持键盘搜索、方向键选择、回车打开应用。

## 解决的问题

- 系统 Launchpad / Apps launcher 在 macOS 27 beta 上点不开或不稳定。
- 新版 Apps 替代旧 Launchpad 后，不再是原来熟悉的应用网格体验。
- 需要一个可以固定在 Dock、开机自启动、随时点击打开/收回的应用启动器。
- 需要启动器窗口隐藏后不出现在 Cmd-Tab 应用切换列表中，但 Dock 入口仍然保留。

## 2.2 方案说明

本版采用双进程结构：

- `/Applications/lauchingpad.app`：Dock 上看到和固定的入口。它只负责把“打开/收回”指令交给后台服务，然后自己退出。
- `/Applications/lauchingpad-agent.app`：真正显示应用网格的后台窗口服务。它不显示 Dock 图标，也不出现在 Cmd-Tab 切换列表中。

这样可以同时做到：Dock 里保留一个可点击的图标；点击第一次打开，第二次收回；窗口收回后不污染 Cmd-Tab；登录后后台预热但不主动弹窗。2.2 最终版还加入了后台服务去重，避免登录项和 Dock 点击各启动一个 agent。

## 功能

- 扫描 `/Applications`、用户 Applications 和系统 Applications 目录。
- 网格展示应用图标和名称。
- 输入即搜索，不显示多余搜索提示或搜索图标。
- 方向键移动选择，旧选中高亮不会残留。
- 回车打开当前选中的应用。
- Esc 隐藏窗口。
- Dock 点击第一次打开，第二次收回。
- 打开某个应用后自动收回窗口。
- 使用系统 Apps / Launchpad 图标。
- 支持登录后自启动，后台预热，不主动弹窗。
- 后台窗口服务不出现在 Cmd-Tab 应用切换中。
- 后台 agent 去重，避免登录自启动和 Dock 点击造成重复进程。
- 二进制最低系统版本设为 26.0，可在当前 macOS 27 beta 上正常打开，同时避免误编译成 28.0。

## 安装

打开本文件夹中的：

```text
lauchingpad-installer.dmg
```

然后双击 DMG 内的：

```text
Install lauchingpad.pkg
```

安装器会：

- 安装 Dock 启动器到 `/Applications/lauchingpad.app`
- 安装后台窗口服务到 `/Applications/lauchingpad-agent.app`
- 添加登录自启动 LaunchAgent
- 把 lauchingpad 固定到 Dock

安装过程中 macOS 可能会要求管理员密码，也可能提示「后台项目」或「登录项」权限。这是因为安装器需要写入 `/Applications` 和 `/Library/LaunchAgents`，并修改 Dock 固定项。

## 使用

- 点击 Dock 图标：打开窗口。
- 再点一次 Dock 图标：收回窗口。
- 直接输入：搜索应用。
- 方向键：移动选择。
- Enter：打开应用。
- Esc：隐藏窗口。

## 卸载

删除：

```text
/Applications/lauchingpad.app
/Applications/lauchingpad-agent.app
/Library/LaunchAgents/com.nick.lauchingpad.launchagent.plist
```

然后从 Dock 上右键 lauchingpad，选择「选项」->「从 Dock 中移除」。

## 文件说明

- `lauchingpad-installer.dmg`：可分发安装镜像，内含安装包和 DMG 图标。
- `source/ZZLaunchpad/`：源码和构建资源。
- `docs/BUG_RECORDS.md`：macOS 27 beta 相关问题记录和解决说明。
- `docs/CHANGELOG.md`：本次优化记录。
