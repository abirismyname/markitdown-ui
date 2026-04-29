import SwiftUI
import UniformTypeIdentifiers

struct DropZoneView: View {
    @ObservedObject var conversionManager: ConversionManager

    @State private var isTargeted = false

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color(red: 0.08, green: 0.11, blue: 0.16), Color(red: 0.12, green: 0.16, blue: 0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("MarkyMarkdown")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)

                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: isTargeted ? 3 : 1.5, dash: [8])
                    )
                    .foregroundStyle(isTargeted ? Color.cyan : Color.white.opacity(0.5))
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color.white.opacity(isTargeted ? 0.14 : 0.08))
                    )
                    .frame(width: 420, height: 220)
                    .overlay {
                        VStack(spacing: 10) {
                            Image(systemName: "square.and.arrow.down.on.square")
                                .font(.system(size: 34, weight: .regular))
                                .foregroundStyle(.white)

                            Text("Drop a file to convert")
                                .foregroundStyle(.white)
                                .font(.system(size: 18, weight: .medium))

                            Text("Markdown will be created in the same folder")
                                .foregroundStyle(Color.white.opacity(0.8))
                                .font(.system(size: 13))
                        }
                    }
                    .onDrop(of: [UTType.fileURL], isTargeted: $isTargeted) { providers in
                        loadFirstURL(from: providers)
                    }

                statusView
            }
            .padding(.vertical, 28)
            .padding(.horizontal, 24)
        }
        .frame(minWidth: 560, minHeight: 420)
        .animation(.easeInOut(duration: 0.2), value: isTargeted)
        .animation(.easeInOut(duration: 0.2), value: conversionManager.state)
    }

    @ViewBuilder
    private var statusView: some View {
        switch conversionManager.state {
        case .idle:
            Text("Ready")
                .foregroundStyle(Color.white.opacity(0.7))
                .font(.system(size: 13))
        case let .converting(fileName):
            HStack(spacing: 8) {
                ProgressView()
                    .progressViewStyle(.circular)
                Text("Converting \(fileName)…")
            }
            .foregroundStyle(.white)
            .font(.system(size: 13, weight: .medium))
        case let .success(outputURL):
            HStack(spacing: 12) {
                Text("Saved: \(outputURL.lastPathComponent)")
                    .foregroundStyle(.green)
                    .font(.system(size: 13, weight: .semibold))

                Button("Reveal") {
                    conversionManager.revealOutputInFinder()
                }
                .buttonStyle(.borderedProminent)
                .tint(.green)
            }
        case let .failure(message):
            Text(message)
                .foregroundStyle(.red.opacity(0.92))
                .font(.system(size: 12, weight: .medium))
                .multilineTextAlignment(.center)
                .frame(maxWidth: 460)
        }
    }

    private func loadFirstURL(from providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first(where: { $0.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) }) else {
            return false
        }

        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let rawURL = URL(dataRepresentation: data, relativeTo: nil) else {
                return
            }

            DispatchQueue.main.async {
                conversionManager.convert(url: rawURL)
            }
        }

        return true
    }
}
