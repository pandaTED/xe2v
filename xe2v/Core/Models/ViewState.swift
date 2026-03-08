import Foundation

enum LoadState: Equatable {
    case idle
    case loading
    case loaded
    case empty(message: String)
    case failed(message: String)
}
