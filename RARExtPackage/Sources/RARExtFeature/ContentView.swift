import SwiftUI
import UniformTypeIdentifiers

public struct ContentView: View {
    @State private var selectedFiles: [String] = []
    @State private var archiveName = ""
    @State private var compressionLevel = 5
    @State private var usePassword = false
    @State private var password = ""
    @State private var createSolid = false
    @State private var createSFX = false
    @State private var recurseSubdirs = true
    @State private var deleteAfter = false
    @State private var testAfter = false
    @State private var addRecovery = true
    @State private var lockArchive = false
    @State private var showAdvanced = false
    @State private var dictionarySize = 15
    @State private var threadCount = 0
    @State private var splitVolumes = false
    @State private var volumeSize = 4
    @State private var excludeDSStore = true
    @State private var showCommandWindow = false
    @State private var isExtractMode = false
    @State private var extractPath = ""
    @State private var overwriteFiles = true

    public init() {}

    public var body: some View {
        Group {
            if selectedFiles.isEmpty {
                dropZoneView
            } else {
                formView
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("LoadFiles"))) { notification in
            if let files = notification.object as? [String] {
                loadFiles(files)
            }
        }
    }

    private var dropZoneView: some View {
        VStack(spacing: 16) {
            Spacer()
            Image(systemName: "arrow.down.doc")
                .font(.system(size: 48))
                .foregroundStyle(.secondary)
            Text("Drop files or folders here")
                .font(.title2)
                .foregroundStyle(.secondary)
            Text("or")
                .foregroundStyle(.tertiary)
            Button("Browse...") {
                browseFiles()
            }
            .buttonStyle(.borderedProminent)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(32)
        .background {
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(style: StrokeStyle(lineWidth: 2, dash: [8]))
                .foregroundStyle(.tertiary)
                .padding(16)
        }
        .onDrop(of: [.fileURL], isTargeted: nil) { providers in
            loadDroppedFiles(providers)
            return true
        }
        .frame(minWidth: 500, minHeight: 400)
        .navigationTitle("RAR")
    }

    private var formView: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Text(buildCommand())
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .padding(8)
                        .background(Color(nsColor: .textBackgroundColor))
                        .cornerRadius(4)

                    Button("Run") {
                        showCommandWindow = true
                    }
                    .buttonStyle(.borderedProminent)
                    .sheet(isPresented: $showCommandWindow) {
                        RARCommandView(command: buildCommand())
                    }
                }
            } header: {
                Text("Command")
            }

            if isExtractMode {
                Section {
                    HStack {
                        TextField("Extract to", text: $extractPath)
                            .multilineTextAlignment(.leading)
                        Button("Browse...") {
                            selectExtractPath()
                        }
                    }
                } header: {
                    Text("Destination")
                }

                Section {
                    Toggle("Overwrite files", isOn: $overwriteFiles)
                    Toggle("Extract with full paths", isOn: $recurseSubdirs)

                    TextField("Password (if encrypted)", text: $password)
                } header: {
                    Text("Options")
                }
            } else {
                Section {
                    HStack {
                        TextField("Archive name", text: $archiveName, prompt: Text("archive.rar"))
                            .multilineTextAlignment(.leading)
                        Button("Browse...") {
                            selectArchiveLocation()
                        }
                    }
                } header: {
                    Text("Archive")
                }

                Section {
                    Picker("Compression", selection: $compressionLevel) {
                    Text("Store (0)").tag(0)
                    Text("Fastest (1)").tag(1)
                    Text("Fast (2)").tag(2)
                    Text("Normal (3)").tag(3)
                    Text("Good (4)").tag(4)
                    Text("Best (5)").tag(5)
                }

                Picker("Dictionary size", selection: $dictionarySize) {
                    Text("64 KB").tag(0)
                    Text("128 KB").tag(1)
                    Text("256 KB").tag(2)
                    Text("512 KB").tag(3)
                    Text("1 MB").tag(4)
                    Text("2 MB").tag(5)
                    Text("4 MB").tag(6)
                    Text("8 MB").tag(7)
                    Text("16 MB").tag(8)
                    Text("32 MB").tag(9)
                    Text("64 MB").tag(10)
                    Text("128 MB").tag(11)
                    Text("256 MB").tag(12)
                    Text("512 MB").tag(13)
                    Text("1 GB").tag(14)
                    Text("2 GB").tag(15)
                    Text("4 GB").tag(16)
                    Text("8 GB").tag(17)
                    Text("16 GB").tag(18)
                    Text("32 GB").tag(19)
                    Text("64 GB").tag(20)
                }

                    Toggle("Solid archive", isOn: $createSolid)
                    Toggle("Self-extracting (SFX)", isOn: $createSFX)
                } header: {
                    Text("Compression")
                }

                Section {
                    Toggle("Use password", isOn: $usePassword)
                    if usePassword {
                        TextField("Password", text: $password)
                    }
                } header: {
                    Text("Security")
                }

                Section {
                    Toggle("Recurse subdirectories", isOn: $recurseSubdirs)
                    Toggle("Delete files after archiving", isOn: $deleteAfter)
                    Toggle("Test archive after creation", isOn: $testAfter)
                    Toggle("Add recovery record", isOn: $addRecovery)
                    Toggle("Lock archive", isOn: $lockArchive)
                    Toggle("Exclude .DS_Store files", isOn: $excludeDSStore)

                    Stepper("Threads: \(threadCount == 0 ? "Auto" : "\(threadCount)")",
                           value: $threadCount, in: 0...16)

                    Toggle("Split into volumes", isOn: $splitVolumes)
                    if splitVolumes {
                        Picker("Volume size", selection: $volumeSize) {
                            Text("100 MB").tag(0)
                            Text("250 MB").tag(1)
                            Text("500 MB").tag(2)
                            Text("700 MB (CD)").tag(3)
                            Text("1 GB").tag(4)
                            Text("2 GB").tag(5)
                            Text("4.7 GB (DVD)").tag(6)
                        }
                    }
                } header: {
                    Text("Options")
                }
            }
        }
        .formStyle(.grouped)
        .frame(minWidth: 500, minHeight: 600)
        .navigationTitle(isExtractMode ? "RAR Extract Archive" : "RAR Create Archive")
    }

    private func buildCommand() -> String {
        var parts: [String] = ["/usr/local/bin/rar"]

        if isExtractMode {
            parts.append(recurseSubdirs ? "x" : "e")
            parts.append("-y")

            parts.append(overwriteFiles ? "-o+" : "-o-")

            if !password.isEmpty {
                parts.append("-p\(password)")
            }

            if let rarFile = selectedFiles.first {
                parts.append("\"\(rarFile)\"")
            }
            parts.append("\"\(extractPath)/\"")

            return parts.joined(separator: " ")
        }

        parts.append("a")
        parts.append("-y")
        parts.append("-ep1")

        parts.append("-m\(compressionLevel)")

        if createSolid {
            parts.append("-s")
        }

        if createSFX {
            parts.append("-sfx")
        }

        if !recurseSubdirs {
            parts.append("-r-")
        } else {
            parts.append("-r")
        }

        if deleteAfter {
            parts.append("-df")
        }

        if testAfter {
            parts.append("-t")
        }

        if addRecovery {
            parts.append("-rr")
        }

        if lockArchive {
            parts.append("-k")
        }

        if usePassword && !password.isEmpty {
            parts.append("-hp\(password)")
        }

        let dictSizes = ["64k", "128k", "256k", "512k", "1m", "2m", "4m", "8m", "16m", "32m", "64m", "128m", "256m", "512m", "1g", "2g", "4g", "8g", "16g", "32g", "64g"]
        if dictionarySize < dictSizes.count {
            parts.append("-md\(dictSizes[dictionarySize])")
        }

        if threadCount > 0 {
            parts.append("-mt\(threadCount)")
        }

        if splitVolumes {
            let volumeSizes = ["100m", "250m", "500m", "700m", "1g", "2g", "4700m"]
            if volumeSize < volumeSizes.count {
                parts.append("-v\(volumeSizes[volumeSize])")
            }
        }

        if excludeDSStore {
            parts.append("-x.DS_Store")
        }

        if !archiveName.isEmpty {
            parts.append("\"\(archiveName)\"")
        } else {
            parts.append("\"archive.rar\"")
        }

        for file in selectedFiles {
            parts.append("\"\(file)\"")
        }

        return parts.joined(separator: " ")
    }


    private func browseFiles() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = true
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = true
        guard panel.runModal() == .OK else { return }
        let paths = panel.urls.map(\.path)
        if !paths.isEmpty { loadFiles(paths) }
    }

    private func loadDroppedFiles(_ providers: [NSItemProvider]) {
        let group = DispatchGroup()
        var paths: [String] = []
        for provider in providers {
            guard provider.canLoadObject(ofClass: URL.self) else { continue }
            group.enter()
            _ = provider.loadObject(ofClass: URL.self) { url, _ in
                if let url { paths.append(url.path) }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            if !paths.isEmpty { loadFiles(paths) }
        }
    }

    private func loadFiles(_ files: [String]) {
        selectedFiles = files

        guard !files.isEmpty else { return }

        let firstFile = files[0]

        if files.count == 1, firstFile.hasSuffix(".rar") {
            isExtractMode = true
            extractPath = (firstFile as NSString).deletingPathExtension
            return
        }

        isExtractMode = false
        let directory = (firstFile as NSString).deletingLastPathComponent
        let baseName: String

        if files.count == 1 {
            var isDirectory: ObjCBool = false
            FileManager.default.fileExists(atPath: firstFile, isDirectory: &isDirectory)

            if !isDirectory.boolValue {
                recurseSubdirs = false
            }

            baseName = (firstFile as NSString).lastPathComponent
        } else {
            baseName = "archive"
        }

        archiveName = "\(directory)/\(baseName).rar"
    }

    private func selectExtractPath() {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.canCreateDirectories = true

        if panel.runModal() == .OK, let url = panel.url {
            extractPath = url.path
        }
    }

    private func selectArchiveLocation() {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.init(filenameExtension: "rar")!]
        panel.nameFieldStringValue = archiveName.isEmpty ? "archive.rar" : archiveName

        if panel.runModal() == .OK, let url = panel.url {
            archiveName = url.path
        }
    }
}
