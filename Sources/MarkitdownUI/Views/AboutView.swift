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
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("About MarkyMarkdown")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                Text("v\(Bundle.main.appVersion)")
                    .font(.system(size: 13, weight: .regular, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

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

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Acknowledgements")
                    .font(.headline)
                Text("MarkItDown © Microsoft Corporation — MIT License")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Link("Full license notice (ACKNOWLEDGEMENTS.md)",
                     destination: URL(string: "https://github.com/abirismyname/markymarkdown/blob/main/ACKNOWLEDGEMENTS.md")!)
                    .font(.caption)
            }

            Spacer()
        }
        .padding(20)
        .frame(width: 560, height: 480)
    }
}
