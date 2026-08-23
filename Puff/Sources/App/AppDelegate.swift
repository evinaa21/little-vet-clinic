import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

    private let store = TaskStore()
    private let settings = AppSettings()

    private var panel: FloatingPanel?
    private var statusItem: NSStatusItem?
    private var settingsWindow: NSWindow?

    // MARK: Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu-bar-only app: no Dock icon, no app menu.
        NSApp.setActivationPolicy(.accessory)

        buildPanel()
        buildStatusItem()

        settings.onHotKeyChange = { combo in
            HotKeyManager.shared.register(combo)
        }
        HotKeyManager.shared.onFire = { [weak self] in
            self?.togglePanel()
        }
        HotKeyManager.shared.register(settings.hotKey)

        showPanel()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }

    func applicationWillTerminate(_ notification: Notification) {
        store.save()
        HotKeyManager.shared.unregister()
    }

    // MARK: Panel

    private func buildPanel() {
        let root = PanelView(onOpenSettings: { [weak self] in self?.openSettings() })
            .environmentObject(store)
            .environmentObject(settings)

        let panel = FloatingPanel(view: root)
        panel.onMove = { [weak self] origin in
            self?.settings.panelOrigin = origin
        }
        panel.restore(origin: settings.panelOrigin)
        self.panel = panel
    }

    private func showPanel() {
        guard let panel else { return }
        panel.restore(origin: settings.panelOrigin)
        // Activating lets the quick-add field actually receive keystrokes; the panel
        // stays non-activating for ordinary clicks like checking a box.
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)
    }

    private func hidePanel() {
        panel?.orderOut(nil)
    }

    @objc func togglePanel() {
        guard let panel else { return }
        if panel.isVisible {
            hidePanel()
        } else {
            showPanel()
        }
    }

    // MARK: Menu bar

    private func buildStatusItem() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = item.button {
            let image = NSImage(systemSymbolName: "cloud.fill", accessibilityDescription: "Puff")
            image?.isTemplate = true
            button.image = image
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "Puff — \(settings.hotKey.displayString) to show or hide"
        }
        statusItem = item
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let isRightClick = NSApp.currentEvent?.type == .rightMouseUp
            || NSApp.currentEvent?.modifierFlags.contains(.control) == true

        if isRightClick {
            showStatusMenu()
        } else {
            togglePanel()
        }
    }

    private func showStatusMenu() {
        guard let statusItem else { return }
        let menu = NSMenu()

        let toggle = NSMenuItem(
            title: (panel?.isVisible ?? false) ? "Hide Puff" : "Show Puff",
            action: #selector(togglePanel),
            keyEquivalent: ""
        )
        toggle.target = self
        menu.addItem(toggle)

        menu.addItem(.separator())

        let settingsItem = NSMenuItem(title: "Settings…", action: #selector(openSettings), keyEquivalent: ",")
        settingsItem.target = self
        menu.addItem(settingsItem)

        let launchItem = NSMenuItem(title: "Launch at Login", action: #selector(toggleLaunchAtLogin), keyEquivalent: "")
        launchItem.target = self
        launchItem.state = LaunchAtLogin.isEnabled ? .on : .off
        menu.addItem(launchItem)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Puff", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        // Attaching the menu for exactly one click keeps left-click free for toggling.
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func toggleLaunchAtLogin() {
        LaunchAtLogin.set(!LaunchAtLogin.isEnabled)
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }

    // MARK: Settings window

    @objc func openSettings() {
        if settingsWindow == nil {
            let view = SettingsView()
                .environmentObject(settings)
                .environmentObject(store)

            let controller = NSHostingController(rootView: view)
            let window = NSWindow(contentViewController: controller)
            window.title = "Puff Settings"
            window.styleMask = [.titled, .closable, .fullSizeContentView]
            window.titlebarAppearsTransparent = true
            window.isReleasedWhenClosed = false
            window.center()
            settingsWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }
}