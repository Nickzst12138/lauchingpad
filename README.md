# lauchingpad

<p align="right">
  <a href="README.en.md"><img src="https://img.shields.io/badge/English-2ea44f?style=for-the-badge" alt="English"></a>
</p>

一个给 macOS 27 beta 准备的轻量 Launchpad 风格应用启动器。

`lauchingpad` 用一个熟悉的应用网格，把旧 Launchpad 的使用感带回来：Dock 点击打开，再点一次收回；直接输入搜索；方向键选择；回车打开应用。它不修改系统自带 Launchpad，也不依赖新的 Apps launcher。

![Star History Chart](https://api.star-history.com/svg?repos=Nickzst12138/lauchingpad&type=Date)

## 为什么做这个

macOS 27 beta 改变了旧 Launchpad 的体验，也有用户遇到系统 Apps launcher / Launchpad 入口点不开、不稳定的问题。

`lauchingpad` 是一个独立的小型应用启动器：

- 扫描 `/Applications`、用户 Applications 和系统 Applications 目录。
- 以网格展示应用图标和名称。
- 从 Dock 打开，再点 Dock 图标收回。
- 支持输入即搜索。
- 支持方向键选择和回车打开。
- 支持 Esc 隐藏。
- 打开某个应用后自动隐藏。
- 真实窗口服务不进入 Cmd-Tab。
- 登录后安静预热，不主动弹窗。

## 下载和安装

安装镜像已经放在仓库里：

```text
lauchingpad-installer.dmg
```

打开 DMG，然后运行：

```text
Install lauchingpad.pkg
```

安装器会写入：

```text
/Applications/lauchingpad.app
/Applications/lauchingpad-agent.app
/Library/LaunchAgents/com.nick.lauchingpad.launchagent.plist
```

同时会把 `lauchingpad.app` 固定到 Dock。

macOS 可能会要求管理员密码，也可能提示后台项目 / 登录项权限。这是正常现象，因为安装器需要写入 `/Applications`、安装 LaunchAgent，并更新 Dock 固定项。

## 工作原理

2.2 版本采用双 app 结构：

```text
lauchingpad.app          Dock 入口和点击 toggle
lauchingpad-agent.app    后台窗口服务
```

`lauchingpad.app` 是 Dock 上可见的入口。它接收点击，把打开 / 隐藏请求交给后台服务，然后自己退出。

`lauchingpad-agent.app` 负责真正的启动器窗口。它设置为 `LSUIElement`，所以不会显示额外 Dock 图标，也不会像普通应用一样出现在 Cmd-Tab 里。登录启动时会带上 `--start-hidden`，后台预热但不弹窗。

agent 还会检查重复实例，避免登录自启动和 Dock 点击各启动一个后台服务。

## 使用方式

| 操作 | 效果 |
| --- | --- |
| 点击 Dock 图标 | 打开启动器 |
| 再点一次 Dock 图标 | 隐藏启动器 |
| 直接输入 | 立即搜索应用 |
| 方向键 | 移动选择 |
| Enter | 打开当前选中应用 |
| Esc | 隐藏启动器 |

## 源码结构

```text
source/ZZLaunchpad/
├── Sources/
│   ├── main.swift          # 后台启动器窗口服务
│   ├── launcher.swift      # Dock 入口 / toggle 命令 app
│   └── make_icon.swift     # 图标生成辅助脚本
├── Info.plist              # Dock app plist
├── Agent-Info.plist        # 后台 agent plist
└── build/icon.iconset/     # app 图标资源
```

## 构建说明

当前安装包面向 Apple Silicon 构建，最低运行版本设置为 macOS 26.0，因此可以在当前 macOS 27 beta 上运行，同时避免被 LaunchServices 识别成过新的二进制。

发布包包含：

```text
lauchingpad-installer.dmg
source/ZZLaunchpad/
README.md
README.md
README.en.md
LICENSE
```

## 更新记录

### 2.2

- 拆分为 `lauchingpad.app` 和 `lauchingpad-agent.app`。
- 保持 Dock 图标稳定，同时让真实窗口服务不进入 Cmd-Tab。
- 通过 `lauchingpad-agent.app --start-hidden` 实现登录启动。
- 增加后台 agent 去重，避免 Dock 点击生成额外服务。
- 安装器同时安装两个 app。
- 最低系统目标设为 `26.0`，兼容当前 macOS 27 beta。

### 2.1

- 恢复窗口隐藏后的 Dock 常驻行为。
- 避免把可见 Dock 入口切成后台型 app。

### 2.0

- 测试过单 app 隐藏后切换后台型的方案。
- 因为会导致 Dock 入口消失，最终替换为双 app 结构。

### 1.9

- 增加 DMG 安装器打包。
- 增加登录自启动 LaunchAgent。
- 增加自动固定 Dock。

### 1.8

- 增加 Dock 点击 toggle。
- 增加 Esc 隐藏。
- 打开应用后自动隐藏。
- 优化搜索框行为。
- 修复键盘选择时旧高亮残留。
- 使用系统 Apps / Launchpad 图标风格。

## 卸载

删除这些文件：

```text
/Applications/lauchingpad.app
/Applications/lauchingpad-agent.app
/Library/LaunchAgents/com.nick.lauchingpad.launchagent.plist
```

然后从 Dock 移除 `lauchingpad`：

```text
右键 Dock 图标 -> 选项 -> 从 Dock 中移除
```

## 许可证

MIT License。见 [LICENSE](LICENSE)。
