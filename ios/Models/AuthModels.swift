import Foundation

struct LoginRequest: Encodable {
  let username: String
  let password: String
}

struct LoginResult: Decodable {
  let token: String
  let expiresAt: Date
  let user: User
}

struct User: Decodable, Identifiable {
  let id: Int
  let username: String
  let email: String?
  let role: String?
  let nickname: String?
  let avatar: String?
  let phone: String?
  let isApproved: Bool?
  let status: String?
  let createdAt: Date?
  let updatedAt: Date?

  var displayName: String {
    nickname ?? username
  }
}
