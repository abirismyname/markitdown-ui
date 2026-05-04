import SwiftUI
import UniformTypeIdentifiers
import ConfettiSwiftUI

private let celebrationMessages = [
    "✨ Magic complete! ✨",
    "🎉 Markdown perfection! 🎉",
    "🚀 Converted to the moon! 🚀",
    "⭐ Stellar conversion! ⭐",
    "🎊 File transformation success! 🎊",
    "💫 Converted with sparkles! 💫",
    "🌟 Absolutely brilliant! 🌟",
    "👏 Perfectly executed! 👏",
    "🎯 Bullseye! 🎯",
    "🧙 Markdown wizardry! 🧙",
    "🎨 Beautifully converted! 🎨",
    "🌈 Rainbow markdown! 🌈",
    "💎 Gem-quality! 💎",
    "🏆 Champion conversion! 🏆",
]

func playfulErrorMessage(_ original: String) -> String {
    let lower = original.lowercased()
    if lower.contains("unsupported file type") {
        return "That file type isn't supported yet. Try PDF, DOCX, PPTX, XLSX, HTML, or plain text! 📄"
    } else if lower.contains("path") {
        return "CLI path got lost—check Preferences! 🔍"
    } else if lower.contains("executable") {
        return "CLI needs permission to run. Check Preferences! 🔐"
    } else if lower.contains("not a valid") {
        return "Hmm, that doesn't look like a local file. Try again! 📁"
    }
    return "Something went sideways. Try again? 😊"
}

struct DropZoneView: View {
    @ObservedObject var conversionManager: ConversionManager

    @Environment(\.colorScheme) private var colorScheme

    @State private var isTargeted = false
    @State private var isUnsupportedHover = false
    @State private var celebrationMessage = ""
    @State private var confettiTrigger: Int = 0
    @State private var spinAngle: Double = 0
    @State private var showErrorDetails = false

    private let spinAnimationDuration: Double = 2.0

