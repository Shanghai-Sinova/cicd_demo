import SwiftUI

struct ProjectCard: View {
  let project: Project
  var favoriteAction: (() -> Void)?
  var deleteAction: (() -> Void)?

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(project.projectName)
            .font(.headline)
          Text("ID: \(project.projectId)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer()
        Button {
          favoriteAction?()
        } label: {
          Image(systemName: (project.isFavorite ?? false) ? "heart.fill" : "heart")
            .foregroundStyle(.pink)
        }
        .buttonStyle(.plain)
      }

      HStack {
        Text(project.statusLabel)
          .font(.caption)
          .padding(.horizontal, 10)
          .padding(.vertical, 4)
          .background(Color.blue.opacity(0.1))
          .clipShape(Capsule())
        if let tags = project.tags, !tags.isEmpty {
          ForEach(tags.prefix(2), id: \.self) { tag in
            Text(tag)
              .font(.caption2)
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
              .background(Color.gray.opacity(0.15))
              .clipShape(Capsule())
          }
        }
      }

      if let storyCore = project.storyCore, !storyCore.isEmpty {
        Text(storyCore)
          .font(.subheadline)
          .lineLimit(3)
      }

      HStack {
        if let updated = project.updatedAt {
          Label(updated.formatted(date: .abbreviated, time: .shortened), systemImage: "clock")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer()
        Button(role: .destructive) {
          deleteAction?()
        } label: {
          Label("删除", systemImage: "trash")
            .font(.caption)
        }
        .buttonStyle(.bordered)
      }
    }
    .padding()
    .background(Color(.systemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 20))
    .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
  }
}
