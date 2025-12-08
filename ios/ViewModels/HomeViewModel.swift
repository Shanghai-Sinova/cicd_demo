import Foundation
import Combine

struct HomeStats {
  var totalProjects: Int = 0
  var activeProjects: Int = 0
  var completedProjects: Int = 0
  var totalWordCount: Int = 0
}

@MainActor
final class HomeViewModel: ObservableObject {
  @Published private(set) var stats = HomeStats()
  @Published private(set) var projects: [Project] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  private let apiClient = APIClient.shared

  func load() async {
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    let queryItems = [
      URLQueryItem(name: "limit", value: "20"),
      URLQueryItem(name: "sort_by", value: "updated_at"),
      URLQueryItem(name: "sort_order", value: "desc")
    ]

    do {
      let endpoint = Endpoint(path: "/projects", queryItems: queryItems)
      let payload: ProjectsListPayload = try await apiClient.send(endpoint)
      guard let data = payload.data else {
        throw APIClientError.decoding("项目列表缺少数据")
      }
      projects = data.projects
      stats = makeStats(from: data.projects, total: data.total ?? data.projects.count)
    } catch {
      errorMessage = error.localizedDescription
      projects = []
    }
  }

  private func makeStats(from projects: [Project], total: Int) -> HomeStats {
    var stats = HomeStats()
    stats.totalProjects = total
    stats.activeProjects = projects.filter { $0.status == "in_progress" || $0.status == "active" }.count
    stats.completedProjects = projects.filter { $0.status == "completed" }.count
    stats.totalWordCount = projects.compactMap { $0.metadata?.wordCount }.reduce(0, +)
    return stats
  }
}
