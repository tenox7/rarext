import SwiftUI

public struct RARCommandView: View {
    let command: String
    @StateObject private var console = Console()
    @State private var isRunning: Bool = false
    @State private var task: Process?
    @Environment(\.dismiss) private var dismiss

    public init(command: String) {
        self.command = command
    }

    public var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Running RAR Command")
                    .font(.headline)
                Spacer()
                if isRunning {
                    ProgressView()
                        .scaleEffect(0.5)
                }
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))

            ConsoleView(console: console)

            HStack {
                Spacer()
                if isRunning {
                    Button("Kill") {
                        killCommand()
                    }
                    .keyboardShortcut("k", modifiers: .command)
                }
                Button("Close") {
                    killCommand()
                    dismiss()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        NSApplication.shared.terminate(nil)
                    }
                }
                .keyboardShortcut(.cancelAction)
            }
            .padding()
            .background(Color(nsColor: .controlBackgroundColor))
        }
        .frame(minWidth: 600, minHeight: 400)
        .onAppear {
            runCommand()
        }
    }

    private func killCommand() {
        if let task = task, task.isRunning {
            task.terminate()
            console.append("\n\nCommand terminated by user\n")
        }
    }

    private func runCommand() {
        isRunning = true
        console.append("$ \(command)\n\n")

        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", command]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
        } catch {
            console.append("Error: \(error.localizedDescription)\n")
            isRunning = false
            return
        }
        task = process

        let console = console
        DispatchQueue.global().async {
            let handle = pipe.fileHandleForReading
            var pending = Data()
            while case let data = handle.availableData, !data.isEmpty {
                pending += data
                // cut after last ASCII byte so UTF-8 chars split across reads stay intact
                guard let last = pending.lastIndex(where: { $0 < 0x80 }) else { continue }
                let text = String(decoding: pending[...last], as: UTF8.self)
                pending.removeSubrange(...last)
                DispatchQueue.main.async { console.append(text) }
            }
            process.waitUntilExit()
            let rest = String(decoding: pending, as: UTF8.self)
            DispatchQueue.main.async {
                isRunning = false
                console.append(rest + "\n\nCommand completed with exit code: \(process.terminationStatus)\n")
            }
        }
    }
}

@MainActor
final class Console: ObservableObject {
    let scrollView = NSTextView.scrollableTextView()
    private var textView: NSTextView { scrollView.documentView as! NSTextView }
    private let attributes: [NSAttributedString.Key: Any] = [
        .font: NSFont.monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular),
        .foregroundColor: NSColor.textColor,
    ]

    init() {
        textView.isEditable = false
        textView.textContainerInset = NSSize(width: 10, height: 10)
    }

    func append(_ text: String) {
        guard let storage = textView.textStorage else { return }
        var out = String.UnicodeScalarView()
        var erase = 0
        for c in text.unicodeScalars {
            if c != "\u{8}" {
                out.append(c)
            } else if out.isEmpty {
                erase += 1
            } else {
                out.removeLast()
            }
        }
        erase = min(erase, storage.length)
        storage.replaceCharacters(in: NSRange(location: storage.length - erase, length: erase),
                                  with: NSAttributedString(string: String(out), attributes: attributes))
        textView.scrollToEndOfDocument(nil)
    }
}

private struct ConsoleView: NSViewRepresentable {
    let console: Console

    func makeNSView(context: Context) -> NSScrollView { console.scrollView }
    func updateNSView(_ nsView: NSScrollView, context: Context) {}
}
