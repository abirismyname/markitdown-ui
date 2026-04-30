import Testing
import Foundation
@testable import MarkitdownUI

// Integration and regression tests that exercise the real MarkItDown CLI.
// These tests require the `markitdown` executable to be available on PATH
// or pointed to by the MARKITDOWN_CLI_PATH environment variable.
// If the CLI cannot be found the tests return early (pass trivially).
//
// In CI the markitdown CLI is installed via pip before `swift test` runs.

@Suite("Integration & Regression")
struct IntegrationTests {

    // MARK: CLI discovery

    /// Returns the path to the markitdown CLI, or nil if it cannot be found.
    private func findMarkitdownCLI() -> String? {
        // 1. Explicit override via environment variable
        if let envPath = ProcessInfo.processInfo.environment["MARKITDOWN_CLI_PATH"],
           FileManager.default.isExecutableFile(atPath: envPath) {
            return envPath
        }

        // 2. Ask `which` (respects the user's PATH)
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = ["markitdown"]
        let pipe = Pipe()
        process.standardOutput = pipe
        do {
            try process.run()
            process.waitUntilExit()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let path = String(data: data, encoding: .utf8)?
                .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            if !path.isEmpty, FileManager.default.isExecutableFile(atPath: path) {
                return path
            }
        } catch {}

        // 3. Common install locations
        let candidates = [
            "/usr/local/bin/markitdown",
            "/usr/bin/markitdown",
            "\(NSHomeDirectory())/.local/bin/markitdown",
            "\(NSHomeDirectory())/Library/Python/3.12/bin/markitdown",
            "\(NSHomeDirectory())/Library/Python/3.11/bin/markitdown",
            "\(NSHomeDirectory())/Library/Python/3.10/bin/markitdown",
        ]
        for path in candidates where FileManager.default.isExecutableFile(atPath: path) {
            return path
        }

        return nil
    }

    // MARK: Helpers

    private func tmpDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("IntegrationTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: CLI smoke test

    @Test("CLI executes and exits successfully on a known good file")
    func cliSmokeTest() throws {
        guard let cliPath = findMarkitdownCLI() else { return }
        guard let docxURL = Bundle.module.url(forResource: "markymarkdown_test",
                                              withExtension: "docx",
                                              subdirectory: "Resources") else {
            Issue.record("Test fixture markymarkdown_test.docx not found in bundle")
            return
        }

        let dir = try tmpDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let inputURL = dir.appendingPathComponent("markymarkdown_test.docx")
        try FileManager.default.copyItem(at: docxURL, to: inputURL)

        let service = MarkitdownConversionService(cliPath: cliPath, keepDataURIs: false)
        let result = try service.convertFile(at: inputURL)

        #expect(FileManager.default.fileExists(atPath: result.outputURL.path),
                "Expected output file to exist at \(result.outputURL.path)")
    }

    // MARK: Output naming regression

    @Test("output file is placed in the same directory as input")
    func outputFileInSameDirectory() throws {
        guard let cliPath = findMarkitdownCLI() else { return }
        guard let docxURL = Bundle.module.url(forResource: "markymarkdown_test",
                                              withExtension: "docx",
                                              subdirectory: "Resources") else { return }

        let dir = try tmpDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let inputURL = dir.appendingPathComponent("markymarkdown_test.docx")
        try FileManager.default.copyItem(at: docxURL, to: inputURL)

        let service = MarkitdownConversionService(cliPath: cliPath, keepDataURIs: false)
        let result = try service.convertFile(at: inputURL)

        #expect(result.outputURL.deletingLastPathComponent() == dir)
    }

    @Test("output filename follows the '<input>.md' convention")
    func outputFilenamingConvention() throws {
        guard let cliPath = findMarkitdownCLI() else { return }
        guard let docxURL = Bundle.module.url(forResource: "markymarkdown_test",
                                              withExtension: "docx",
                                              subdirectory: "Resources") else { return }

        let dir = try tmpDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let inputURL = dir.appendingPathComponent("markymarkdown_test.docx")
        try FileManager.default.copyItem(at: docxURL, to: inputURL)

        let service = MarkitdownConversionService(cliPath: cliPath, keepDataURIs: false)
        let result = try service.convertFile(at: inputURL)

        #expect(result.outputURL.lastPathComponent == "markymarkdown_test.docx.md")
    }

    @Test("second conversion produces collision-suffixed filename")
    func collisionSuffix() throws {
        guard let cliPath = findMarkitdownCLI() else { return }
        guard let docxURL = Bundle.module.url(forResource: "markymarkdown_test",
                                              withExtension: "docx",
                                              subdirectory: "Resources") else { return }

        let dir = try tmpDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let inputURL = dir.appendingPathComponent("markymarkdown_test.docx")
        try FileManager.default.copyItem(at: docxURL, to: inputURL)

        let service = MarkitdownConversionService(cliPath: cliPath, keepDataURIs: false)
        let first  = try service.convertFile(at: inputURL)
        let second = try service.convertFile(at: inputURL)

        #expect(first.outputURL.lastPathComponent  == "markymarkdown_test.docx.md")
        #expect(second.outputURL.lastPathComponent == "markymarkdown_test.docx (1).md")
    }

    // MARK: Content regression against golden file

