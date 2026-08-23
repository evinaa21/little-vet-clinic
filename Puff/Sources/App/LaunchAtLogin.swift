import Foundation
import ServiceManagement

/// Thin wrapper over `SMAppService` (macOS 13+), which registers the app itself
/// as a login item — no helper bundle, no deprecated LSSharedFileList.
enum LaunchAtLogin {

    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    /// Returns the state actually achieved, so the UI can snap back if macOS refused.
    @discardableResult
    static func set(_ enabled: Bool) -> Bool {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            NSLog("Puff: launch at login change failed — \(error.localizedDescription)")
        }
        return isEnabled
    }
}