import Testing
import Foundation
@testable import MarkitdownUI

@Suite("Output URL Naming")
struct OutputNamingTests {

    // MARK: Helpers

    private func tmpDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("OutputNamingTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func service() -> MarkitdownConversionService {
        MarkitdownConversionService(cliPath: "/usr/bin/false", keepDataURIs: false)
    }

    // MARK: Basic naming

    @Test("output URL appends .md to the full filename")
    func basicNaming() throws {
        let dir = try tmpDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let input = dir.appendingPathComponent("document.pdf")
        let output = service().makeUniqueOutputURL(for: input)
        #expect(output.lastPathComponent == "document.pdf.md")
    }

    @Test("output URL is placed in the same directory as input")
    func sameDirectory() throws {
        let dir = try tmpDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let input = dir.appendingPathComponent("notes.docx")
        let output = service().makeUniqueOutputURL(for: input)
        #expect(output.deletingLastPathComponent() == dir)
    }

    @Test("output URL for file without extension appends .md")
    func fileWithoutExtension() throws {
        let dir = try tmpDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let input = dir.appendingPathComponent("README")
        let output = service().makeUniqueOutputURL(for: input)
        #expect(output.lastPathComponent == "README.md")
    }

    // MARK: Collision handling

    @Test("first collision appends ' (1)' before .md")
    func firstCollision() throws {
        let dir = try tmpDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let input = dir.appendingPathComponent("report.pdf")
        // Create the primary output so it collides
        let primary = dir.appendingPathComponent("report.pdf.md")
        FileManager.default.createFile(atPath: primary.path, contents: nil)

        let output = service().makeUniqueOutputURL(for: input)
        #expect(output.lastPathComponent == "report.pdf (1).md")
    }

    @Test("second collision appends ' (2)' before .md")
    func secondCollision() throws {
        let dir = try tmpDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let input = dir.appendingPathComponent("data.xlsx")
        FileManager.default.createFile(atPath: dir.appendingPathComponent("data.xlsx.md").path, contents: nil)
        FileManager.default.createFile(atPath: dir.appendingPathComponent("data.xlsx (1).md").path, contents: nil)

        let output = service().makeUniqueOutputURL(for: input)
        #expect(output.lastPathComponent == "data.xlsx (2).md")
    }

    @Test("collision suffix increments monotonically to (3)")
    func thirdCollision() throws {
        let dir = try tmpDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let input = dir.appendingPathComponent("slide.pptx")
        for suffix in ["", " (1)", " (2)"] {
            let name = "slide.pptx\(suffix).md"
            FileManager.default.createFile(atPath: dir.appendingPathComponent(name).path, contents: nil)
        }

        let output = service().makeUniqueOutputURL(for: input)
        #expect(output.lastPathComponent == "slide.pptx (3).md")
    }

    @Test("no collision when output directory is empty")
    func noCollisionInEmptyDir() throws {
        let dir = try tmpDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let input = dir.appendingPathComponent("clean.txt")
        let output = service().makeUniqueOutputURL(for: input)
        #expect(output.lastPathComponent == "clean.txt.md")
        // Should not have a suffix parenthetical
        #expect(!output.lastPathComponent.contains("("))
    }

    @Test("output path extension is always .md")
    func outputExtensionIsAlwaysMD() throws {
        let dir = try tmpDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let inputs = ["a.pdf", "b.docx", "c.pptx", "d.xlsx", "e"]
        for name in inputs {
            let input = dir.appendingPathComponent(name)
            let output = service().makeUniqueOutputURL(for: input)
            #expect(output.pathExtension == "md", "Expected .md for input '\(name)', got '\(output.lastPathComponent)'")
        }
    }

    @Test("invalidInput error thrown for non-file URL")
    func invalidInputForNonFileURL() throws {
        let httpURL = try #require(URL(string: "https://example.com/file.pdf"))
        let svc = MarkitdownConversionService(cliPath: "/usr/bin/false", keepDataURIs: false)
        #expect(throws: ConversionError.invalidInput) {
            try svc.convertFile(at: httpURL)
        }
    }
}
