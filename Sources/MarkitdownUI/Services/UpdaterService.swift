import AppKit
import Sparkle

/// Wraps Sparkle's `SPUStandardUpdaterController` and exposes a single
/// `checkForUpdates()` method for use by the menu bar.
@MainActor
final class UpdaterService {
    let updaterController: SPUStandardUpdaterController

    init() {
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: nil,
            userDriverDelegate: nil
        )
    }

    func checkForUpdates() {
        updaterController.checkForUpdates(nil)
    }

    /// Whether Sparkle is in a state where it can begin a user-initiated check.
    var canCheckForUpdates: Bool {
        updaterController.updater.canCheckForUpdates
    }
}
