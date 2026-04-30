import Testing
import Foundation
@testable import MarkitdownUI

// playfulErrorMessage is a module-level function extracted from DropZoneView.
// These tests verify that each keyword branch returns the correct friendly copy.

@Suite("Playful Error Messages")
struct PlayfulErrorMessageTests {

    @Test("'path' keyword returns CLI path message")
    func pathKeyword() {
        let result = playfulErrorMessage("MarkItDown CLI path does not point to a file.")
        #expect(result.lowercased().contains("path") || result.lowercased().contains("preferences"))
    }

    @Test("'executable' keyword returns permission message")
    func executableKeyword() {
        let result = playfulErrorMessage("MarkItDown CLI is not executable.")
        #expect(result.lowercased().contains("permission") || result.lowercased().contains("executable"))
    }

    @Test("'not a valid' keyword returns format message")
    func notAValidKeyword() {
        let result = playfulErrorMessage("The dropped item is not a valid local file.")
        #expect(result.lowercased().contains("format") || result.lowercased().contains("supported") || result.lowercased().contains("file"))
    }

    @Test("unknown error returns fallback message")
    func unknownError() {
        let result = playfulErrorMessage("An unexpected error occurred.")
        #expect(!result.isEmpty)
        // Should not match the path/executable/format branches
        let lower = result.lowercased()
        #expect(!lower.contains("path") || lower.contains("sideways") || lower.contains("try again"))
    }

    @Test("empty string returns fallback message")
    func emptyStringFallback() {
        let result = playfulErrorMessage("")
        #expect(!result.isEmpty)
    }

    @Test("case insensitive matching for PATH")
    func caseInsensitivePath() {
        let result = playfulErrorMessage("Invalid PATH setting detected.")
        // 'path' is lowercase-matched so uppercase PATH also triggers it
        let lower = result.lowercased()
        #expect(lower.contains("path") || lower.contains("preferences"))
    }

    @Test("case insensitive matching for EXECUTABLE")
    func caseInsensitiveExecutable() {
        let result = playfulErrorMessage("The binary is not EXECUTABLE.")
        let lower = result.lowercased()
        #expect(lower.contains("permission") || lower.contains("executable"))
    }

    @Test("each distinct keyword returns a distinct message")
    func distinctMessagesForDistinctKeywords() {
        let pathMsg = playfulErrorMessage("bad path here")
        let execMsg = playfulErrorMessage("not executable")
        let validMsg = playfulErrorMessage("not a valid file")
        let fallback = playfulErrorMessage("unknown")
        // All four should be different strings
        let messages: Set<String> = [pathMsg, execMsg, validMsg, fallback]
        #expect(messages.count == 4)
    }
}
