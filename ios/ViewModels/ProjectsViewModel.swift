import Foundation
import Combine

@MainActor
final class ProjectsViewModel: ObservableObject {
  @Published var projects: [Project] = []
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var searchText: String = ""
  @Published var selectedStatus: String? = nil
  @Published var isCreating = false
  @Published var newProjectName: String = ""
  @Published var newProjectIdea: String = ""

  private let apiClient = APIClient.shared

  func load() async {
    await fetchProjects()
  }

  func fetchProjects() async {
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    var queryItems: [URLQueryItem] = [
      URLQueryItem(name: "page", value: "1"),
      URLQueryItem(name: "limit", value: "50")
    ]

    if !searchText.isEmpty {
      queryItems.append(URLQueryItem(name: "search", value: searchText))
    }

    if let status = selectedStatus, !status.isEmpty {
      queryItems.append(URLQueryItem(name: "status", value: status))
    }

    do {
      let endpoint = Endpoint(path: "/projects", queryItems: queryItems)
      let payload: ProjectsListPayload = try await apiClient.send(endpoint)
      projects = payload.data?.projects ?? []
    } catch {
      errorMessage = error.localizedDescription
      projects = []
    }
  }

  func toggleFavorite(for project: Project) async {
    let payload: [String: Any] = ["is_favorite": !(project.isFavorite ?? false)]
    guard let body = payload.toJSONData() else { return }
    do {
      let endpoint = Endpoint(path: "/projects/\(project.projectId)", method: .put, body: body)
      let response: APIEnvelope<Project> = try await apiClient.send(endpoint)
      if let updated = response.data {
        updateLocal(project: updated)
      } else {
        await fetchProjects()
      }
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func delete(project: Project) async {
    do {
      let endpoint = Endpoint(path: "/projects/\(project.projectId)", method: .delete)
      _ = try await apiClient.send(endpoint, decodeTo: APIEnvelope<EmptyResponse>.self)
      projects.removeAll { $0.projectId == project.projectId }
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func createProject() async {
    guard !newProjectName.isEmpty else {
      errorMessage = "请输入项目名称"
      return
    }
    isCreating = true
    errorMessage = nil
    defer { isCreating = false }

    var payload: [String: Any] = ["project_name": newProjectName]
    if !newProjectIdea.isEmpty {
      payload["first_idea"] = newProjectIdea
    }
    guard let body = payload.toJSONData() else { return }

    do {
      let endpoint = Endpoint(path: "/projects", method: .post, body: body)
      let response: APIEnvelope<Project> = try await apiClient.send(endpoint)
      if let project = response.data {
        projects.insert(project, at: 0)
        newProjectName = ""
        newProjectIdea = ""
      }
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  private func updateLocal(project: Project) {
    guard let index = projects.firstIndex(where: { $0.projectId == project.projectId }) else {
      return
    }
    projects[index] = project
  }
}
