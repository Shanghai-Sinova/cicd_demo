import SwiftUI

struct StepCard: View {
  let step: CreationStepViewData
  let action: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(step.kind.title)
            .font(.headline)
          Text(step.kind.description)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer()
        StepStatusBadge(status: step.status)
      }

      if let preview = step.resultPreview, !preview.isEmpty {
        Text(preview)
          .font(.footnote)
          .lineLimit(3)
          .foregroundStyle(.secondary)
      }

      Button(action: action) {
        Label("运行", systemImage: "play.fill")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
    }
    .padding()
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 20))
  }
}

struct StepStatusBadge: View {
  let status: StepStatus

  var body: some View {
    Text(status.label)
      .font(.caption)
      .padding(.horizontal, 10)
      .padding(.vertical, 4)
      .background(backgroundColor)
      .foregroundStyle(foregroundColor)
      .clipShape(Capsule())
  }

  private var backgroundColor: Color {
    switch status {
    case .idle:
      return Color.gray.opacity(0.15)
    case .running:
      return Color.yellow.opacity(0.2)
    case .completed:
      return Color.green.opacity(0.2)
    case .failed:
      return Color.red.opacity(0.2)
    }
  }

  private var foregroundColor: Color {
    switch status {
    case .idle:
      return .gray
    case .running:
      return .orange
    case .completed:
      return .green
    case .failed:
      return .red
    }
  }
}
