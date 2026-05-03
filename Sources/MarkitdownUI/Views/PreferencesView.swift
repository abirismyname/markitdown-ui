import SwiftUI
import UniformTypeIdentifiers

struct PreferencesView: View {
    let settings: AppSettingsStore
    let onDismiss: () -> Void

    @State private var draftCliPath: String
    @State private var draftKeepDataURIs: Bool
    @State private var draftColorScheme: ColorSchemePreference
    @State private var isPickerPresented = false

    private var isBundled: Bool {
        AppSettingsStore.bundledMarkitdownPath() != nil
    }

    init(settings: AppSettingsStore, onDismiss: @escaping () -> Void) {
        self.settings = settings
        self.onDismiss = onDismiss
        _draftCliPath = State(initialValue: settings.cliPath)
        _draftKeepDataURIs = State(initialValue: settings.keepDataURIs)
        _draftColorScheme = State(initialValue: settings.colorScheme)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preferences")
                .font(.system(size: 22, weight: .semibold, design: .rounded))

            VStack(alignment: .leading, spacing: 8) {
                Text("MarkItDown CLI Path")
                    .font(.headline)

                HStack {
                    Text(draftCliPath)
                        .truncationMode(.middle)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .background(Color(NSColor.controlBackgroundColor))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color(NSColor.separatorColor), lineWidth: 1)
                        )

                    Button("Browse…") {
                        isPickerPresented = true
                    }
                }
                .fileImporter(
                    isPresented: $isPickerPresented,
                    allowedContentTypes: [.unixExecutable, .shellScript],
                    allowsMultipleSelection: false
                ) { result in
                    if case .success(let urls) = result, let url = urls.first {
                        draftCliPath = url.path
                    }
                }

                if isBundled {
                    Text("Using bundled MarkItDown (included with app)")
                        .font(.caption)
                        .foregroundStyle(.green)
                } else {
                    Text("Default: /Users/abirmajumdar/.local/bin/markitdown")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Toggle("Embed assets as data URLs (self-contained output)", isOn: $draftKeepDataURIs)
                Text("When enabled, images/assets remain embedded as data: URLs so the output works offline and in a single file. This can significantly increase output size and may be blocked by some security policies.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Text("Color Scheme")
                    .font(.headline)
                Spacer()
                Picker("", selection: $draftColorScheme) {
                    ForEach(ColorSchemePreference.allCases, id: \.self) { scheme in
                        Text(scheme.displayName).tag(scheme)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            if let error = draftValidationError() {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            } else {
                Text("CLI path is valid")
                    .foregroundStyle(.green)
                    .font(.caption)
            }

            Spacer()

            HStack {
                Spacer()
                Button("Cancel") {
                    onDismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Apply") {
                    applyChanges()
                    onDismiss()
                }
                .keyboardShortcut(.defaultAction)
                .disabled(draftValidationError() != nil)
            }
        }
        .padding(20)
        .frame(width: 520, height: 360)
    }

    private func draftValidationError() -> String? {
        if draftCliPath.isEmpty {
            return "MarkItDown CLI path cannot be empty."
        }
        var isDirectory: ObjCBool = false
        guard FileManager.default.fileExists(atPath: draftCliPath, isDirectory: &isDirectory),
              !isDirectory.boolValue else {
            return "MarkItDown CLI path does not point to a file."
        }
        guard FileManager.default.isExecutableFile(atPath: draftCliPath) else {
            return "MarkItDown CLI is not executable."
        }
        return nil
    }

    private func applyChanges() {
        settings.cliPath = draftCliPath
        settings.keepDataURIs = draftKeepDataURIs
        settings.colorScheme = draftColorScheme
    }
}
