import Foundation

enum HTTPMethod: String {
  case get = "GET"
  case post = "POST"
  case put = "PUT"
  case delete = "DELETE"
  case patch = "PATCH"
}

struct Endpoint {
  let path: String
  var method: HTTPMethod = .get
  var queryItems: [URLQueryItem] = []
  var headers: [String: String] = [:]
  var body: Data? = nil

  init(path: String,
       method: HTTPMethod = .get,
       queryItems: [URLQueryItem] = [],
       headers: [String: String] = [:],
       body: Data? = nil) {
    self.path = path
    self.method = method
    self.queryItems = queryItems
    self.headers = headers
    self.body = body
  }
}

struct APIErrorEnvelope: Decodable {
  let success: Bool?
  let code: Int?
  let message: String?
  let error: APIErrorDetail?
  let data: APIErrorDataWrapper?
}

struct APIErrorDetail: Decodable {
  let message: String?
  let code: String?
}

struct APIErrorDataWrapper: Decodable {
  let error: APIErrorDetail?
}

enum APIClientError: Error, LocalizedError {
  case invalidURL
  case invalidResponse
  case http(Int, String)
  case decoding(String)

  var errorDescription: String? {
    switch self {
    case .invalidURL:
      return "无效的请求地址"
    case .invalidResponse:
      return "服务器返回异常"
    case .http(let code, let message):
      return "请求失败(\(code))：\(message)"
    case .decoding(let message):
      return "解析数据失败：\(message)"
    }
  }
}

final class APIClient {
  static let shared = APIClient()

  private let session: URLSession
  private let config: AppConfig
  private let tokenStore: AuthTokenStore
  private let decoder: JSONDecoder

  init(session: URLSession = .shared,
       config: AppConfig = .shared,
       tokenStore: AuthTokenStore = .shared) {
    self.session = session
    self.config = config
    self.tokenStore = tokenStore

    decoder = JSONDecoder()
    decoder.keyDecodingStrategy = .convertFromSnakeCase
    decoder.dateDecodingStrategy = .iso8601
  }

  func send<T: Decodable>(_ endpoint: Endpoint,
                          decodeTo type: T.Type = T.self) async throws -> T {
    guard var components = URLComponents(url: config.apiBaseURL, resolvingAgainstBaseURL: false) else {
      throw APIClientError.invalidURL
    }
    components.path = config.apiBaseURL.path + endpoint.path
    if !endpoint.queryItems.isEmpty {
      components.queryItems = endpoint.queryItems
    }
    guard let url = components.url else {
      throw APIClientError.invalidURL
    }

    var request = URLRequest(url: url)
    request.httpMethod = endpoint.method.rawValue
    request.timeoutInterval = config.timeoutSeconds
    request.cachePolicy = .reloadIgnoringLocalCacheData

    var headers = endpoint.headers
    if headers["Content-Type"] == nil {
      headers["Content-Type"] = "application/json"
    }
    headers["Accept"] = "application/json"

    if let token = tokenStore.token() {
      headers["Authorization"] = "Bearer \(token)"
    }

    headers.forEach { key, value in
      request.setValue(value, forHTTPHeaderField: key)
    }

    request.httpBody = endpoint.body

    let (data, response) = try await session.data(for: request)
    guard let httpResponse = response as? HTTPURLResponse else {
      throw APIClientError.invalidResponse
    }

    guard (200..<300).contains(httpResponse.statusCode) else {
      // 401 时清理 token
      if httpResponse.statusCode == 401 {
        tokenStore.clear()
      }
      let serverMessage = decodeServerMessage(from: data)
      throw APIClientError.http(httpResponse.statusCode, serverMessage)
    }

    if T.self == EmptyResponse.self, data.isEmpty {
      return EmptyResponse() as! T
    }

    do {
      return try decoder.decode(T.self, from: data)
    } catch {
      throw APIClientError.decoding(error.localizedDescription)
    }
  }

  private func decodeServerMessage(from data: Data) -> String {
    guard let envelope = try? decoder.decode(APIErrorEnvelope.self, from: data) else {
      return String(data: data, encoding: .utf8) ?? "未知错误"
    }
    if let message = envelope.message, !message.isEmpty {
      return message
    }
    if let detailMessage = envelope.error?.message, !detailMessage.isEmpty {
      return detailMessage
    }
    if let nested = envelope.data?.error?.message, !nested.isEmpty {
      return nested
    }
    return "服务器返回错误"
  }
}

struct EmptyResponse: Decodable {}

extension Dictionary where Key == String, Value == Any {
  func toJSONData() -> Data? {
    guard JSONSerialization.isValidJSONObject(self) else { return nil }
    return try? JSONSerialization.data(withJSONObject: self, options: [])
  }
}
