import SwiftUI

@main
struct LittleVetClinicApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        // The clinic has no ordinary windows — the floating clipboard and the menu
        // bar item are both built by the app delegate. This empty scene exists only
        // so the App protocol has a body.
        Settings { EmptyView() }
    }
}
