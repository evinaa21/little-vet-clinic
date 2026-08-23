import SwiftUI

@main
struct PuffApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // Puff has no ordinary windows — the floating panel and the menu bar item
        // are created by the app delegate. This empty Settings scene exists purely
        // so the App protocol has a body; the real settings live in their own window.
        Settings { EmptyView() }
    }
}