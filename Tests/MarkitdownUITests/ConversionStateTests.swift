import Testing
import Foundation
@testable import MarkitdownUI

@Suite("ConversionState")
struct ConversionStateTests {

    @Test("idle equals idle")
    func idleEquality() {
        #expect(ConversionState.idle == ConversionState.idle)
    }

    @Test("converting equals converting with same fileName")
    func convertingEqualitySameFileName() {
        let a = ConversionState.converting(fileName: "test.pdf")
        let b = ConversionState.converting(fileName: "test.pdf")
        #expect(a == b)
    }

    @Test("converting not equal when fileNames differ")
    func convertingInequalityDifferentFileNames() {
        let a = ConversionState.converting(fileName: "a.pdf")
        let b = ConversionState.converting(fileName: "b.pdf")
        #expect(a != b)
    }

    @Test("success equals success with same URL")
    func successEqualitySameURL() {
        let url = URL(fileURLWithPath: "/tmp/out.md")
        let a = ConversionState.success(outputURL: url)
        let b = ConversionState.success(outputURL: url)
        #expect(a == b)
    }

    @Test("success not equal when URLs differ")
    func successInequalityDifferentURLs() {
        let a = ConversionState.success(outputURL: URL(fileURLWithPath: "/tmp/a.md"))
        let b = ConversionState.success(outputURL: URL(fileURLWithPath: "/tmp/b.md"))
        #expect(a != b)
    }

    @Test("failure equals failure with same message")
    func failureEqualitySameMessage() {
        let a = ConversionState.failure(message: "oops")
        let b = ConversionState.failure(message: "oops")
        #expect(a == b)
    }

    @Test("failure not equal when messages differ")
    func failureInequalityDifferentMessages() {
        let a = ConversionState.failure(message: "oops")
        let b = ConversionState.failure(message: "different")
        #expect(a != b)
    }

    @Test("different cases are not equal")
    func differentCasesNotEqual() {
        #expect(ConversionState.idle != ConversionState.converting(fileName: "x"))
        #expect(ConversionState.idle != ConversionState.success(outputURL: URL(fileURLWithPath: "/tmp/x.md")))
        #expect(ConversionState.idle != ConversionState.failure(message: "e"))
        #expect(ConversionState.converting(fileName: "x") != ConversionState.success(outputURL: URL(fileURLWithPath: "/tmp/x.md")))
        #expect(ConversionState.converting(fileName: "x") != ConversionState.failure(message: "e"))
        #expect(ConversionState.success(outputURL: URL(fileURLWithPath: "/tmp/x.md")) != ConversionState.failure(message: "e"))
    }

    @Test("success case carries correct outputURL")
    func successOutputURL() {
        let url = URL(fileURLWithPath: "/tmp/report.md")
        if case let .success(outputURL) = ConversionState.success(outputURL: url) {
            #expect(outputURL == url)
        } else {
            Issue.record("Expected success case")
        }
    }

    @Test("failure case carries correct message")
    func failureMessage() {
        let msg = "Something went wrong"
        if case let .failure(message) = ConversionState.failure(message: msg) {
            #expect(message == msg)
        } else {
            Issue.record("Expected failure case")
        }
    }

    @Test("converting case carries correct fileName")
    func convertingFileName() {
        let name = "document.pdf"
        if case let .converting(fileName) = ConversionState.converting(fileName: name) {
            #expect(fileName == name)
        } else {
            Issue.record("Expected converting case")
        }
    }
}
