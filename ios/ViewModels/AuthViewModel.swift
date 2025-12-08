import Foundation
import Combine

@MainActor
final class AuthViewModel: ObservableObject {
  @Published var username: String = "user001"
  @Published var password: String = "abcd123456"
  @Published var email: String = "user001@example.com"
  @Published var nickname: String = "新用户"
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published private(set) var user: User?

  private let apiClient = APIClient.shared
  private let tokenStore = AuthTokenStore.shared

  var isAuthenticated: Bool {
    user != nil
  }

  func bootstrapSession() async {
    guard tokenStore.token() != nil else { return }
    await loadProfile()
  }

  func login() async {
    guard !username.isEmpty, !password.isEmpty else {
      errorMessage = "请输入账号和密码"
      return
    }
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    let requestBody = LoginRequest(username: username, password: password)
    guard let body = try? JSONEncoder().encode(requestBody) else {
      errorMessage = "构建登录请求失败"
      return
    }

    do {
      let endpoint = Endpoint(path: "/auth/login", method: .post, body: body)
      let envelope: APIEnvelope<LoginResult> = try await apiClient.send(endpoint)
      guard let payload = envelope.data else {
        throw APIClientError.decoding(envelope.message ?? "登录响应缺少数据")
      }
      tokenStore.save(token: payload.token)
      user = payload.user
    } catch {
      errorMessage = error.localizedDescription
      tokenStore.clear()
    }
  }

  func loadProfile() async {
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    do {
      let endpoint = Endpoint(path: "/auth/profile", method: .get)
      let envelope: APIEnvelope<User> = try await apiClient.send(endpoint)
      guard let profile = envelope.data else {
        throw APIClientError.decoding("获取用户信息失败")
      }
      user = profile
    } catch {
      errorMessage = error.localizedDescription
      tokenStore.clear()
      user = nil
    }
  }

  func logout() {
    tokenStore.clear()
    user = nil
  }

  func registerAccount() async {
    guard !username.isEmpty, !password.isEmpty, !email.isEmpty else {
      errorMessage = "请填写完整注册信息"
      return
    }
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    let registerPayload = RegisterRequest(
      username: username,
      email: email,
      password: password,
      nickname: nickname.isEmpty ? nil : nickname
    )

    guard let body = try? JSONEncoder().encode(registerPayload) else {
      errorMessage = "构建注册请求失败"
      return
    }

    do {
      let endpoint = Endpoint(path: "/users/register", method: .post, body: body)
      let response: APIEnvelope<User> = try await apiClient.send(endpoint)
      guard response.data != nil else {
        throw APIClientError.decoding("注册失败")
      }
      await login()
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}
