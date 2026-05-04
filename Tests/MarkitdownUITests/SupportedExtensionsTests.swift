import Testing
import Foundation
@testable import MarkitdownUI

@Suite("Supported File Extensions")
struct SupportedExtensionsTests {

    // MARK: Known supported types

    @Test("common document formats are supported")
    func documentFormats() {
        let supported = MarkitdownConversionService.supportedExtensions
        #expect(supported.contains("pdf"))
        #expect(supported.contains("docx"))
        #expect(supported.contains("pptx"))
        #expect(supported.contains("xlsx"))
    }

    @Test("common web formats are supported")
    func webFormats() {
        let supported = MarkitdownConversionService.supportedExtensions
        #expect(supported.contains("html"))
        #expect(supported.contains("htm"))
    }

    @Test("plain text formats are supported")
    func textFormats() {
        let supported = MarkitdownConversionService.supportedExtensions
        #expect(supported.contains("txt"))
        #expect(supported.contains("md"))
        #expect(supported.contains("csv"))
    }

    // MARK: Known unsupported types

    @Test("video formats are not supported")
    func videoFormatsUnsupported() {
        let supported = MarkitdownConversionService.supportedExtensions
        #expect(!supported.contains("mp4"))
        #expect(!supported.contains("mov"))
        #expect(!supported.contains("avi"))
    }

    @Test("executable files are not supported")
    func executableFilesUnsupported() {
        let supported = MarkitdownConversionService.supportedExtensions
        #expect(!supported.contains("exe"))
        #expect(!supported.contains("dmg"))
        #expect(!supported.contains("pkg"))
    }

    // MARK: Service-level validation (no CLI required)

    @Test("convertFile throws unsupportedFileType for .mp4 without needing the CLI")
    func unsupportedTypeThrowsBeforeCLI() {
        let service = MarkitdownConversionService(cliPath: "/nonexistent/markitdown", keepDataURIs: false)
        let fakeURL = URL(fileURLWithPath: "/tmp/video.mp4")
        #expect(throws: ConversionError.unsupportedFileType("mp4")) {
            try service.convertFile(at: fakeURL)
        }
    }

    @Test("convertFile throws unsupportedFileType for a file with no extension")
    func noExtensionThrowsBeforeCLI() {
        let service = MarkitdownConversionService(cliPath: "/nonexistent/markitdown", keepDataURIs: false)
        let fakeURL = URL(fileURLWithPath: "/tmp/noextension")
        #expect(throws: ConversionError.unsupportedFileType("unknown")) {
            try service.convertFile(at: fakeURL)
        }
    }

    @Test("unsupportedFileType extension check is case-insensitive")
    func caseInsensitiveExtension() {
        let service = MarkitdownConversionService(cliPath: "/nonexistent/markitdown", keepDataURIs: false)
        // .PDF (uppercase) should be treated the same as .pdf (supported)
        // — so it should NOT throw unsupportedFileType. It may throw processFailed (CLI missing)
        // but not unsupportedFileType.
        let fakeURL = URL(fileURLWithPath: "/tmp/document.PDF")
        #expect(throws: (any Error).self) { try service.convertFile(at: fakeURL) }
        do {
            _ = try service.convertFile(at: fakeURL)
        } catch ConversionError.unsupportedFileType {
            Issue.record("Uppercase .PDF should be treated as a supported extension")
        } catch {
            // Expected: processFailed or similar — not unsupportedFileType
        }
    }
}
