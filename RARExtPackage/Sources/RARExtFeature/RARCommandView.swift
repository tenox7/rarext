import SwiftUI

public struct RARCommandView: View {
    let command: String
    @State private var output: String = ""
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

            ScrollViewReader { proxy in
                ScrollView {
                    Text(output)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .id("output")
                }
                .onChange(of: output) { _ in
                    proxy.scrollTo("output", anchor: .bottom)
                }
            }

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
            output += "\n\nCommand terminated by user\n"
        }
    }

    private func runCommand() {
        isRunning = true
        output = "$ \(command)\n\n"

        let process = Process()
        process.launchPath = "/bin/sh"
        process.arguments = ["-c", command]

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        pipe.fileHandleForReading.readabilityHandler = { handle in
            let data = handle.availableData
            if !data.isEmpty, let text = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    output += text
                }
            }
        }

        process.terminationHandler = { _ in
            DispatchQueue.main.async {
                isRunning = false
                output += "\n\nCommand completed with exit code: \(process.terminationStatus)\n"
            }
        }

        task = process

        do {
            try process.run()
        } catch {
            output += "Error: \(error.localizedDescription)\n"
            isRunning = false
        }
    }
}
