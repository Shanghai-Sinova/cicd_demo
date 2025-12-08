import Foundation
import Combine

enum CreationStepKind: String, CaseIterable, Identifiable {
  case inspiration
  case storyCore
  case protagonist
  case relationships
  case plotSequence
  case writing

  var id: String { rawValue }

  var title: String {
    switch self {
    case .inspiration: return "输入灵感"
    case .storyCore: return "故事核心"
    case .protagonist: return "主角人物"
    case .relationships: return "配角关系"
    case .plotSequence: return "情节序列"
    case .writing: return "正文生成"
    }
  }

  var description: String {
    switch self {
    case .inspiration: return "输入创作需求并生成多条灵感"
    case .storyCore: return "选择并深化故事核心"
    case .protagonist: return "生成并修改主角小传"
    case .relationships: return "生成关键配角及关系图"
    case .plotSequence: return "构建情节和场景节拍"
    case .writing: return "根据节拍生成完整稿件"
    }
  }
}

enum StepStatus: Equatable {
  case idle
  case running
  case completed
  case failed(String)

  var label: String {
    switch self {
    case .idle: return "待处理"
    case .running: return "生成中"
    case .completed: return "已完成"
    case .failed: return "失败"
    }
  }
}

struct CreationStepViewData: Identifiable {
  let kind: CreationStepKind
  var status: StepStatus = .idle
  var resultPreview: String? = nil
  var updatedAt: Date? = nil

  var id: String { kind.id }
}

@MainActor
final class CreationViewModel: ObservableObject {
  @Published var projectId: String = ""
  @Published var projectName: String = ""
  @Published var firstIdea: String = ""
  @Published var brainstormIdeas: [String] = []
  @Published var selectedIdea: String? = nil
  @Published var storyCore: String = ""
  @Published var protagonist: String = ""
  @Published var supportingCharacters: [SupportingCharacterDTO] = []
  @Published var plotSequence: String = ""
  @Published var sceneBeats: [SequenceBeatItem] = []
  @Published var scriptContent: String = ""
  @Published var isLoadingProject = false
  @Published var errorMessage: String?

  @Published var steps: [CreationStepViewData] = CreationStepKind.allCases.map {
    CreationStepViewData(kind: $0)
  }

  private let apiClient = APIClient.shared

