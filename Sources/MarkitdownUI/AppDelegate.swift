import AppKit
import Combine

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var settings: AppSettingsStore!
    private var conversionManager: ConversionManager!
    private var updaterService: UpdaterService!

    private var dropWindowController: DropWindowController!
    private var preferencesWindowController: PreferencesWindowController!
    private var statusBarController: StatusBarController!

    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        settings = AppSettingsStore()
        conversionManager = ConversionManager(settings: settings)
        updaterService = UpdaterService()

        dropWindowController = DropWindowController(conversionManager: conversionManager)
        preferencesWindowController = PreferencesWindowController(settings: settings)

        statusBarController = StatusBarController(
            conversionManager: conversionManager,
            openMainWindow: { [weak self] in
                self?.dropWindowController.show()
            },
            openPreferences: { [weak self] in
                self?.preferencesWindowController.show()
            },
            convertViaPicker: { [weak self] in
                self?.openFilePickerAndConvert()
            },
            checkForUpdates: { [weak self] in
                self?.updaterService.checkForUpdates()
            }
        )

        conversionManager.$state
            .sink { [weak self] state in
                self?.statusBarController.updateForState(state)
            }
            .store(in: &cancellables)

        dropWindowController.show()
    }

    private func openFilePickerAndConvert() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.canChooseFiles = true
        panel.prompt = "Convert"

        if panel.runModal() == .OK, let url = panel.url {
            conversionManager.convert(url: url)
        }
    }
}
