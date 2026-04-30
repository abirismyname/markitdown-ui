import Testing
import Foundation
@testable import MarkitdownUI

@Suite("ConversionError")
struct ConversionErrorTests {

    @Test("invalidInput error description is non-empty")
    func invalidInputDescription() {
        let error = ConversionError.invalidInput
        let desc = error.errorDescription
        #expect(desc != nil)
        #expect(!(desc ?? "").isEmpty)
    }

    @Test("invalidInput description mentions valid/local file")
    func invalidInputDescriptionText() {
        let error = ConversionError.invalidInput
        let desc = (error.errorDescription ?? "").lowercased()
        #expect(desc.contains("valid") || desc.contains("file"))
    }

    @Test("processFailed carries exit code in description")
    func processFailedExitCode() {
        let error = ConversionError.processFailed(code: 42, stderr: "")
        let desc = error.errorDescription ?? ""
        #expect(desc.contains("42"))
    }

    @Test("processFailed with stderr includes stderr in description")
    func processFailedWithStderr() {
        let stderrMsg = "cannot open file"
        let error = ConversionError.processFailed(code: 1, stderr: stderrMsg)
        let desc = error.errorDescription ?? ""
        #expect(desc.contains(stderrMsg))
    }

    @Test("processFailed with empty stderr does not include separator artifacts")
    func processFailedEmptyStderrNoColon() {
        let error = ConversionError.processFailed(code: 1, stderr: "")
        let desc = error.errorDescription ?? ""
        // Should still contain the exit code
        #expect(desc.contains("1"))
        // Should not end with a hanging colon + space
        #expect(!desc.hasSuffix(": "))
    }

    @Test("processFailed with non-zero code and stderr produces combined message")
    func processFailedCombinedMessage() {
        let error = ConversionError.processFailed(code: 2, stderr: "bad format")
        let desc = error.errorDescription ?? ""
        #expect(desc.contains("2"))
        #expect(desc.contains("bad format"))
    }

    @Test("ConversionError conforms to LocalizedError")
    func localizedErrorConformance() {
        let error: LocalizedError = ConversionError.invalidInput
        #expect(error.errorDescription != nil)
    }
}
