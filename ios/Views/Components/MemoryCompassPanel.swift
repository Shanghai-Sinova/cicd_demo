import SwiftUI

struct MemoryCompassPanel: View {
  let compass: MemoryCompass

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("记忆罗盘")
          .font(.headline)
        Spacer()
        Text("项目 \(compass.projectId)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      if compass.anchors.isEmpty && compass.decisions.isEmpty {
        Text("暂无记忆锚点，先生成叙事线即可沉淀上下文。")
          .font(.caption)
          .foregroundStyle(.secondary)
      } else {
        CompassAnchorsView(anchors: compass.anchors)
        Divider()
        VStack(alignment: .leading, spacing: 8) {
          Text("决策记录")
            .font(.subheadline)
          ForEach(compass.decisions.prefix(4)) { decision in
            HStack(alignment: .top, spacing: 8) {
              Circle()
                .fill(Color.blue.opacity(0.2))
                .frame(width: 10, height: 10)
              VStack(alignment: .leading, spacing: 4) {
                Text(decision.cue)
                  .font(.subheadline)
                Text(decision.outcome)
                  .font(.caption)
                  .foregroundStyle(.secondary)
                if let time = decision.happenedAt {
                  Text(time.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                }
              }
              Spacer()
              Text(String(format: "%.0f%%", decision.confidence * 100))
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
        }
      }
    }
    .padding()
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 18))
  }
}

private struct CompassAnchorsView: View {
  let anchors: [MemoryAnchor]

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("锚点")
        .font(.subheadline)
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
        ForEach(anchors.prefix(6)) { anchor in
          VStack(alignment: .leading, spacing: 4) {
            Text(anchor.focus)
              .font(.headline)
            Text(anchor.detail)
              .font(.caption)
              .foregroundStyle(.secondary)
              .lineLimit(3)
            HStack {
              Spacer()
              Text(String(format: "权重 %.1f", anchor.weight))
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
          }
          .padding()
          .background(Color(.secondarySystemBackground))
          .clipShape(RoundedRectangle(cornerRadius: 12))
        }
      }
    }
  }
}
