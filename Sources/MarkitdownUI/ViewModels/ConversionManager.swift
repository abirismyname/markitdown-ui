import AppKit
import Foundation

@MainActor
final class ConversionManager: ObservableObject {
    @Published var state: ConversionState = .idle
    @Published var milestoneCelebration: String? = nil

    private let settings: AppSettingsStore
    
    private var conversionCount: Int {
        get { UserDefaults.standard.integer(forKey: "com.markitdown.conversionCount") }
        set { UserDefaults.standard.set(newValue, forKey: "com.markitdown.conversionCount") }
    }

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
                    self.checkMilestone()
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

    private func checkMilestone() {
        conversionCount += 1
        
        switch conversionCount {
        case 10:
            milestoneCelebration = "🎊 10 files converted! You're on fire! 🔥"
        case 50:
            milestoneCelebration = "🏆 50 conversions! You're a Markdown master! 👑"
        case 100:
            milestoneCelebration = "👏 100 files! You deserve a medal! 🥇"
        default:
            milestoneCelebration = nil
        }
        
        // Show milestone for 2 seconds
        if milestoneCelebration != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.milestoneCelebration = nil
            }
        }
    }
}
