import Cocoa

private let agentBundleIdentifier = "com.nick.lauchingpad.agent"
private let agentPath = "/Applications/lauchingpad-agent.app"
private let agentExecutablePath = agentPath + "/Contents/MacOS/lauchingpad-agent"
private let notificationName = Notification.Name("com.nick.lauchingpad.toggle")

final class LauncherDelegate: NSObject, NSApplicationDelegate {
    func applicationDidFinishLaunching(_ notification: Notification) {
        toggleAgent()
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        toggleAgent()
        return true
    }

    private func toggleAgent() {
        let didLaunchAgent = launchAgentIfNeeded()
        guard !didLaunchAgent else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                NSApp.terminate(nil)
            }
            return
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            DistributedNotificationCenter.default().post(name: notificationName, object: nil)
            NSApp.terminate(nil)
        }
    }

    private func launchAgentIfNeeded() -> Bool {
        guard !isAgentRunning() else { return false }

        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = false
        configuration.arguments = ["--toggle-on-start"]
        NSWorkspace.shared.openApplication(at: URL(fileURLWithPath: agentPath), configuration: configuration)
        return true
    }

    private func isAgentRunning() -> Bool {
        NSWorkspace.shared.runningApplications.contains { app in
            app.bundleIdentifier == agentBundleIdentifier ||
            app.bundleURL?.path == agentPath ||
            app.executableURL?.path == agentExecutablePath
        }
    }
}

let app = NSApplication.shared
let delegate = LauncherDelegate()
app.delegate = delegate
app.setActivationPolicy(.regular)
app.run()
