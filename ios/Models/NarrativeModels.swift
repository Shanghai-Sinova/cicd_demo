import Foundation

struct NarrativeThread: Decodable, Identifiable {
  let threadId: String
  let title: String
  let summary: String
  let tension: String?
  let characters: [String]
  let tokensUsed: Int?
  let lastUpdated: Date?

  var id: String { threadId }
}

struct NarrativeThreadListResponse: Decodable {
  let threads: [NarrativeThread]
}

struct NarrativeBeat: Decodable, Identifiable {
  let beatId: String
  let content: String
  let prompt: String?
  let tokensUsed: Int?
  let orderIndex: Int

  var id: String { beatId }
}

struct NarrativeBeatListResponse: Decodable {
  let beats: [NarrativeBeat]
}

struct MemoryCompass: Decodable {
  let compassId: String
  let projectId: String
  let anchors: [MemoryAnchor]
  let decisions: [MemoryDecision]
}

struct MemoryAnchor: Decodable, Identifiable {
  let anchorId: String
  let focus: String
  let detail: String
  let weight: Double
  let updatedAt: Date?

  var id: String { anchorId }
}

struct MemoryDecision: Decodable, Identifiable {
  let decisionId: String
  let cue: String
  let outcome: String
  let confidence: Double
  let happenedAt: Date?

  var id: String { decisionId }
}

struct TokenUsage: Equatable {
  var promptTokens: Int = 0
  var completionTokens: Int = 0
  var cachedTokens: Int = 0

  var totalTokens: Int {
    promptTokens + completionTokens - cachedTokens
  }

  var costCNY: Double {
    TokenEstimator.costInCNY(forTokens: totalTokens)
  }
}

enum TokenEstimator {
  private static let charactersPerToken: Double = 1.2
  private static let pricePerThousandTokensCNY: Double = 0.08

  static func estimateTokens(for text: String) -> Int {
    let count = text.trimmingCharacters(in: .whitespacesAndNewlines).count
    guard count > 0 else { return 0 }
    return Int((Double(count) / charactersPerToken).rounded(.up))
  }

  static func costInCNY(forTokens tokens: Int) -> Double {
    guard tokens > 0 else { return 0 }
    let units = Double(tokens) / 1000.0
    return (units * pricePerThousandTokensCNY * 100).rounded(.toNearestOrAwayFromZero) / 100
  }
}
