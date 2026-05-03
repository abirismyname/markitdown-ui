import Testing
import Foundation
@testable import MarkitdownUI

@Suite("AppSettingsStore Validation")
@MainActor
struct AppSettingsStoreTests {

    // MARK: Helpers

    private func tmpDir() throws -> URL {
        let dir = FileManager.default.temporaryDirectory
            .appendingPathComponent("AppSettingsTests-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func makeExecutable(at url: URL) throws {
        FileManager.default.createFile(atPath: url.path, contents: Data("#!/bin/sh\n".utf8))
        try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: url.path)
    }

    // MARK: Empty path

    @Test("empty cliPath returns validation error")
    func emptyCLIPath() {
        let store = AppSettingsStore()
        store.cliPath = ""
        let error = store.validationError()
        #expect(error != nil)
        #expect((error ?? "").lowercased().contains("empty") || (error ?? "").lowercased().contains("path"))
    }

    // MARK: Non-existent path

    @Test("non-existent cliPath returns validation error")
    func nonExistentCLIPath() {
        let store = AppSettingsStore()
        store.cliPath = "/nonexistent/path/to/markitdown"
        let error = store.validationError()
        #expect(error != nil)
    }

    // MARK: Directory path

    @Test("directory cliPath returns validation error")
    func directoryCLIPath() throws {
        let dir = try tmpDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let store = AppSettingsStore()
        store.cliPath = dir.path
        let error = store.validationError()
        #expect(error != nil)
    }

    // MARK: Non-executable file

    @Test("non-executable file returns validation error")
    func nonExecutableCLIPath() throws {
        let dir = try tmpDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let file = dir.appendingPathComponent("markitdown")
        FileManager.default.createFile(atPath: file.path, contents: Data("#!/bin/sh\n".utf8))
        // Explicitly set non-executable permissions
        try FileManager.default.setAttributes([.posixPermissions: 0o644], ofItemAtPath: file.path)

        let store = AppSettingsStore()
        store.cliPath = file.path
        let error = store.validationError()
        #expect(error != nil)
        #expect((error ?? "").lowercased().contains("executable"))
    }

    // MARK: Valid executable

    @Test("valid executable file returns nil validation error")
    func validExecutableCLIPath() throws {
        let dir = try tmpDir()
        defer { try? FileManager.default.removeItem(at: dir) }

        let file = dir.appendingPathComponent("markitdown")
        try makeExecutable(at: file)

        let store = AppSettingsStore()
        store.cliPath = file.path
        let error = store.validationError()
        #expect(error == nil)
    }

    // MARK: bundledMarkitdownPath

    @Test("bundledMarkitdownPath returns nil when binary is absent")
    func bundledPathAbsent() {
        // In a test bundle the bundled markitdown binary is not present
        let path = AppSettingsStore.bundledMarkitdownPath()
        // Either nil, or if it somehow resolves, the file must actually exist
        if let path {
            #expect(FileManager.default.fileExists(atPath: path))
        }
    }

    @Test("bundledMarkitdownPath never crashes when SwiftPM resource bundle is absent")
    func bundledPathNeverCrashes() {
        // Regression test for v1.2.0 launch crash: Bundle.module raised fatalError() when
        // the SwiftPM resource bundle was absent in a packaged .app. The fix replaces the
        // direct Bundle.module call with safeModuleBundle() which returns nil instead.
        // Simply reaching the end of this test without a crash validates the fix.
        let path = AppSettingsStore.bundledMarkitdownPath()
        if let path {
            // If a path was found it must point to a real, executable file.
            #expect(FileManager.default.fileExists(atPath: path))
            #expect(FileManager.default.isExecutableFile(atPath: path))
        }
        // nil is the expected result in test environments where the CLI binary is absent.
    }
}
