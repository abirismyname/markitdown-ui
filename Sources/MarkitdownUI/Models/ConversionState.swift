import Foundation

enum ConversionState: Equatable {
    case idle
    case converting(fileName: String)
    case success(outputURL: URL)
    case failure(message: String)
}
