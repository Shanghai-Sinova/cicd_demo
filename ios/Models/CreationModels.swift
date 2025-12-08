import Foundation

struct BrainstormGenerateRequest: Encodable {
  let firstIdea: String
  let numIdeas: Int
  let creativeStyle: [String]
  let conceptType: String?
  let conceptDepth: String?
  let plotType: String?
  let projectId: String?
}

struct BrainstormGenerateResponse: Decodable {
  let success: Bool?
  let message: String?
  let data: BrainstormPayload?
}

struct BrainstormPayload: Decodable {
  let brainstormIdeas: [String]?
  let session: BrainstormSession?
}

struct BrainstormSession: Decodable, Identifiable {
  let sessionId: String
  let projectId: String?
  let createdAt: Date?
  let ideas: [String]?

  var id: String { sessionId }
}

struct StoryCoreResponse: Decodable {
  let content: String?
  let success: Bool
  let message: String?
}

struct StoryCoreAdvanceRequest: Encodable {
  let projectId: String
  let storyCore: String
  let leadingQuantity: Int?
}

struct ProtagonistResponse: Decodable {
  let success: Bool
  let message: String?
  let data: ProtagonistPayload?
}

struct ProtagonistPayload: Decodable {
  let leadingBrief: String?
}

struct SupportingCharactersResponse: Decodable {
  let success: Bool
  let message: String?
  let supportingCharacters: [SupportingCharacterDTO]?
}

struct SupportingCharacterDTO: Codable, Identifiable {
  let id: String?
  let name: String
  let description: String
  let relationship: String?
  let orderIndex: Int?

  var displayId: String { id ?? UUID().uuidString }
  var identifier: String { id ?? name }
  var stableId: String { id ?? UUID().uuidString }
  var actualId: String { id ?? stableId }
}

struct GenerateResponse: Decodable {
  let success: Bool
  let message: String?
  let content: String?
  let data: GenerateDataWrapper?
}

struct GenerateDataWrapper: Decodable {
  let projectId: String?
  let sequence: String?
}

struct PlotSequenceResponse: Decodable {
  let data: PlotSequenceData?
  let message: String?
}

struct PlotSequenceData: Decodable {
  let projectId: String?
  let sequence: String?
}

struct SequenceBeatResponse: Decodable {
  let success: Bool
  let message: String?
  let data: SequenceBeatData?
}

struct SequenceBeatData: Decodable {
  let sequenceId: String
  let sceneBeats: [SequenceBeatItem]
}

struct SequenceBeatItem: Codable, Identifiable {
  let id: String
  let title: String
  let summary: String
  let raw: String

  init(id: String, title: String, summary: String, raw: String) {
    self.id = id
    self.title = title
    self.summary = summary
    self.raw = raw
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()

    if let value = try? container.decode(String.self) {
      id = UUID().uuidString
      title = value.components(separatedBy: "\n").first ?? "Scene"
      summary = value
      raw = value
      return
    }

    if let value = try? container.decode([String: String].self) {
      raw = value.description
      title = value["title"] ?? value["scene"] ?? "Scene"
      summary = value["summary"] ?? value["content"] ?? raw
      id = value["id"] ?? UUID().uuidString
      return
    }

    throw DecodingError.dataCorruptedError(in: container, debugDescription: "无法解析场景节拍")
  }
}

struct SequenceScriptResponse: Decodable {
  let success: Bool
  let message: String?
  let data: SequenceScriptData?
}

struct SequenceScriptData: Decodable {
  let generatedContent: String?
}
