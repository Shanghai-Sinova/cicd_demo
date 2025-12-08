import SwiftUI

struct TokenUsageStrip: View {
  let usage: TokenUsage

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text("本地 Token 估算")
          .font(.subheadline)
          .foregroundStyle(.secondary)
        Text("\(usage.totalTokens) tokens · 约 ¥\(String(format: "%.2f", usage.costCNY))")
          .font(.headline)
      }
      Spacer()
      VStack(alignment: .trailing, spacing: 4) {
        Label("\(usage.promptTokens)", systemImage: "text.alignleft")
          .font(.caption)
          .foregroundStyle(.secondary)
        Label("\(usage.completionTokens)", systemImage: "sparkles")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
    .padding()
    .background(Color(.secondarySystemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 14))
  }
}
