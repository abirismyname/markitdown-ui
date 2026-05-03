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
    if lower.contains("path") {
        return "CLI path got lost—check Preferences! 🔍"
    } else if lower.contains("executable") {
        return "CLI needs permission to run. Check Preferences! 🔐"
    } else if lower.contains("not a valid") {
        return "Hmm, that file format might not be supported. Try another! 📁"
    }
    return "Something went sideways. Try again? 😊"
}

struct DropZoneView: View {
    @ObservedObject var conversionManager: ConversionManager

    @State private var isTargeted = false
    @State private var celebrationMessage = ""
    @State private var confettiTrigger: Int = 0
    @State private var spinAngle: Double = 0

    private let spinAnimationDuration: Double = 2.0

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
                        ZStack {
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
                .foregroundStyle(Color.white.opacity(0.7))
                .font(.system(size: 13))
        case let .converting(fileName):
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
            .foregroundStyle(.white)
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
}
