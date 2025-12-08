import SwiftUI

struct CreationWorkflowView: View {
  @EnvironmentObject private var viewModel: CreationViewModel

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          projectBindingSection
          stepsSection
          outputSection
        }
        .padding()
      }
      .navigationTitle("分步创作")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            if !viewModel.projectId.isEmpty {
              Task { await viewModel.attachProject(id: viewModel.projectId) }
            }
          } label: {
            Image(systemName: "arrow.triangle.2.circlepath")
          }
        }
      }
    }
  }

  private var projectBindingSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("绑定创作项目")
        .font(.headline)
      TextField("项目 ID (数字)", text: $viewModel.projectId)
        .keyboardType(.numberPad)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
      TextField("项目名称", text: $viewModel.projectName)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
      TextField("创作灵感", text: $viewModel.firstIdea, axis: .vertical)
        .padding()
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))

      if let error = viewModel.errorMessage {
        Text(error)
          .foregroundStyle(.red)
          .font(.caption)
      }

      HStack {
        Button {
          Task { await viewModel.ensureProjectIfNeeded() }
        } label: {
          Label("新建/绑定", systemImage: "link")
        }
        .buttonStyle(.borderedProminent)

        Button {
          if !viewModel.projectId.isEmpty {
            Task { await viewModel.attachProject(id: viewModel.projectId) }
          }
        } label: {
          Label("同步", systemImage: "icloud.and.arrow.down")
        }
        .buttonStyle(.bordered)
      }
    }
    .padding()
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 20))
  }

  private var stepsSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      Text("创作步骤")
        .font(.headline)
      ForEach(viewModel.steps) { step in
        StepCard(step: step) {
          Task { await viewModel.run(step: step.kind) }
        }
      }
    }
  }

  private var outputSection: some View {
    VStack(alignment: .leading, spacing: 16) {
      if !viewModel.protagonist.isEmpty {
        OutputCard(title: "主角人物", content: viewModel.protagonist)
      }
      if !viewModel.supportingCharacters.isEmpty {
        OutputCard(title: "配角关系", content: formattedSupporting())
      }
      if !viewModel.plotSequence.isEmpty {
        OutputCard(title: "情节序列", content: viewModel.plotSequence)
      }
      if !viewModel.sceneBeats.isEmpty {
        OutputCard(title: "场景节拍", content: viewModel.sceneBeats.map { "• \($0.title): \($0.summary)" }.joined(separator: "\n"))
      }
      if !viewModel.scriptContent.isEmpty {
        OutputCard(title: "正文输出", content: viewModel.scriptContent)
      }
    }
  }

  private func formattedSupporting() -> String {
    viewModel.supportingCharacters
      .map { character in
        let relation = (character.relationship ?? "").trimmingCharacters(in: .whitespaces)
        let relationText = relation.isEmpty ? "" : "（\(relation)）"
        return "• \(character.name)：\(character.description)\(relationText)"
      }
      .joined(separator: "\n")
  }
}

struct OutputCard: View {
  let title: String
  let content: String

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        Text(title)
          .font(.headline)
        Spacer()
        Image(systemName: "doc.on.doc")
          .foregroundStyle(.secondary)
      }
      Text(content)
        .font(.body)
        .lineLimit(nil)
    }
    .padding()
    .background(.thickMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 20))
  }
}
