import Foundation

struct ConversionResult {
    let outputURL: URL
}

enum ConversionError: LocalizedError {
    case invalidInput
    case processFailed(code: Int32, stderr: String)

    var errorDescription: String? {
        switch self {
        case .invalidInput:
            return "The dropped item is not a valid local file."
        case let .processFailed(code, stderr):
            if stderr.isEmpty {
                return "MarkItDown failed with exit code \(code)."
            }
            return "MarkItDown failed with exit code \(code): \(stderr)"
        }
    }
}

struct MarkitdownConversionService {
    let cliPath: String
    let keepDataURIs: Bool

    func convertFile(at inputURL: URL) throws -> ConversionResult {
        guard inputURL.isFileURL else {
            throw ConversionError.invalidInput
        }

        let outputURL = makeUniqueOutputURL(for: inputURL)

        let process = Process()
        process.executableURL = URL(fileURLWithPath: cliPath)

        var args = [inputURL.path, "-o", outputURL.path]
        if keepDataURIs {
            args.append("--keep-data-uris")
        }
        process.arguments = args

        let stderrPipe = Pipe()
        process.standardError = stderrPipe

        try process.run()
        process.waitUntilExit()

        let stderrData = stderrPipe.fileHandleForReading.readDataToEndOfFile()
        let stderr = String(data: stderrData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard process.terminationStatus == 0 else {
            throw ConversionError.processFailed(code: process.terminationStatus, stderr: stderr)
        }

        return ConversionResult(outputURL: outputURL)
    }

    private func makeUniqueOutputURL(for inputURL: URL) -> URL {
        let folder = inputURL.deletingLastPathComponent()
        let fileName = inputURL.lastPathComponent  // Keep original filename with extension

        var candidate = folder.appendingPathComponent(fileName).appendingPathExtension("md")
        var count = 1

        while FileManager.default.fileExists(atPath: candidate.path) {
            let name = "\(fileName) (\(count))"
            candidate = folder.appendingPathComponent(name).appendingPathExtension("md")
            count += 1
        }

        return candidate
    }
}
