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
    private let extensionBundleID = "com.example.rarext.RARAction"
    private let registerOnly = CommandLine.arguments.contains("--register")

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        if registerOnly {
            NSApp.setActivationPolicy(.accessory)
            NSApp.windows.forEach { $0.orderOut(nil) }
        }
        registerExtensionIfNeeded()
        if registerOnly {
            NSApp.terminate(nil)
        }
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

    private func registerExtensionIfNeeded() {
        if isExtensionRegistered() { return }

        guard let appexPath = Bundle.main.builtInPlugInsURL?
            .appendingPathComponent("RAR.appex").path else { return }

        run("/usr/bin/pluginkit", arguments: ["-a", appexPath])
        run("/usr/bin/pluginkit", arguments: ["-e", "use", "-i", extensionBundleID])

        if isExtensionRegistered() { return }

        let lsregister = "/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister"
        run(lsregister, arguments: ["-f", Bundle.main.bundlePath])
        run("/usr/bin/pluginkit", arguments: ["-a", appexPath])
        run("/usr/bin/pluginkit", arguments: ["-e", "use", "-i", extensionBundleID])

        if isExtensionRegistered() || registerOnly { return }

        let alert = NSAlert()
        alert.messageText = "Finder Extension Registration Failed"
        alert.informativeText = "The RAR Finder extension could not be registered automatically.\n\nTry enabling it manually:\nSystem Settings → General → Login Items & Extensions → Extensions → Finder Extensions"
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "OK")
        if alert.runModal() == .alertFirstButtonReturn {
            NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.ExtensionsPreferences")!)
        }
    }

    private func isExtensionRegistered() -> Bool {
        let (output, status) = runCapture("/usr/bin/pluginkit", arguments: ["-m", "-i", extensionBundleID])
        return status == 0 && output.contains(extensionBundleID)
    }

    @discardableResult
    private func run(_ path: String, arguments: [String]) -> Int32 {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        process.standardOutput = FileHandle.nullDevice
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return -1
        }
        return process.terminationStatus
    }

    private func runCapture(_ path: String, arguments: [String]) -> (String, Int32) {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ("", -1)
        }
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        return (String(data: data, encoding: .utf8) ?? "", process.terminationStatus)
    }
}
