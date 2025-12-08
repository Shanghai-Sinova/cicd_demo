import Foundation
import Combine

@MainActor
final class NarrativeViewModel: ObservableObject {
  @Published var projectId: String = ""
  @Published var draftTitle: String = ""
  @Published var draftSummary: String = ""
  @Published var draftExpansion: String = ""
  @Published private(set) var threads: [NarrativeThread] = []
  @Published private(set) var beats: [NarrativeBeat] = []
  @Published private(set) var compass: MemoryCompass?
  @Published private(set) var tokenUsage = TokenUsage()
  @Published private(set) var isLoading = false
  @Published var errorMessage: String?
  @Published var selectedThreadId: String?
  @Published var tokenInput: String = ""

  private let apiClient = APIClient.shared

  func attachProject(_ id: String) async {
    guard !id.trimmingCharacters(in: .whitespaces).isEmpty else {
      errorMessage = "请先填写项目ID"
      return
    }
    projectId = id
    await loadAll()
  }

  func loadAll() async {
    guard !projectId.isEmpty else { return }
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    do {
      try await withThrowingTaskGroup(of: Void.self) { group in
        group.addTask { try await self.fetchThreads() }
        group.addTask { try await self.refreshCompass() }
        group.addTask { self.recalculateTokens() }
        try await group.waitForAll()
      }
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func fetchThreads() async throws {
    let query = [URLQueryItem(name: "project_id", value: projectId)]
    let endpoint = Endpoint(path: "/narratives/threads", queryItems: query)
    let response: APIEnvelope<NarrativeThreadListResponse> = try await apiClient.send(endpoint)
    threads = response.data?.threads ?? []
    if selectedThreadId == nil {
      selectedThreadId = threads.first?.threadId
    }
    try await fetchBeatsIfNeeded()
  }

  func fetchBeatsIfNeeded() async throws {
    guard let threadId = selectedThreadId else {
      beats = []
      return
    }
    let endpoint = Endpoint(path: "/narratives/threads/\(threadId)/beats")
    let response: APIEnvelope<NarrativeBeatListResponse> = try await apiClient.send(endpoint)
    beats = response.data?.beats ?? []
    recalculateTokens()
  }

  func createThread() async {
    guard !draftTitle.isEmpty else {
      errorMessage = "请填写叙事线标题"
      return
    }
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    let bodyDict: [String: Any] = [
      "project_id": projectId,
      "title": draftTitle,
      "summary": draftSummary.isEmpty ? "多线叙事初稿" : draftSummary
    ]
    guard let body = bodyDict.toJSONData() else { return }

    do {
      let endpoint = Endpoint(path: "/narratives/threads", method: .post, body: body)
      let response: APIEnvelope<NarrativeThread> = try await apiClient.send(endpoint)
      if let thread = response.data {
        threads.insert(thread, at: 0)
        selectedThreadId = thread.threadId
        draftTitle = ""
        draftSummary = ""
      }
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func continueThread() async {
    guard let threadId = selectedThreadId else { return }
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }

    let bodyDict: [String: Any] = [
      "project_id": projectId,
      "generation_hint": draftExpansion.isEmpty ? "延展当前支线剧情" : draftExpansion
    ]
    guard let body = bodyDict.toJSONData() else { return }

    do {
      let endpoint = Endpoint(path: "/narratives/threads/\(threadId)/beats", method: .post, body: body)
      let response: APIEnvelope<NarrativeBeatListResponse> = try await apiClient.send(endpoint)
      beats = response.data?.beats ?? beats
      recalculateTokens()
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func refreshCompass() async throws {
    let query = [URLQueryItem(name: "project_id", value: projectId)]
    let endpoint = Endpoint(path: "/memory/compass", queryItems: query)
    let response: APIEnvelope<MemoryCompass> = try await apiClient.send(endpoint)
    compass = response.data
  }

  func recalculateTokens() {
    let promptFromDraft = TokenEstimator.estimateTokens(for: draftTitle + draftSummary + draftExpansion + tokenInput)
    let remoteTokens = threads.compactMap { $0.tokensUsed }.reduce(0, +)
    let beatTokens = beats.compactMap { $0.tokensUsed }.reduce(0, +)
    tokenUsage.promptTokens = promptFromDraft
    tokenUsage.completionTokens = beatTokens
    tokenUsage.cachedTokens = 0
    if tokenUsage.totalTokens < remoteTokens {
      tokenUsage.completionTokens = remoteTokens
    }
  }
}
