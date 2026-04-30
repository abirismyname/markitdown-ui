import Testing
import Foundation
@testable import MarkitdownUI

@Suite("ConversionManager")
@MainActor
struct ConversionManagerTests {

    // MARK: Helpers

    private func makeManager() -> ConversionManager {
        let settings = AppSettingsStore()
        return ConversionManager(settings: settings)
    }

    // MARK: Initial state

    @Test("initial state is idle")
    func initialStateIsIdle() {
        let manager = makeManager()
        #expect(manager.state == .idle)
    }

    @Test("initial milestoneCelebration is nil")
    func initialMilestoneIsNil() {
        let manager = makeManager()
        #expect(manager.milestoneCelebration == nil)
    }

    // MARK: resetState

    @Test("resetState returns state to idle from failure")
    func resetStateFromFailure() {
        let manager = makeManager()
        manager.state = .failure(message: "some error")
        manager.resetState()
        #expect(manager.state == .idle)
    }

    @Test("resetState returns state to idle from success")
    func resetStateFromSuccess() {
        let manager = makeManager()
        manager.state = .success(outputURL: URL(fileURLWithPath: "/tmp/out.md"))
        manager.resetState()
        #expect(manager.state == .idle)
    }

    @Test("resetState returns state to idle from converting")
    func resetStateFromConverting() {
        let manager = makeManager()
        manager.state = .converting(fileName: "file.pdf")
        manager.resetState()
        #expect(manager.state == .idle)
    }

    // MARK: Validation guard

    @Test("convert sets failure state when CLI path is invalid")
    func convertWithInvalidCLIPath() {
        let settings = AppSettingsStore()
        settings.cliPath = "/nonexistent/markitdown"
        let manager = ConversionManager(settings: settings)

        manager.convert(url: URL(fileURLWithPath: "/tmp/test.pdf"))

        // validationError() is checked synchronously before the conversion task launches.
        if case .failure = manager.state {
            // expected
        } else {
            Issue.record("Expected .failure state for invalid CLI path, got \(manager.state)")
        }
    }

    // MARK: convert(urls:) with empty array

    @Test("convert(urls:) with empty array leaves state idle")
    func convertEmptyURLArray() {
        let manager = makeManager()
        manager.convert(urls: [])
        #expect(manager.state == .idle)
    }

    // MARK: Milestone tracking

    @Test("milestone at 10th conversion sets celebration message containing '10'")
    func milestone10() {
        UserDefaults.standard.set(9, forKey: "com.markitdown.conversionCount")
        defer { UserDefaults.standard.removeObject(forKey: "com.markitdown.conversionCount") }

        let manager = makeManager()
        manager.checkMilestone()

        #expect(manager.milestoneCelebration != nil)
        #expect(manager.milestoneCelebration?.contains("10") == true)
        #expect(UserDefaults.standard.integer(forKey: "com.markitdown.conversionCount") == 10)
    }

    @Test("milestone at 50th conversion sets celebration message containing '50'")
    func milestone50() {
        UserDefaults.standard.set(49, forKey: "com.markitdown.conversionCount")
        defer { UserDefaults.standard.removeObject(forKey: "com.markitdown.conversionCount") }

        let manager = makeManager()
        manager.checkMilestone()

        #expect(manager.milestoneCelebration != nil)
        #expect(manager.milestoneCelebration?.contains("50") == true)
    }

    @Test("milestone at 100th conversion sets celebration message containing '100'")
    func milestone100() {
        UserDefaults.standard.set(99, forKey: "com.markitdown.conversionCount")
        defer { UserDefaults.standard.removeObject(forKey: "com.markitdown.conversionCount") }

        let manager = makeManager()
        manager.checkMilestone()

        #expect(manager.milestoneCelebration != nil)
        #expect(manager.milestoneCelebration?.contains("100") == true)
    }

    @Test("non-milestone conversion leaves milestoneCelebration nil")
    func nonMilestone() {
        UserDefaults.standard.set(5, forKey: "com.markitdown.conversionCount")
        defer { UserDefaults.standard.removeObject(forKey: "com.markitdown.conversionCount") }

        let manager = makeManager()
        manager.checkMilestone()

        #expect(manager.milestoneCelebration == nil)
    }

    @Test("checkMilestone increments the persistent conversion count")
    func milestoneIncrementsCount() {
        UserDefaults.standard.set(20, forKey: "com.markitdown.conversionCount")
        defer { UserDefaults.standard.removeObject(forKey: "com.markitdown.conversionCount") }

        let manager = makeManager()
        manager.checkMilestone()

        #expect(UserDefaults.standard.integer(forKey: "com.markitdown.conversionCount") == 21)
    }
}
