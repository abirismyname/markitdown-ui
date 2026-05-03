import SwiftUI

struct PreferencesView: View {
    @ObservedObject var settings: AppSettingsStore

    private var isBundled: Bool {
        AppSettingsStore.bundledMarkitdownPath() != nil
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Preferences")
                .font(.system(size: 22, weight: .semibold, design: .rounded))

            VStack(alignment: .leading, spacing: 8) {
                Text("MarkItDown CLI Path")
                    .font(.headline)

                TextField("/path/to/markitdown", text: $settings.cliPath)
                    .textFieldStyle(.roundedBorder)

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
                Toggle("Embed assets as data URLs (self-contained output)", isOn: $settings.keepDataURIs)
                Text("When enabled, images/assets remain embedded as data: URLs so the output works offline and in a single file. This can significantly increase output size and may be blocked by some security policies.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            HStack {
                Text("Color Scheme")
                    .font(.headline)
                Spacer()
                Picker("", selection: $settings.colorScheme) {
                    ForEach(ColorSchemePreference.allCases, id: \.self) { scheme in
                        Text(scheme.displayName).tag(scheme)
                    }
                }
                .pickerStyle(.segmented)
                .frame(width: 200)
            }

            if let error = settings.validationError() {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            } else {
                Text("CLI path is valid")
                    .foregroundStyle(.green)
                    .font(.caption)
            }

            Spacer()
        }
        .padding(20)
        .frame(width: 520, height: 300)
    }
}
