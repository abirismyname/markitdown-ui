import AppKit
import SwiftUI

@MainActor
final class DropWindowController {
    private let window: NSWindow

    init(conversionManager: ConversionManager) {
        let contentView = DropZoneView(conversionManager: conversionManager)
        let hostingController = NSHostingController(rootView: contentView)

        let window = NSWindow(contentViewController: hostingController)
        window.title = "MarkItDown"
        window.styleMask = [.titled, .closable, .miniaturizable]
        window.setContentSize(NSSize(width: 560, height: 420))
        window.isReleasedWhenClosed = false
        window.center()

        self.window = window
    }

    func show() {
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
