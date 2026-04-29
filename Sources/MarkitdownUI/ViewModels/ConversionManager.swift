import AppKit
import Foundation

@MainActor
final class ConversionManager: ObservableObject {
    @Published var state: ConversionState = .idle

    private let settings: AppSettingsStore

    init(settings: AppSettingsStore) {
        self.settings = settings
    }

    func convert(url: URL) {
        if let error = settings.validationError() {
            state = .failure(message: error)
            return
        }

        state = .converting(fileName: url.lastPathComponent)

        let cliPath = settings.cliPath
        let keepDataURIs = settings.keepDataURIs

        Task.detached(priority: .userInitiated) {
            do {
                let service = MarkitdownConversionService(cliPath: cliPath, keepDataURIs: keepDataURIs)
                let result = try service.convertFile(at: url)

                await MainActor.run {
                    self.state = .success(outputURL: result.outputURL)
                }
            } catch {
                await MainActor.run {
                    self.state = .failure(message: error.localizedDescription)
                }
            }
        }
    }

    func convert(urls: [URL]) {
        guard let first = urls.first else { return }
        convert(url: first)
    }

    func resetState() {
        state = .idle
    }

    func revealOutputInFinder() {
        guard case let .success(outputURL) = state else { return }
        NSWorkspace.shared.activateFileViewerSelecting([outputURL])
    }
}
