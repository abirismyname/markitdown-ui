import AppKit
import SwiftUI

@MainActor
final class AboutWindowController {
    private let window: NSWindow

    init() {
        let contentView = AboutView()
        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "About MarkyMarkdown"
        window.styleMask = [.titled, .closable]
        window.setContentSize(NSSize(width: 560, height: 440))
        window.isReleasedWhenClosed = false
        window.center()

        self.window = window
    }

    func show() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}