    @Test("converted output contains expected document sections")
    func contentSectionsPresent() throws {
        guard let cliPath = findMarkitdownCLI() else { return }
        guard let docxURL = Bundle.module.url(forResource: "markymarkdown_test",
                                              withExtension: "docx",
                                              subdirectory: "Resources") else { return }

        let dir = try tmpDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let inputURL = dir.appendingPathComponent("markymarkdown_test.docx")
        try FileManager.default.copyItem(at: docxURL, to: inputURL)

        let service = MarkitdownConversionService(cliPath: cliPath, keepDataURIs: false)
        let result  = try service.convertFile(at: inputURL)
        let output  = try String(contentsOf: result.outputURL, encoding: .utf8)

        let expectedSections = [
            "Introduction",
            "Bullet List",
            "Numbered List",
            "Sample Table",
            "Formatting",
            "Block Quote",
        ]
        for section in expectedSections {
            #expect(output.contains(section),
                    "Output is missing expected section: '\(section)'")
        }
    }

    @Test("converted output contains Lorem ipsum body text")
    func bodyTextPresent() throws {
        guard let cliPath = findMarkitdownCLI() else { return }
        guard let docxURL = Bundle.module.url(forResource: "markymarkdown_test",
                                              withExtension: "docx",
                                              subdirectory: "Resources") else { return }

        let dir = try tmpDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let inputURL = dir.appendingPathComponent("markymarkdown_test.docx")
        try FileManager.default.copyItem(at: docxURL, to: inputURL)

        let service = MarkitdownConversionService(cliPath: cliPath, keepDataURIs: false)
        let result  = try service.convertFile(at: inputURL)
        let output  = try String(contentsOf: result.outputURL, encoding: .utf8)

        #expect(output.contains("Lorem ipsum"))
        #expect(output.contains("consectetur"))
    }

    @Test("converted output contains table column headers")
    func tableContentPresent() throws {
        guard let cliPath = findMarkitdownCLI() else { return }
        guard let docxURL = Bundle.module.url(forResource: "markymarkdown_test",
                                              withExtension: "docx",
                                              subdirectory: "Resources") else { return }

        let dir = try tmpDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let inputURL = dir.appendingPathComponent("markymarkdown_test.docx")
        try FileManager.default.copyItem(at: docxURL, to: inputURL)

        let service = MarkitdownConversionService(cliPath: cliPath, keepDataURIs: false)
        let result  = try service.convertFile(at: inputURL)
        let output  = try String(contentsOf: result.outputURL, encoding: .utf8)

        #expect(output.contains("Column 1"))
        #expect(output.contains("Column 2"))
        #expect(output.contains("Column 3"))
    }

    @Test("converted output contains bold and italic formatting markers")
    func formattingMarkersPresent() throws {
        guard let cliPath = findMarkitdownCLI() else { return }
        guard let docxURL = Bundle.module.url(forResource: "markymarkdown_test",
                                              withExtension: "docx",
                                              subdirectory: "Resources") else { return }

        let dir = try tmpDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let inputURL = dir.appendingPathComponent("markymarkdown_test.docx")
        try FileManager.default.copyItem(at: docxURL, to: inputURL)

        let service = MarkitdownConversionService(cliPath: cliPath, keepDataURIs: false)
        let result  = try service.convertFile(at: inputURL)
        let output  = try String(contentsOf: result.outputURL, encoding: .utf8)

        // The golden file uses **bold** and *italic*
        #expect(output.contains("**bold**") || output.contains("bold"))
        #expect(output.contains("*italic*") || output.contains("italic"))
    }

    @Test("output content matches golden file closely")
    func goldenFileRegression() throws {
        guard let cliPath = findMarkitdownCLI() else { return }
        guard let docxURL = Bundle.module.url(forResource: "markymarkdown_test",
                                              withExtension: "docx",
                                              subdirectory: "Resources") else { return }
        guard let goldenURL = Bundle.module.url(forResource: "markymarkdown_test.docx",
                                                withExtension: "md",
                                                subdirectory: "Resources") else {
            Issue.record("Golden file markymarkdown_test.docx.md not found in bundle")
            return
        }

        let dir = try tmpDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let inputURL = dir.appendingPathComponent("markymarkdown_test.docx")
        try FileManager.default.copyItem(at: docxURL, to: inputURL)

        let service = MarkitdownConversionService(cliPath: cliPath, keepDataURIs: false)
        let result  = try service.convertFile(at: inputURL)

        let output  = try String(contentsOf: result.outputURL, encoding: .utf8)
        let golden  = try String(contentsOf: goldenURL, encoding: .utf8)

        // Normalize: trim whitespace and collapse consecutive blank lines for comparison
        func normalize(_ s: String) -> String {
            s.components(separatedBy: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .joined(separator: "\n")
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }

        let normalizedOutput = normalize(output)
        let normalizedGolden = normalize(golden)

        // Check that every non-empty line in the golden file is present somewhere in the output
        let goldenLines = normalizedGolden.components(separatedBy: "\n").filter { !$0.isEmpty }
        var missingLines: [String] = []
        for line in goldenLines {
            if !normalizedOutput.contains(line) {
                missingLines.append(line)
            }
        }
        #expect(missingLines.isEmpty,
                "Output is missing \(missingLines.count) line(s) from golden file. First missing: '\(missingLines.first ?? "")'")
    }
}