    private var backgroundGradient: LinearGradient {
        if colorScheme == .dark {
            return LinearGradient(
                colors: [Color(red: 0.08, green: 0.11, blue: 0.16), Color(red: 0.12, green: 0.16, blue: 0.22)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        } else {
            return LinearGradient(
                colors: [Color(red: 0.94, green: 0.96, blue: 0.99), Color(red: 0.88, green: 0.92, blue: 0.97)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var body: some View {
        ZStack {
            backgroundGradient
            .ignoresSafeArea()

            VStack(spacing: 20) {
                Text("MarkyMarkdown")
                    .font(.system(size: 28, weight: .semibold, design: .rounded))
                    .foregroundStyle(.primary)

                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        style: StrokeStyle(lineWidth: (isTargeted || isUnsupportedHover) ? 3 : 1.5, dash: [8])
                    )
                    .foregroundStyle(dropZoneBorderColor)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(dropZoneFillColor)
                    )
                    .frame(width: 420, height: 220)
                    .overlay {
                        ZStack {
                            if isUnsupportedHover {
                                VStack(spacing: 10) {
                                    Image(systemName: "xmark.circle")
                                        .font(.system(size: 34, weight: .regular))
                                        .foregroundStyle(.red)

                                    Text("Unsupported file type")
                                        .foregroundStyle(.red)
                                        .font(.system(size: 18, weight: .medium))

                                    Text("Try PDF, DOCX, PPTX, XLSX, HTML, or plain text")
                                        .foregroundStyle(.red.opacity(0.8))
                                        .font(.system(size: 13))
                                }
                            } else {
                                VStack(spacing: 10) {
                                    Image(systemName: "square.and.arrow.down.on.square")
                                        .font(.system(size: 34, weight: .regular))
                                        .foregroundStyle(.primary)

                                    Text("Drop a file to convert")
                                        .foregroundStyle(.primary)
                                        .font(.system(size: 18, weight: .medium))

                                    Text("Markdown will be created in the same folder")
                                        .foregroundStyle(.secondary)
                                        .font(.system(size: 13))
                                }
                            }
                        }
                    }
                    .onDrop(of: [UTType.fileURL], delegate: DropZoneDelegate(
                        isTargeted: $isTargeted,
                        isUnsupportedHover: $isUnsupportedHover,
                        onDrop: { url in conversionManager.convert(url: url) }
                    ))

                statusView
            }
            .padding(.vertical, 28)
            .padding(.horizontal, 24)
        }
        .frame(minWidth: 560, minHeight: 420)
        .animation(.easeInOut(duration: 0.2), value: isTargeted)
        .animation(.easeInOut(duration: 0.2), value: isUnsupportedHover)
        .animation(.easeInOut(duration: 0.2), value: conversionManager.state)
        .animation(.easeInOut(duration: 0.4), value: conversionManager.milestoneCelebration != nil)
        // Confetti burst fired on every successful conversion
        .confettiCannon(
            counter: $confettiTrigger,
            confettis: [.text("✨"), .text("🎉"), .shape(.circle), .shape(.triangle)],
            colors: [.green, .cyan, .white, .yellow],
            openingAngle: .degrees(60),
            closingAngle: .degrees(120),
            radius: 300
        )
    }

    @ViewBuilder
    private var statusView: some View {
        switch conversionManager.state {
        case .idle:
            Text("Ready to work magic ✨")
                .foregroundStyle(.secondary)
                .font(.system(size: 13))
        case let .converting(fileName):
            let _ = { showErrorDetails = false }()
            HStack(spacing: 8) {
                ProgressView()
                    .progressViewStyle(.circular)
                Text("Converting \(fileName)…")
                Image(systemName: "sparkle")
                    .font(.system(size: 11))
                    .foregroundStyle(.cyan.opacity(0.9))
                    .rotationEffect(.degrees(spinAngle))
                    .onAppear {
                        spinAngle = 0
                        withAnimation(.linear(duration: spinAnimationDuration).repeatForever(autoreverses: false)) {
                            spinAngle = 360
                        }
                    }
            }
            .foregroundStyle(.primary)
            .font(.system(size: 13, weight: .medium))
        case let .success(outputURL):
            VStack(spacing: 8) {
                Text(celebrationMessage)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(.green)
                
                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("✓ Mission accomplished!")
                            .foregroundStyle(.green)
                            .font(.system(size: 12, weight: .semibold))
                        Text(outputURL.lastPathComponent)
                            .foregroundStyle(.green.opacity(0.8))
                            .font(.system(size: 11))
                            .lineLimit(1)
                    }
                    
                    Button("Reveal") {
                        conversionManager.revealOutputInFinder()
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                }
            }
            .onAppear {
                celebrationMessage = celebrationMessages.randomElement() ?? "🎉 Done! 🎉"
                confettiTrigger += 1
            }
        case let .failure(message):
            VStack(spacing: 6) {
                Text("Oops! 🤔")
                    .foregroundStyle(.red)
                    .font(.system(size: 13, weight: .bold))
                Text(playfulErrorMessage(message))
                    .foregroundStyle(.red.opacity(0.92))
                    .font(.system(size: 11, weight: .medium))
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: 460)
                Button(showErrorDetails ? "Hide Details" : "Show Details") {
                    showErrorDetails.toggle()
                }
                .font(.system(size: 11))
                .foregroundStyle(.red.opacity(0.7))
                .buttonStyle(.plain)
                if showErrorDetails {
                    ScrollView {
                        Text(message)
                            .font(.system(size: 11, design: .monospaced))
                            .foregroundStyle(.red.opacity(0.85))
                            .textSelection(.enabled)
                            .frame(maxWidth: 460, alignment: .leading)
                            .padding(8)
                    }
                    .frame(maxWidth: 460, maxHeight: 120)
                    .background(Color.black.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
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

    private var dropZoneBorderColor: Color {
        if isUnsupportedHover { return .red }
        return isTargeted ? Color.cyan : Color.primary.opacity(0.5)
    }

    private var dropZoneFillColor: Color {
        if isUnsupportedHover { return Color.red.opacity(0.08) }
        return Color.primary.opacity(isTargeted ? 0.14 : 0.08)
    }
}

struct DropZoneDelegate: DropDelegate {
    @Binding var isTargeted: Bool
    @Binding var isUnsupportedHover: Bool
    let onDrop: (URL) -> Void

    func validateDrop(info: DropInfo) -> Bool {
        // Allow any fileURL to enter so we can show the "unsupported" visual
        return info.hasItemsConforming(to: [UTType.fileURL])
    }

    func dropEntered(info: DropInfo) {
        guard let provider = info.itemProviders(for: [UTType.fileURL]).first else { return }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            let ext: String
            if let data = item as? Data, let url = URL(dataRepresentation: data, relativeTo: nil) {
                ext = url.pathExtension.lowercased()
            } else {
                ext = ""
            }
            DispatchQueue.main.async {
                let supported = MarkitdownConversionService.supportedExtensions.contains(ext)
                isTargeted = supported
                isUnsupportedHover = !supported
            }
        }
    }

    func dropExited(info: DropInfo) {
        isTargeted = false
        isUnsupportedHover = false
    }

    func performDrop(info: DropInfo) -> Bool {
        isTargeted = false
        isUnsupportedHover = false
        guard let provider = info.itemProviders(for: [UTType.fileURL]).first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            guard let data = item as? Data,
                  let url = URL(dataRepresentation: data, relativeTo: nil) else { return }
            DispatchQueue.main.async {
                onDrop(url)
            }
        }
        return true
    }
}
