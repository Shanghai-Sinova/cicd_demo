import Foundation

enum AppEnvironment: String {
  case development
  case staging
  case production
}

struct AppConfig {
  static let shared = AppConfig()
  let environment: AppEnvironment
  let apiBaseURL: URL
  let timeoutSeconds: TimeInterval = 5000 // 硬性要求：不超过 5000 秒

  private init() {
    #if DEBUG
    environment = .development
    #else
    environment = .production
    #endif

    let env = ProcessInfo.processInfo.environment
    let baseURLString = env["MOBILE_API_BASE_URL"] ?? "http://127.0.0.1:23004/api/v1"

    guard let baseURL = URL(string: baseURLString) else {
      fatalError("无法解析 API 基础地址: \(baseURLString)")
    }

    apiBaseURL = baseURL
  }
}
