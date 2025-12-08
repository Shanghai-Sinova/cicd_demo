import SwiftUI

struct NarrativeThreadCard: View {
  let thread: NarrativeThread
  let isSelected: Bool
  var onSelect: (() -> Void)?

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(thread.title)
            .font(.headline)
          Text(thread.summary)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(3)
        }
        Spacer()
        if let tension = thread.tension, !tension.isEmpty {
          Text(tension)
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.orange.opacity(0.15))
            .clipShape(Capsule())
        }
      }

      HStack(spacing: 12) {
        Label("tokens \(thread.tokensUsed ?? 0)", systemImage: "gauge.with.dots.needle.33percent")
          .font(.caption)
          .foregroundStyle(.secondary)
        let characterNames = thread.characters.joined(separator: " / ")
        if !characterNames.isEmpty {
          Label(characterNames, systemImage: "person.3.sequence")
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        Spacer()
        if let updated = thread.lastUpdated {
          Text(updated.formatted(date: .abbreviated, time: .shortened))
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
      }
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(isSelected ? Color.blue.opacity(0.12) : Color(.systemBackground))
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
    )
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .contentShape(Rectangle())
    .onTapGesture {
      onSelect?()
    }
  }
}
