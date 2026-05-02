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

            Divider()

            VStack(alignment: .leading, spacing: 4) {
                Text("Acknowledgements")
                    .font(.headline)
                Text("MarkItDown is © Microsoft Corporation, used under the MIT License.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons and to whom the Software is furnished to do so, subject to the following conditions: The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer()
        }
        .padding(20)
        .frame(width: 560, height: 540)
    }
}
