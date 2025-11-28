import Foundation
import AppKit

class ActionRequestHandler: NSObject, NSExtensionRequestHandling {

    func beginRequest(with context: NSExtensionContext) {
        guard let inputItems = context.inputItems as? [NSExtensionItem] else {
            context.completeRequest(returningItems: [], completionHandler: nil)
            return
        }

        var filePaths: [String] = []
        let group = DispatchGroup()

        for item in inputItems {
            guard let attachments = item.attachments else { continue }

            for itemProvider in attachments {
                for typeIdentifier in itemProvider.registeredTypeIdentifiers {
                    group.enter()
                    itemProvider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { (item, error) in
                        defer { group.leave() }

                        if error != nil { return }

                        if let url = item as? URL {
                            filePaths.append(url.path)
                        } else if let data = item as? Data,
                                  let url = URL(dataRepresentation: data, relativeTo: nil) {
                            filePaths.append(url.path)
                        } else if let string = item as? String {
                            filePaths.append(string)
                        }
                    }

                    if typeIdentifier.contains("file") { break }
                }
            }
        }

        group.notify(queue: .main) {
            self.openMainApp(with: filePaths, context: context)
        }
    }

    private func openMainApp(with paths: [String], context: NSExtensionContext) {
        var components = URLComponents(string: "rarext://open")!
        components.queryItems = paths.enumerated().map { index, path in
            URLQueryItem(name: "file\(index)", value: path)
        }

        if let url = components.url {
            NSWorkspace.shared.open(url)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            context.completeRequest(returningItems: [], completionHandler: nil)
        }
    }
}
