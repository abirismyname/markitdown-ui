import AppKit
import SwiftUI

@MainActor
final class PreferencesWindowController {
    private let window: NSWindow
    private let settings: AppSettingsStore

    init(settings: AppSettingsStore) {
        self.settings = settings

        let window = NSWindow(
            contentRect: .zero,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Preferences"
        window.isReleasedWhenClosed = false
        window.center()
        self.window = window
    }

    func show() {
        let contentView = PreferencesView(settings: settings) {
            window.close()
        }
        let hostingController = NSHostingController(rootView: contentView)
        window.contentViewController = hostingController
        window.setContentSize(hostingController.preferredContentSize)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
