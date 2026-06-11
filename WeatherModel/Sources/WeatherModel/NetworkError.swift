public enum NetworkError: Error, Equatable, Sendable {
    case invalidURL
    case invalidResponse
    case decodingFailed
    case unauthorized
}
