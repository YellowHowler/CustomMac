import SwiftUI

@main
struct CustomMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // No WindowGroup – no visible window at all
        Settings {
            EmptyView() // Optional settings scene
        }
    }
}
