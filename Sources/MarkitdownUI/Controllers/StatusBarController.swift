import AppKit
import QuartzCore

@MainActor
final class StatusBarController {
    private let statusItem: NSStatusItem
    private let conversionManager: ConversionManager
    private let openMainWindow: () -> Void
    private let openPreferences: () -> Void
    private let convertViaPicker: () -> Void

    private var menu: NSMenu?
    private var dropView: StatusBarDropView?

    private let checkForUpdates: () -> Void

    init(
        conversionManager: ConversionManager,
        openMainWindow: @escaping () -> Void,
        openPreferences: @escaping () -> Void,
        convertViaPicker: @escaping () -> Void,
        checkForUpdates: @escaping () -> Void
    ) {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.conversionManager = conversionManager
        self.openMainWindow = openMainWindow
        self.openPreferences = openPreferences
        self.convertViaPicker = convertViaPicker
        self.checkForUpdates = checkForUpdates

        configure()
    }

    func updateForState(_ state: ConversionState) {
        guard let button = statusItem.button else { return }

        switch state {
        case .idle:
            button.image = NSImage(systemSymbolName: "doc.text", accessibilityDescription: "MarkyMarkdown - Your friendly markdown converter! 🎉")
        case .converting:
            button.image = NSImage(systemSymbolName: "arrow.triangle.2.circlepath", accessibilityDescription: "Converting your file with markdown magic! ✨")
        case .success:
            button.image = NSImage(systemSymbolName: "checkmark.circle", accessibilityDescription: "Success! File converted beautifully! 🎊")
            // Brief scale pulse to celebrate the successful conversion
            button.wantsLayer = true
            if let layer = button.layer {
                let pulse = CABasicAnimation(keyPath: "transform.scale")
                pulse.fromValue = 1.0
                pulse.toValue = 1.35
                pulse.duration = 0.15
                pulse.autoreverses = true
                pulse.repeatCount = 2
                layer.add(pulse, forKey: "successPulse")
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
                self?.updateForState(.idle)
            }
        case .failure:
            button.image = NSImage(systemSymbolName: "exclamationmark.triangle", accessibilityDescription: "Conversion encountered an issue. Check Preferences! 🔍")
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
                self?.updateForState(.idle)
            }
        }
    }

    private func configure() {
        guard let button = statusItem.button else { return }

        button.title = ""
        button.image = NSImage(systemSymbolName: "doc.text", accessibilityDescription: "MarkyMarkdown - Your friendly markdown converter! 🎉")
        button.imagePosition = .imageOnly

        let menu = NSMenu()
        let versionItem = NSMenuItem(title: "MarkyMarkdown v\(Bundle.main.appVersion)", action: nil, keyEquivalent: "")
        versionItem.isEnabled = false
        menu.addItem(versionItem)
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Open Drop Window", action: #selector(handleOpenWindow), keyEquivalent: "o"))
        menu.addItem(NSMenuItem(title: "Convert File…", action: #selector(handleConvertPicker), keyEquivalent: "c"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Check for Updates…", action: #selector(handleCheckForUpdates), keyEquivalent: "u"))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Preferences…", action: #selector(handlePreferences), keyEquivalent: ","))
        menu.addItem(NSMenuItem.separator())
        menu.addItem(NSMenuItem(title: "Quit", action: #selector(handleQuit), keyEquivalent: "q"))

        menu.items.forEach { $0.target = self }

        self.menu = menu
        statusItem.menu = menu

        let dropView = StatusBarDropView(frame: button.bounds)
        dropView.autoresizingMask = [.width, .height]
        dropView.onFilesDropped = { [weak self] urls in
            self?.conversionManager.convert(urls: urls)
        }
        button.addSubview(dropView)
        self.dropView = dropView
    }

    @objc
    private func handleCheckForUpdates() {
        checkForUpdates()
    }

    @objc
    private func handleOpenWindow() {
        openMainWindow()
    }

    @objc
    private func handlePreferences() {
        openPreferences()
    }

    @objc
    private func handleConvertPicker() {
        convertViaPicker()
    }

    @objc
    private func handleQuit() {
        NSApp.terminate(nil)
    }
}

final class StatusBarDropView: NSView {
    var onFilesDropped: (([URL]) -> Void)?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        registerForDraggedTypes([.fileURL])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        let pasteboard = sender.draggingPasteboard
        let classes: [AnyClass] = [NSURL.self]
        if let urls = pasteboard.readObjects(forClasses: classes, options: nil) as? [URL], !urls.isEmpty {
            return .copy
        }
        return []
    }

    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteboard = sender.draggingPasteboard
        let classes: [AnyClass] = [NSURL.self]

        guard let urls = pasteboard.readObjects(forClasses: classes, options: nil) as? [URL], !urls.isEmpty else {
            return false
        }

        onFilesDropped?(urls)
        return true
    }
}
