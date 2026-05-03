import AppKit
import SwiftUI

@MainActor
final class PreferencesWindowController {
    private let window: NSWindow

    init(settings: AppSettingsStore) {
        let contentView = PreferencesView(settings: settings)
        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "Preferences"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 520, height: 300))
        window.isReleasedWhenClosed = false
        window.center()

        self.window = window
    }

    func show() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
