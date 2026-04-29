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

            Toggle("Keep data URIs in output", isOn: $settings.keepDataURIs)

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
        .frame(width: 520, height: 260)
    }
}
