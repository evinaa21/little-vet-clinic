import AppKit
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

    private let store = PatientStore()
    private let settings = AppSettings()
    private let presentation = PanelPresentation()

    private var panel: FloatingPanel?
    private var statusItem: NSStatusItem?

    // MARK: Launch

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Menu-bar-only app: no Dock icon, no app menu.
        NSApp.setActivationPolicy(.accessory)

        buildPanel()
        buildStatusItem()

        HotKeyManager.shared.onFire = { [weak self] in self?.togglePanel() }
        HotKeyManager.shared.register()

        showPanel()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool { true }

    func applicationWillTerminate(_ notification: Notification) {
        store.save()
        HotKeyManager.shared.unregister()
    }

    // MARK: Panel

    private func buildPanel() {
        let root = ClipboardView()
            .environmentObject(store)
            .environmentObject(settings)
            .environmentObject(presentation)

        let panel = FloatingPanel(view: root)
        panel.onMove = { [weak self] origin in self?.settings.panelOrigin = origin }
        panel.restore(origin: settings.panelOrigin)
        self.panel = panel
    }

    private func showPanel() {
        guard let panel else { return }
        // Roll the sheet up *before* the window is on screen, so the first frame
        // anyone sees is the bare clip rather than a full sheet that then collapses.
        presentation.prepareForOpen()
        panel.restore(origin: settings.panelOrigin)
        // Activating lets the check-in field actually receive keystrokes; the panel
        // stays non-activating for ordinary clicks like marking a patient seen.
        NSApp.activate(ignoringOtherApps: true)
        panel.makeKeyAndOrderFront(nil)

        // One turn of the run loop, so SwiftUI has drawn the rolled-up state and
        // the feed animates from it rather than starting mid-way.
        DispatchQueue.main.async { [weak self] in
            guard let self else { return }
            self.presentation.open()
            if self.settings.soundEnabled { SoundPlayer.shared.playUnroll() }
        }
    }

    private func hidePanel() {
        guard let panel else { return }
        SoundPlayer.shared.stopUnroll()   // closing mid-feed shouldn't leave it running
        presentation.close { panel.orderOut(nil) }
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
            let image = NSImage(systemSymbolName: "pawprint.fill", accessibilityDescription: "Little Vet Clinic")
            image?.isTemplate = true
            button.image = image
            button.target = self
            button.action = #selector(statusItemClicked(_:))
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
            button.toolTip = "Little Vet Clinic — \(HotKeyManager.displayString) to show or hide"
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
            title: (panel?.isVisible ?? false) ? "Hide Clinic" : "Show Clinic",
            action: #selector(togglePanel),
            keyEquivalent: ""
        )
        toggle.target = self
        menu.addItem(toggle)

        menu.addItem(.separator())

        // The entire settings surface: one switch.
        let sound = NSMenuItem(title: "Stamp Sound", action: #selector(toggleSound), keyEquivalent: "")
        sound.target = self
        sound.state = settings.soundEnabled ? .on : .off
        menu.addItem(sound)

        menu.addItem(.separator())

        let quit = NSMenuItem(title: "Quit Little Vet Clinic", action: #selector(quit), keyEquivalent: "q")
        quit.target = self
        menu.addItem(quit)

        // Attaching the menu for exactly one click keeps left-click free for toggling.
        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func toggleSound() {
        settings.soundEnabled.toggle()
    }

    @objc private func quit() {
        NSApp.terminate(nil)
    }
}
