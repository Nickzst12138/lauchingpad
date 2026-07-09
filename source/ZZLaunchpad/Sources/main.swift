import Cocoa
import QuartzCore

private let distributedNotificationName = Notification.Name("com.nick.lauchingpad.toggle")
private let agentBundleIdentifier = "com.nick.lauchingpad.agent"
private let agentBundlePath = "/Applications/lauchingpad-agent.app"
private let agentExecutablePath = agentBundlePath + "/Contents/MacOS/lauchingpad-agent"

struct AppEntry: Hashable {
    let name: String
    let path: String
    let url: URL
    let bundleIdentifier: String?
}

final class AppIconProvider {
    static let shared = AppIconProvider()

    private let cache = NSCache<NSString, NSImage>()

    func icon(for entry: AppEntry) -> NSImage {
        let key = entry.path as NSString
        if let cached = cache.object(forKey: key) {
            return cached
        }

        let icon = NSWorkspace.shared.icon(forFile: entry.path)
        icon.size = NSSize(width: 80, height: 80)
        cache.setObject(icon, forKey: key)
        return icon
    }

    func warm(_ entries: [AppEntry]) {
        for entry in entries {
            _ = icon(for: entry)
        }
    }
}

final class LiquidGlassView: NSVisualEffectView {
    private let sheenLayer = CAGradientLayer()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        material = .popover
        blendingMode = .behindWindow
        state = .active
        wantsLayer = true
        layer?.cornerRadius = 28
        layer?.cornerCurve = .continuous
        layer?.masksToBounds = true
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.white.withAlphaComponent(0.56).cgColor
        layer?.backgroundColor = NSColor.clear.cgColor
        layer?.shadowColor = NSColor.black.cgColor
        layer?.shadowOpacity = 0.38
        layer?.shadowRadius = 52
        layer?.shadowOffset = NSSize(width: 0, height: -18)

        sheenLayer.colors = [
            NSColor.white.withAlphaComponent(0.62).cgColor,
            NSColor.white.withAlphaComponent(0.20).cgColor,
            NSColor.clear.cgColor
        ]
        sheenLayer.locations = [0, 0.30, 1]
        sheenLayer.startPoint = CGPoint(x: 0.10, y: 1)
        sheenLayer.endPoint = CGPoint(x: 0.92, y: 0)
        layer?.addSublayer(sheenLayer)
    }

    override func layout() {
        super.layout()
        sheenLayer.frame = bounds
    }
}

final class GlassBarView: NSVisualEffectView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        material = .popover
        blendingMode = .withinWindow
        state = .active
        wantsLayer = true
        layer?.cornerRadius = 22
        layer?.cornerCurve = .continuous
        layer?.masksToBounds = true
        layer?.borderWidth = 1
        layer?.borderColor = NSColor.white.withAlphaComponent(0.62).cgColor
        layer?.backgroundColor = NSColor.clear.cgColor
    }
}

final class AppCell: NSCollectionViewItem {
    static let identifier = NSUserInterfaceItemIdentifier("AppCell")

    private let iconView = NSImageView()
    private let nameLabel = NSTextField(labelWithString: "")

