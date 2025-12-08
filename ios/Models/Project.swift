import Foundation

struct Project: Decodable, Identifiable {
  let projectId: String
  let projectName: String
  let status: String
  let tags: [String]?
  let isFavorite: Bool?
  let createdAt: Date?
  let updatedAt: Date?
  let storyCore: String?
  let leadingBrief: String?
  let firstIdea: String?
  let brainstormIdeas: [String]?
  let metadata: ProjectMetadata?

  var id: String { projectId }

  var statusLabel: String {
    switch status {
    case "created": return "已创建"
    case "in_progress": return "创作中"
    case "completed": return "已完成"
    case "archived": return "已归档"
    default: return status
    }
  }
}

struct ProjectMetadata: Decodable {
  let wordCount: Int?
  let chapterCount: Int?
  let characterCount: Int?
}

struct ProjectsResponse: Decodable {
  let projects: [Project]
  let total: Int
  let page: Int
  let limit: Int
}

struct ProjectsListPayload: Decodable {
  let success: Bool?
  let message: String?
  let data: ProjectsDataPayload?
}

struct ProjectsDataPayload: Decodable {
  let projects: [Project]
  let pagination: Pagination?
  let total: Int?
  let page: Int?
  let limit: Int?
}
