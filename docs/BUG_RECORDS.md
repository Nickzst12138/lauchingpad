# macOS 27 beta Launchpad / Apps 问题记录

## 背景

macOS 新版本中，传统 Launchpad 被新的 Apps app / Spotlight 应用启动入口替代。外部报道和社区反馈显示，用户对这次变化存在两类问题：一是旧 Launchpad 体验被移除；二是 macOS 27 beta 中有人遇到 Apps launcher / Launchpad 点不开或不稳定。

## 外部记录

### 1. 传统 Launchpad 被 Apps 替代

Macworld 记录了 macOS Tahoe / 新版 macOS 中 Apps app 取代 Launchpad 的变化。也就是说，很多用户熟悉的全屏网格、页面、文件夹式 Launchpad 体验不再是系统默认方式。

参考：

```text
https://www.macworld.com/article/2830963/macos-tahoe-apps-replaces-launchpad.html
```

### 2. Reddit 用户反馈 macOS 27 Developer Beta 中 Launchpad / Apps launcher 点不开

Reddit 的 macOS Beta 讨论中，有用户反馈安装 macOS 27 Developer Beta 后，点击 app launchpad / launcher 时无法打开应用列表。评论里也有用户表示 fresh install 后仍然遇到类似问题。

参考：

```text
https://www.reddit.com/r/MacOSBeta/comments/1u0n959/does_anybody_have_a_issue_with_the_app_launchpad/
```

### 3. 社区中也有 Apps.app 在 macOS 27 上无法运行的反馈

MacRumors 的 macOS 27 working / non-working apps thread 中，有用户提到 Apps.app 在 macOS 27 上无法运行，Dock 图标点击和 Applications 文件夹里直接打开都不工作。

参考：

```text
https://spy.macrumors.com/threads/macos-27-working-and-non-working-apps-thread.2483527/page-4
```

### 4. 用户开始寻找第三方替代方案

社区里已经出现多个 Launchpad 替代工具或讨论，核心诉求是找回旧式应用网格和更直接的 Dock 启动入口。

参考：

```text
https://appgridmac.com/launchpad-removed-macos-tahoe/
https://www.macobserver.com/news/launchpad-is-gone-in-macos-26-and-users-hate-the-replacement/
```

## 本机复现信息

当前测试环境：

```text
ProductVersion: macOS 27.0
BuildVersion: 26A5368g
```

这个构建上，系统 Launchpad / Apps 体验存在可用性问题，因此制作了 `lauchingpad` 作为替代入口。

## 我们的解决方案

`lauchingpad` 不是修改系统 Launchpad，也不依赖系统 Apps launcher，而是独立实现一个应用启动器：

- 自己扫描系统和用户 Applications 目录。
- 自己展示应用网格。
- 自己处理 Dock 点击打开/收回。
- 自己处理键盘搜索、选择和启动。
- 打开应用后自动隐藏。
- Esc 直接隐藏。
- 支持登录后自启动。
- 安装后自动固定到 Dock。

这样即使系统自带 Apps launcher 点不开，用户也可以通过 Dock 上的 `lauchingpad` 正常搜索和打开应用。

## 权限说明

安装包会写入：

```text
/Applications/lauchingpad.app
/Library/LaunchAgents/com.nick.lauchingpad.launchagent.plist
```

并会修改当前用户 Dock 配置，把 `/Applications/lauchingpad.app` 固定到 Dock。

macOS 可能出现以下提示：

- 要求输入管理员密码。
- 提示新增后台项目。
- Dock 短暂重启。

这些都是安装、开机自启动和 Dock 固定所需的正常系统行为。

## 2.2 切换问题修复记录

早期尝试把单个 app 在隐藏后切换为后台型状态，确实可以减少 Cmd-Tab 里出现的问题，但副作用是 Dock 中的图标也会消失，用户无法继续通过 Dock 第二次点击打开。

最终采用双进程策略：

- Dock 中只固定 `/Applications/lauchingpad.app`。
- `lauchingpad.app` 是很薄的前台启动器，只负责发送打开/收回指令。
- `/Applications/lauchingpad-agent.app` 才是真正显示窗口的后台服务。
- agent 使用 `LSUIElement`，因此不显示 Dock 图标，也不会作为普通应用进入 Cmd-Tab 切换列表。
- 登录自启动只启动 agent，并带 `--start-hidden`，所以开机后不会主动弹窗。

这个结构解决了两个互相冲突的需求：既保留 Dock 可点击入口，又让实际 Launchpad 窗口不参与普通应用切换。


## 2.2 最终验证

最终版验证结果：

- `/Applications/lauchingpad.app` 和 `/Applications/lauchingpad-agent.app` 均为 2.2。
- 两个二进制均为 arm64，最低系统版本为 26.0，可在当前 macOS 27 beta 上运行。
- 安装后只有一个 `lauchingpad-agent --start-hidden` 后台服务常驻。
- Dock 点击启动器不会再额外生成第二个 agent。
- `lauchingpad-agent` 设置为 `LSUIElement`，不会显示在 Dock，也不会进入普通 Cmd-Tab 应用切换列表。
- Dock 上固定的是 `/Applications/lauchingpad.app`，所以窗口收回后 Dock 入口仍然保留。
