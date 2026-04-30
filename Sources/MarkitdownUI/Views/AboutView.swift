import SwiftUI

struct AboutView: View {
    private let supportedFormats = [
        "PDF",
        "DOCX (Word)",
        "PPTX (PowerPoint)",
        "XLSX (Excel)",
        "HTML",
        "Images (JPG, PNG, GIF)",
        "URLs"
    ]

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("About MarkyMarkdown")
                .font(.system(size: 22, weight: .semibold, design: .rounded))

            Text("MarkyMarkdown uses the MarkItDown CLI to convert documents into clean Markdown output.")
                .font(.body)
                .foregroundStyle(.secondary)

            Link("MarkItDown Repository", destination: URL(string: "https://github.com/microsoft/markitdown")!)
                .font(.system(size: 14, weight: .semibold))

            Text("Supported file types")
                .font(.headline)

            Text(supportedFormats.joined(separator: "\n"))
                .font(.system(size: 13))
                .foregroundStyle(.primary)

            Text("MarkyMarkdown supports all formats available in the bundled MarkItDown CLI build.")
                .font(.footnote)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding(20)
        .frame(width: 560, height: 440)
    }
}