    override func loadView() {
        view = NSView()
        view.wantsLayer = true
        view.layer?.cornerRadius = 18
        view.layer?.cornerCurve = .continuous
        view.layer?.borderWidth = 1
        view.layer?.borderColor = NSColor.clear.cgColor

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.imageScaling = .scaleProportionallyUpOrDown
        iconView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        iconView.setContentCompressionResistancePriority(.defaultLow, for: .vertical)

        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.alignment = .center
        nameLabel.lineBreakMode = .byTruncatingTail
        nameLabel.maximumNumberOfLines = 2
        nameLabel.font = .systemFont(ofSize: 13, weight: .medium)
        nameLabel.textColor = .labelColor
        nameLabel.shadow = {
            let shadow = NSShadow()
            shadow.shadowBlurRadius = 4
            shadow.shadowOffset = NSSize(width: 0, height: -1)
            shadow.shadowColor = NSColor.white.withAlphaComponent(0.35)
            return shadow
        }()

        view.addSubview(iconView)
        view.addSubview(nameLabel)

        NSLayoutConstraint.activate([
            iconView.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            iconView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 70),
            iconView.heightAnchor.constraint(equalToConstant: 70),

            nameLabel.topAnchor.constraint(equalTo: iconView.bottomAnchor, constant: 7),
            nameLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 6),
            nameLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -6),
            nameLabel.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -8)
        ])
    }

    override var isSelected: Bool {
        didSet {
            updateSelectionAppearance(animated: true)
        }
    }

    func configure(with entry: AppEntry) {
        nameLabel.stringValue = entry.name
        iconView.image = AppIconProvider.shared.icon(for: entry)
        updateSelectionAppearance(animated: false)
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        iconView.image = nil
        nameLabel.stringValue = ""
        updateSelectionAppearance(animated: false)
    }

    private func updateSelectionAppearance(animated: Bool) {
        let backgroundColor = isSelected
            ? NSColor.controlAccentColor.withAlphaComponent(0.28).cgColor
            : NSColor.clear.cgColor
        let borderColor = isSelected
            ? NSColor.white.withAlphaComponent(0.68).cgColor
            : NSColor.clear.cgColor
        let alphaValue: CGFloat = isSelected ? 1 : 0.94

        if animated {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.16
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                view.animator().layer?.backgroundColor = backgroundColor
                view.animator().layer?.borderColor = borderColor
                view.animator().alphaValue = alphaValue
            }
        } else {
            view.layer?.backgroundColor = backgroundColor
            view.layer?.borderColor = borderColor
            view.alphaValue = alphaValue
        }
    }
}

final class AppDelegate: NSObject, NSApplicationDelegate, NSCollectionViewDataSource, NSCollectionViewDelegateFlowLayout, NSTextFieldDelegate {
    private var window: NSWindow!
    private let searchField = NSTextField(string: "")
    private let statusLabel = NSTextField(labelWithString: "正在扫描应用...")
    private let collectionView = NSCollectionView()
    private let scrollView = NSScrollView()
    private let searchPanel = GlassBarView()