  func attachProject(id: String) async {
    guard !id.isEmpty else {
      errorMessage = "请输入项目ID"
      return
    }
    isLoadingProject = true
    errorMessage = nil
    defer { isLoadingProject = false }

    do {
      let endpoint = Endpoint(path: "/projects/\(id)")
      let response: APIEnvelope<Project> = try await apiClient.send(endpoint)
      guard let project = response.data else {
        throw APIClientError.decoding("未获取到项目数据")
      }
      projectId = project.projectId
      projectName = project.projectName
      storyCore = project.storyCore ?? ""
      firstIdea = project.firstIdea ?? ""
      brainstormIdeas = project.brainstormIdeas ?? []
      protagonist = project.leadingBrief ?? ""
      plotSequence = project.storyCore ?? ""
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func ensureProjectIfNeeded() async {
    guard projectId.isEmpty else { return }
    errorMessage = nil

    let payload: [String: Any] = [
      "project_name": projectName.isEmpty ? "移动端创作项目" : projectName,
      "first_idea": firstIdea.isEmpty ? "" : firstIdea
    ]

    guard let body = payload.toJSONData() else {
      errorMessage = "无法创建项目"
      return
    }

    do {
      let endpoint = Endpoint(path: "/projects", method: .post, body: body)
      let response: APIEnvelope<Project> = try await apiClient.send(endpoint)
      guard let project = response.data else {
        throw APIClientError.decoding("创建项目失败")
      }
      projectId = project.projectId
      projectName = project.projectName
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func run(step kind: CreationStepKind) async {
    if projectId.isEmpty {
      await ensureProjectIfNeeded()
      if projectId.isEmpty { return }
    }

    updateStep(kind: kind, status: .running)

    do {
      switch kind {
      case .inspiration:
        try await runBrainstorm()
      case .storyCore:
        try await runStoryCore()
      case .protagonist:
        try await runProtagonist()
      case .relationships:
        try await runSupporting()
      case .plotSequence:
        try await runPlotSequence()
      case .writing:
        try await runScript()
      }
      updateStep(kind: kind, status: .completed, result: preview(for: kind))
    } catch {
      errorMessage = error.localizedDescription
      updateStep(kind: kind, status: .failed(error.localizedDescription))
    }
  }

  private func runBrainstorm() async throws {
    let request = BrainstormGenerateRequest(
      firstIdea: firstIdea.isEmpty ? "请帮我创作一部都市奇幻爱情故事" : firstIdea,
      numIdeas: 5,
      creativeStyle: [],
      conceptType: "fantasy",
      conceptDepth: nil,
      plotType: "conflict_internal",
      projectId: projectId
    )
    guard let body = try? JSONEncoder().encode(request) else {
      throw APIClientError.decoding("无法构建灵感请求")
    }
    let endpoint = Endpoint(path: "/llm/brainstorm", method: .post, body: body)
    let response: BrainstormGenerateResponse = try await apiClient.send(endpoint)
    brainstormIdeas = response.data?.brainstormIdeas ?? []
    selectedIdea = brainstormIdeas.first

    if let idea = selectedIdea {
      try await persistStoryCore(idea)
    }
  }

  private func runStoryCore() async throws {
    guard !storyCore.isEmpty || selectedIdea != nil else {
      throw APIClientError.decoding("请先生成或选择灵感")
    }
    if storyCore.isEmpty, let idea = selectedIdea {
      storyCore = idea
    }

    let payload: [String: Any] = [
      "project_id": projectId,
      "story_core": storyCore,
      "leading_quantity": 1
    ]
    guard let body = payload.toJSONData() else { return }
    let endpoint = Endpoint(path: "/projects/\(projectId)/story-core/advance", method: .post, body: body)
    _ = try await apiClient.send(endpoint, decodeTo: APIEnvelope<EmptyResponse>.self)
  }

  private func runProtagonist() async throws {
    let payload: [String: Any] = [
      "project_id": projectId,
      "leading_quantity": 1
    ]
    guard let body = payload.toJSONData() else { return }
    let query = [URLQueryItem(name: "project_id", value: projectId)]
    let endpoint = Endpoint(path: "/protagonist/generate", method: .post, queryItems: query, body: body)
    let response: ProtagonistResponse = try await apiClient.send(endpoint)
    protagonist = response.data?.leadingBrief ?? protagonist
  }

  private func runSupporting() async throws {
    let endpoint = Endpoint(path: "/projects/\(projectId)/generate/supporting", method: .post)
    let response: GenerateResponse = try await apiClient.send(endpoint)
    if let jsonString = response.content?.data(using: .utf8),
       let decoded = try? JSONDecoder().decode([SupportingCharacterDTO].self, from: jsonString) {
      supportingCharacters = decoded
    } else {
      supportingCharacters = []
    }
  }

  private func runPlotSequence() async throws {
    let sequencePayload: [String: Any] = ["project_id": projectId]
    let endpoint = Endpoint(path: "/sequence-act/generate", method: .post, body: sequencePayload.toJSONData())
    let response: PlotSequenceResponse = try await apiClient.send(endpoint)
    plotSequence = response.data?.sequence ?? plotSequence

    let beatsPayload: [String: Any] = [
      "project_id": projectId,
      "sequence_id": "seq_main"
    ]
    let beatsEndpoint = Endpoint(path: "/sequence-beat/generate", method: .post, body: beatsPayload.toJSONData())
    let beats: SequenceBeatResponse = try await apiClient.send(beatsEndpoint)
    if let payload = beats.data?.sceneBeats {
      sceneBeats = payload
    }
  }

  private func runScript() async throws {
    guard !sceneBeats.isEmpty else {
      throw APIClientError.decoding("请先生成场景节拍")
    }
    let beatSummaries = sceneBeats.map { $0.summary }
    let body: [String: Any] = [
      "template_name": "sequence_scripts",
      "variables": [
        "project_id": projectId,
        "current_seq_beats": beatSummaries
      ],
      "metadata": ["project_id": projectId]
    ]

    guard let data = body.toJSONData() else { return }
    let endpoint = Endpoint(path: "/llm/generate-universal", method: .post, body: data)
    let response: SequenceScriptResponse = try await apiClient.send(endpoint)
    scriptContent = response.data?.generatedContent ?? scriptContent
  }

  private func updateStep(kind: CreationStepKind, status: StepStatus, result: String? = nil) {
    guard let index = steps.firstIndex(where: { $0.kind == kind }) else { return }
    steps[index].status = status
    if let result = result {
      steps[index].resultPreview = result
    }
    steps[index].updatedAt = Date()
  }

  private func preview(for kind: CreationStepKind) -> String {
    switch kind {
    case .inspiration:
      return selectedIdea ?? brainstormIdeas.first ?? ""
    case .storyCore:
      return storyCore
    case .protagonist:
      return protagonist
    case .relationships:
      return supportingCharacters.first?.description ?? ""
    case .plotSequence:
      return plotSequence
    case .writing:
      return scriptContent
    }
  }

  private func persistStoryCore(_ content: String) async throws {
    let payload: [String: Any] = ["story_core": content]
    guard let body = payload.toJSONData() else { return }
    let endpoint = Endpoint(path: "/projects/\(projectId)", method: .put, body: body)
    _ = try await apiClient.send(endpoint, decodeTo: APIEnvelope<Project>.self)
    storyCore = content
  }
}
