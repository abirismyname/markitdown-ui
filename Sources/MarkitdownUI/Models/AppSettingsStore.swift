import Foundation

@MainActor
final class AppSettingsStore: ObservableObject {
    @Published var cliPath: String {
        didSet { UserDefaults.standard.set(cliPath, forKey: Keys.cliPath) }
    }

    @Published var keepDataURIs: Bool {
        didSet { UserDefaults.standard.set(keepDataURIs, forKey: Keys.keepDataURIs) }
    }

    init() {
        let defaults = UserDefaults.standard
        let bundledPath = Self.bundledMarkitdownPath()
        let savedPath = defaults.string(forKey: Keys.cliPath)
        
        // Use bundled path if available, otherwise use saved path, otherwise use default
        self.cliPath = bundledPath ?? savedPath ?? "/Users/abirmajumdar/.local/bin/markitdown"
        self.keepDataURIs = defaults.object(forKey: Keys.keepDataURIs) as? Bool ?? false
    }

    func validationError() -> String? {
        if cliPath.isEmpty {
            return "MarkItDown CLI path cannot be empty."
        }

        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: cliPath, isDirectory: &isDirectory), !isDirectory.boolValue else {
            return "MarkItDown CLI path does not point to a file."
        }

        guard FileManager.default.isExecutableFile(atPath: cliPath) else {
            return "MarkItDown CLI is not executable."
        }

        return nil
    }

    static func bundledMarkitdownPath() -> String? {
        // SwiftPM resources (debug/release via `swift build`) live in Bundle.module.
        if let bundledURL = Bundle.module.url(forResource: "markitdown", withExtension: nil) {
            let bundledPath = bundledURL.path
            if FileManager.default.fileExists(atPath: bundledPath),
                FileManager.default.isExecutableFile(atPath: bundledPath) {
                return bundledPath
            }
        }

        // Packaged app fallback where resources are copied under Contents/Resources/.
        if let bundlePath = Bundle.main.resourcePath {
            let markitdownPath = (bundlePath as NSString).appendingPathComponent("markitdown/markitdown")
            if FileManager.default.fileExists(atPath: markitdownPath),
                FileManager.default.isExecutableFile(atPath: markitdownPath) {
                return markitdownPath
            }
        }
        return nil
    }
}

private enum Keys {
    static let cliPath = "settings.cliPath"
    static let keepDataURIs = "settings.keepDataURIs"
}

