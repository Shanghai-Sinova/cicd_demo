import Foundation

struct APIEnvelope<T: Decodable>: Decodable {
  let success: Bool?
  let message: String?
  let data: T?
  let code: Int?
}

struct PaginatedResponse<T: Decodable>: Decodable {
  let data: T
  let pagination: Pagination?
  let total: Int?
  let page: Int?
  let limit: Int?
}

struct Pagination: Decodable {
  let page: Int
  let limit: Int
  let total: Int
  let totalPages: Int?
}
