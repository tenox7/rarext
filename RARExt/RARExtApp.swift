import SwiftUI
import RARExtFeature

@main
struct RARExtApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .defaultSize(width: 550, height: 700)
        .handlesExternalEvents(matching: ["open"])
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first,
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            return
        }

        let files = queryItems.compactMap { item in
            item.name.hasPrefix("file") ? item.value : nil
        }

        NotificationCenter.default.post(name: NSNotification.Name("LoadFiles"), object: files)
    }
}