    private var allApps: [AppEntry] = []
    private var filteredApps: [AppEntry] = []
    private var isLaunchingFromSelection = false
    private var isSelectingFromKeyboard = false
    private var isClosingWindow = false
    private var selectedIndex = 0
    private let restingWindowAlpha: CGFloat = 0.93
    private let startsHidden = CommandLine.arguments.contains("--start-hidden")
    private let togglesOnStart = CommandLine.arguments.contains("--toggle-on-start")

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        if terminateDuplicateAgentIfNeeded() {
            return
        }
        if let iconURL = Bundle.main.url(forResource: "AppIcon", withExtension: "icns"),
           let icon = NSImage(contentsOf: iconURL) {
            NSApp.applicationIconImage = icon
        }
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(handleToggleNotification),
            name: distributedNotificationName,
            object: nil
        )
        buildMenu()
        buildWindow()
        scanApps()
    }

    private func terminateDuplicateAgentIfNeeded() -> Bool {
        let currentPID = ProcessInfo.processInfo.processIdentifier
        let duplicate = NSWorkspace.shared.runningApplications.first { app in
            guard app.processIdentifier != currentPID else { return false }
            return app.bundleIdentifier == agentBundleIdentifier ||
                app.bundleURL?.path == agentBundlePath ||
                app.executableURL?.path == agentExecutablePath
        }

        guard duplicate != nil else { return false }
        if togglesOnStart {
            DistributedNotificationCenter.default().post(name: distributedNotificationName, object: nil)
        }
        NSApp.terminate(nil)
        return true
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if window?.isVisible == true {
            closeWindow()
        } else {
            showAndFocus()
        }
        return true
    }

    func applicationWillTerminate(_ notification: Notification) {
        DistributedNotificationCenter.default().removeObserver(self)
    }

    @objc private func handleToggleNotification() {
        if window?.isVisible == true {
            closeWindow()
        } else {
            showAndFocus()
        }
    }

    private func buildMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(withTitle: "关于 lauchingpad", action: #selector(NSApplication.orderFrontStandardAboutPanel(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "隐藏 lauchingpad", action: #selector(NSApplication.hide(_:)), keyEquivalent: "h")
        let hideOthers = appMenu.addItem(withTitle: "隐藏其他", action: #selector(NSApplication.hideOtherApplications(_:)), keyEquivalent: "h")
        hideOthers.keyEquivalentModifierMask = [.command, .option]
        appMenu.addItem(withTitle: "全部显示", action: #selector(NSApplication.unhideAllApplications(_:)), keyEquivalent: "")
        appMenu.addItem(.separator())
        appMenu.addItem(withTitle: "退出 lauchingpad", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q")
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        let editMenuItem = NSMenuItem()
        let editMenu = NSMenu(title: "编辑")
        editMenu.addItem(withTitle: "撤销", action: Selector(("undo:")), keyEquivalent: "z")
        let redo = editMenu.addItem(withTitle: "重做", action: Selector(("redo:")), keyEquivalent: "z")
        redo.keyEquivalentModifierMask = [.command, .shift]
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "剪切", action: #selector(NSText.cut(_:)), keyEquivalent: "x")
        editMenu.addItem(withTitle: "复制", action: #selector(NSText.copy(_:)), keyEquivalent: "c")
        editMenu.addItem(withTitle: "粘贴", action: #selector(NSText.paste(_:)), keyEquivalent: "v")
        editMenu.addItem(withTitle: "删除", action: #selector(NSText.delete(_:)), keyEquivalent: "")
        editMenu.addItem(.separator())
        editMenu.addItem(withTitle: "全选", action: #selector(NSText.selectAll(_:)), keyEquivalent: "a")
        editMenuItem.submenu = editMenu
        mainMenu.addItem(editMenuItem)

        let fileMenuItem = NSMenuItem()
        let fileMenu = NSMenu(title: "文件")
        let close = fileMenu.addItem(withTitle: "关闭窗口", action: #selector(closeWindow), keyEquivalent: "w")
        close.target = self
        fileMenuItem.submenu = fileMenu
        mainMenu.addItem(fileMenuItem)

        let searchMenuItem = NSMenuItem()
        let searchMenu = NSMenu(title: "搜索")
        let focusSearch = searchMenu.addItem(withTitle: "搜索", action: #selector(focusSearchField), keyEquivalent: "f")
        focusSearch.target = self
        let focusSearchAlt = searchMenu.addItem(withTitle: "定位到搜索框", action: #selector(focusSearchField), keyEquivalent: "l")
        focusSearchAlt.target = self
        let rescan = searchMenu.addItem(withTitle: "重新扫描应用", action: #selector(rescanApplications), keyEquivalent: "r")
        rescan.target = self
        searchMenuItem.submenu = searchMenu
        mainMenu.addItem(searchMenuItem)

        NSApp.mainMenu = mainMenu
    }

    private func buildWindow() {
        let root = LiquidGlassView()

        let content = NSView()
        content.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(content)

        searchPanel.translatesAutoresizingMaskIntoConstraints = false

        searchField.translatesAutoresizingMaskIntoConstraints = false
        searchField.placeholderString = ""
        searchField.font = .systemFont(ofSize: 18)
        searchField.delegate = self
        searchField.controlSize = .large
        searchField.isBordered = false
        searchField.isBezeled = false
        searchField.focusRingType = .none
        searchField.drawsBackground = false
        searchField.backgroundColor = .clear

        statusLabel.translatesAutoresizingMaskIntoConstraints = false
        statusLabel.font = .systemFont(ofSize: 13)
        statusLabel.textColor = .secondaryLabelColor

        let layout = NSCollectionViewFlowLayout()
        layout.itemSize = NSSize(width: 120, height: 122)
        layout.minimumInteritemSpacing = 12
        layout.minimumLineSpacing = 14
        layout.sectionInset = NSEdgeInsets(top: 18, left: 22, bottom: 22, right: 22)

        collectionView.collectionViewLayout = layout
        collectionView.register(AppCell.self, forItemWithIdentifier: AppCell.identifier)
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.isSelectable = true
        collectionView.allowsMultipleSelection = false
        collectionView.backgroundColors = [.clear]
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.wantsLayer = true
        collectionView.layer?.drawsAsynchronously = true

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.documentView = collectionView
        scrollView.hasVerticalScroller = true
        scrollView.scrollerStyle = .overlay
        scrollView.verticalScrollElasticity = .allowed
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder

        content.addSubview(searchPanel)
        searchPanel.addSubview(searchField)
        content.addSubview(statusLabel)
        content.addSubview(scrollView)

        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 18),
            content.trailingAnchor.constraint(equalTo: root.trailingAnchor, constant: -18),
            content.topAnchor.constraint(equalTo: root.topAnchor, constant: 18),
            content.bottomAnchor.constraint(equalTo: root.bottomAnchor, constant: -18),

            searchPanel.topAnchor.constraint(equalTo: content.safeAreaLayoutGuide.topAnchor, constant: 18),
            searchPanel.centerXAnchor.constraint(equalTo: content.centerXAnchor),
            searchPanel.widthAnchor.constraint(greaterThanOrEqualToConstant: 360),
            searchPanel.widthAnchor.constraint(lessThanOrEqualToConstant: 640),
            searchPanel.leadingAnchor.constraint(greaterThanOrEqualTo: content.leadingAnchor, constant: 28),
            searchPanel.trailingAnchor.constraint(lessThanOrEqualTo: content.trailingAnchor, constant: -28),
            searchPanel.heightAnchor.constraint(equalToConstant: 58),

            searchField.leadingAnchor.constraint(equalTo: searchPanel.leadingAnchor, constant: 14),
            searchField.trailingAnchor.constraint(equalTo: searchPanel.trailingAnchor, constant: -14),
            searchField.centerYAnchor.constraint(equalTo: searchPanel.centerYAnchor),

            statusLabel.topAnchor.constraint(equalTo: searchPanel.bottomAnchor, constant: 24),
            statusLabel.centerXAnchor.constraint(equalTo: content.centerXAnchor),

            scrollView.topAnchor.constraint(equalTo: statusLabel.bottomAnchor, constant: 18),
            scrollView.leadingAnchor.constraint(equalTo: content.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: content.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: content.bottomAnchor)
        ])

        window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 980, height: 700),
            styleMask: [.titled, .closable, .miniaturizable, .resizable, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        window.title = "lauchingpad"
        window.isOpaque = false
        window.backgroundColor = .clear
        window.hasShadow = true
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.isMovableByWindowBackground = true
        window.contentView = root
        window.center()
        window.minSize = NSSize(width: 680, height: 460)
        if !startsHidden || togglesOnStart {
            showAndFocus()
        }
    }

    private func showAndFocus() {
        let shouldAnimateIn = window?.isVisible == false
        if shouldAnimateIn {
            window?.alphaValue = 0
            window?.contentView?.layer?.transform = CATransform3DMakeScale(0.97, 0.97, 1)
        }

        isClosingWindow = false
        window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
        window?.makeFirstResponder(searchField)

        if shouldAnimateIn {
            NSAnimationContext.runAnimationGroup { context in
                context.duration = 0.22
                context.timingFunction = CAMediaTimingFunction(name: .easeOut)
                window?.animator().alphaValue = restingWindowAlpha
                window?.contentView?.animator().layer?.transform = CATransform3DIdentity
            }
        } else {
            window?.alphaValue = restingWindowAlpha
            window?.contentView?.layer?.transform = CATransform3DIdentity
        }
    }

    @objc private func focusSearchField() {
        showAndFocus()
        window?.makeFirstResponder(searchField)
        searchField.currentEditor()?.selectAll(nil)
    }

    @objc private func closeWindow() {
        guard !isClosingWindow, window?.isVisible == true else { return }
        isClosingWindow = true

        let originalFrame = window.frame
        var targetFrame = originalFrame
        targetFrame.size.width *= 0.94
        targetFrame.size.height *= 0.94
        targetFrame.origin.x += (originalFrame.width - targetFrame.width) / 2
        targetFrame.origin.y += 26

        NSAnimationContext.runAnimationGroup { context in
            context.duration = 0.24
            context.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            window?.animator().alphaValue = 0
            window?.animator().setFrame(targetFrame, display: true)
        } completionHandler: { [weak self] in
            self?.window?.orderOut(nil)
            self?.window?.alphaValue = self?.restingWindowAlpha ?? 1
            self?.window?.setFrame(originalFrame, display: false)
            self?.isClosingWindow = false
        }
    }

    @objc private func rescanApplications() {
        statusLabel.stringValue = "正在扫描应用..."
        scanApps()
    }

    private func scanApps() {
        DispatchQueue.global(qos: .userInitiated).async {
            let apps = self.loadApplications()
            AppIconProvider.shared.warm(Array(apps.prefix(80)))

            DispatchQueue.main.async {
                self.allApps = apps
                self.applyFilter()
            }
        }
    }

    private func loadApplications() -> [AppEntry] {
        let home = FileManager.default.homeDirectoryForCurrentUser.path
        let roots = [
            "/Applications",
            "\(home)/Applications",
            "/System/Applications",
            "/System/Volumes/Preboot/Cryptexes/App/System/Applications"
        ]

        var seenPaths = Set<String>()
        var seenBundleIdentifiers = Set<String>()
        var apps: [AppEntry] = []

        for rootPath in roots {
            var isDirectory: ObjCBool = false
            guard FileManager.default.fileExists(atPath: rootPath, isDirectory: &isDirectory), isDirectory.boolValue else {
                continue
            }

            guard let enumerator = FileManager.default.enumerator(
                at: URL(fileURLWithPath: rootPath),
                includingPropertiesForKeys: [.isDirectoryKey, .isPackageKey, .isApplicationKey],
                options: [.skipsHiddenFiles],
                errorHandler: nil
            ) else {
                continue
            }

            for case let url as URL in enumerator {
                if url.pathExtension.lowercased() != "app" {
                    continue
                }

                enumerator.skipDescendants()

                let standardizedPath = url.standardizedFileURL.path
                guard !seenPaths.contains(standardizedPath) else { continue }

                let bundle = Bundle(url: url)
                let bundleIdentifier = bundle?.bundleIdentifier
                if let bundleIdentifier, seenBundleIdentifiers.contains(bundleIdentifier) {
                    continue
                }

                let info = bundle?.infoDictionary
                if (info?["LSUIElement"] as? Bool) == true || (info?["LSBackgroundOnly"] as? Bool) == true {
                    continue
                }

                let displayName = FileManager.default.displayName(atPath: standardizedPath)
                    .replacingOccurrences(of: ".app", with: "")

                guard !displayName.isEmpty else { continue }

                seenPaths.insert(standardizedPath)
                if let bundleIdentifier {
                    seenBundleIdentifiers.insert(bundleIdentifier)
                }

                apps.append(AppEntry(
                    name: displayName,
                    path: standardizedPath,
                    url: URL(fileURLWithPath: standardizedPath),
                    bundleIdentifier: bundleIdentifier
                ))
            }
        }

        return apps.sorted {
            $0.name.localizedStandardCompare($1.name) == .orderedAscending
        }
    }

    private func applyFilter() {
        let query = searchField.stringValue.trimmingCharacters(in: .whitespacesAndNewlines)

        if query.isEmpty {
            filteredApps = allApps
        } else {
            filteredApps = allApps.filter { entry in
                entry.name.localizedCaseInsensitiveContains(query)
                    || entry.path.localizedCaseInsensitiveContains(query)
                    || (entry.bundleIdentifier?.localizedCaseInsensitiveContains(query) ?? false)
            }
        }

        collectionView.reloadData()
        selectedIndex = 0

        if filteredApps.isEmpty {
            collectionView.deselectAll(nil)
            statusLabel.stringValue = query.isEmpty ? "没有找到应用" : "没有匹配结果"
        } else {
            statusLabel.stringValue = "\(filteredApps.count) 个应用"
            selectApp(at: selectedIndex)
            let warmList = Array(filteredApps.prefix(120))
            DispatchQueue.global(qos: .utility).async {
                AppIconProvider.shared.warm(warmList)
            }
        }
    }

    private func clearSearch() {
        searchField.stringValue = ""
        applyFilter()
    }

    private func openFirstResult() {
        guard !filteredApps.isEmpty else { return }
        let index = min(max(selectedIndex, 0), filteredApps.count - 1)
        openApp(filteredApps[index])
    }

    private func selectApp(at index: Int) {
        guard !filteredApps.isEmpty else {
            collectionView.deselectAll(nil)
            return
        }

        selectedIndex = min(max(index, 0), filteredApps.count - 1)
        let indexPath = IndexPath(item: selectedIndex, section: 0)

        isSelectingFromKeyboard = true
        collectionView.deselectAll(nil)
        collectionView.selectItems(at: [indexPath], scrollPosition: [])
        collectionView.scrollToItems(at: [indexPath], scrollPosition: .nearestVerticalEdge)
        refreshVisibleSelectionAppearance()

        DispatchQueue.main.async { [weak self] in
            self?.isSelectingFromKeyboard = false
        }
    }

    private func moveSelection(horizontal: Int = 0, vertical: Int = 0) {
        guard !filteredApps.isEmpty else { return }

        let columns = max(1, currentColumnCount())
        let nextIndex = selectedIndex + horizontal + (vertical * columns)
        selectApp(at: nextIndex)
    }

    private func currentColumnCount() -> Int {
        guard let layout = collectionView.collectionViewLayout as? NSCollectionViewFlowLayout else {
            return 1
        }

        let sectionInset = layout.sectionInset
        let usableWidth = max(1, collectionView.bounds.width - sectionInset.left - sectionInset.right)
        let itemWidth = layout.itemSize.width
        let spacing = layout.minimumInteritemSpacing
        return max(1, Int((usableWidth + spacing) / (itemWidth + spacing)))
    }

    private func openApp(_ entry: AppEntry) {
        let configuration = NSWorkspace.OpenConfiguration()
        configuration.activates = true
        closeWindow()

        NSWorkspace.shared.openApplication(at: entry.url, configuration: configuration) { [weak self] _, error in
            DispatchQueue.main.async {
                if let error {
                    self?.showAndFocus()
                    self?.showOpenError(for: entry, error: error)
                }
            }
        }
    }

    private func refreshVisibleSelectionAppearance() {
        for case let item as AppCell in collectionView.visibleItems() {
            item.isSelected = collectionView.selectionIndexPaths.contains(item.collectionView?.indexPath(for: item) ?? IndexPath(item: -1, section: -1))
        }
    }

    private func showOpenError(for entry: AppEntry, error: Error) {
        let alert = NSAlert()
        alert.messageText = "无法打开 \(entry.name)"
        alert.informativeText = error.localizedDescription
        alert.alertStyle = .warning
        alert.runModal()
    }

    func controlTextDidChange(_ obj: Notification) {
        applyFilter()
    }

    func control(_ control: NSControl, textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
        if commandSelector == #selector(NSResponder.insertNewline(_:)) {
            openFirstResult()
            return true
        }

        if commandSelector == #selector(NSResponder.cancelOperation(_:)) {
            closeWindow()
            return true
        }

        if commandSelector == #selector(NSResponder.moveLeft(_:)) {
            moveSelection(horizontal: -1)
            return true
        }

        if commandSelector == #selector(NSResponder.moveRight(_:)) {
            moveSelection(horizontal: 1)
            return true
        }

        if commandSelector == #selector(NSResponder.moveUp(_:)) {
            moveSelection(vertical: -1)
            return true
        }

        if commandSelector == #selector(NSResponder.moveDown(_:)) {
            moveSelection(vertical: 1)
            return true
        }

        return false
    }

    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        1
    }

    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        filteredApps.count
    }

    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        let item = collectionView.makeItem(withIdentifier: AppCell.identifier, for: indexPath)
        if let appCell = item as? AppCell {
            appCell.configure(with: filteredApps[indexPath.item])
        }
        return item
    }

    func collectionView(_ collectionView: NSCollectionView, didSelectItemsAt indexPaths: Set<IndexPath>) {
        guard !isSelectingFromKeyboard, !isLaunchingFromSelection, let indexPath = indexPaths.first, indexPath.item < filteredApps.count else {
            return
        }

        selectedIndex = indexPath.item
        isLaunchingFromSelection = true
        openApp(filteredApps[indexPath.item])

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.collectionView.deselectItems(at: indexPaths)
            self?.isLaunchingFromSelection = false
        }
    }
}

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate
app.run()
