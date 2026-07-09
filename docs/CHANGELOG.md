# Changelog

## 2.2

- 改为双进程结构：`lauchingpad.app` 作为 Dock 启动器，`lauchingpad-agent.app` 作为后台窗口服务。
- Dock 图标固定在 `/Applications/lauchingpad.app`，窗口隐藏后 Dock 图标不会丢失。
- 后台窗口服务设置为 `LSUIElement`，不显示在 Dock，也不进入 Cmd-Tab 切换列表。
- Dock 点击逻辑继续保持 toggle：第一次打开，第二次收回。
- 登录自启动改为启动 `lauchingpad-agent.app --start-hidden`，后台预热但不弹窗。
- 安装包同时安装启动器和后台服务两个 app。
- 启动器按 bundle id、bundle 路径、可执行路径识别已运行 agent，避免重复启动。
- agent 启动时会检测并退出重复实例，Dock 点击只切换现有后台服务。
- 最终构建使用 `arm64-apple-macosx26.0`，兼容当前 macOS 27 beta，避免 `minos 27.0 / sdk 26.1` 在测试环境中触发 LaunchServices 扫描异常。


## 2.1

- 恢复 Dock 常驻行为：窗口收回后 Dock 图标仍然保留，方便继续点击打开。
- 不再切换到后台型状态，避免 Dock 图标消失。

## 2.0

- 曾尝试在窗口隐藏/收回后切换到后台型状态，以减少 Cmd-Tab 出现；该方案会导致 Dock 图标消失，已在 2.1 回滚。

## 1.9

- 打包 DMG 安装器。
- DMG 文件和挂载卷使用系统 Apps / Launchpad 图标。
- 安装后复制 app 到 `/Applications`。
- 安装后添加 LaunchAgent，实现登录自启动。
- 安装后自动固定 app 到 Dock。
- 自启动时使用 `--start-hidden` 后台预热，不直接弹窗。

## 1.8

- Dock 点击逻辑改为 toggle：
  - 第一次点击打开。
  - 第二次点击收回。
- Esc 改为隐藏窗口。
- 打开应用后自动收回窗口。
- 搜索框改为普通透明输入框，移除内置搜索图标，避免文字重叠。
- 删除默认搜索提示文字。
- 修复键盘移动选择时旧高亮残留。
- 使用系统 Apps / Launchpad 图标。
- 重新构建为 `arm64-apple-macosx27.0`，避免误编译成 `minos 28.0` 导致无法运行。
