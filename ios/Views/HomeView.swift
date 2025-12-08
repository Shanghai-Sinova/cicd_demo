import SwiftUI

struct HomeView: View {
  @EnvironmentObject private var homeViewModel: HomeViewModel
  @EnvironmentObject private var creationViewModel: CreationViewModel

  var body: some View {
    NavigationView {
      ScrollView {
        VStack(spacing: 24) {
          header
          statsSection
          quickActionSection
          recentProjectsSection
        }
        .padding()
      }
      .navigationTitle("首页")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            Task { await homeViewModel.load() }
          } label: {
            Image(systemName: "arrow.clockwise")
          }
        }
      }
    }
  }

  private var header: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("欢迎回来")
        .font(.callout)
        .foregroundStyle(.secondary)
      Text("准备好继续创作了吗？")
        .font(.title2)
        .bold()
      Button {
        Task { await creationViewModel.run(step: .inspiration) }
      } label: {
        Label("开始新的灵感", systemImage: "sparkles")
          .padding()
          .frame(maxWidth: .infinity)
          .background(.purple.opacity(0.15))
          .foregroundStyle(.purple)
          .clipShape(RoundedRectangle(cornerRadius: 16))
      }
    }
  }

  private var statsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("数据概览")
        .font(.headline)
      HStack(spacing: 12) {
        StatCard(title: "项目总数", value: "\(homeViewModel.stats.totalProjects)", trend: "+")
        StatCard(title: "进行中", value: "\(homeViewModel.stats.activeProjects)", trend: "")
      }
      HStack(spacing: 12) {
        StatCard(title: "已完成", value: "\(homeViewModel.stats.completedProjects)", trend: "")
        StatCard(title: "字数", value: "\(homeViewModel.stats.totalWordCount)", trend: "字")
      }
    }
  }

  private var quickActionSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("快速操作")
        .font(.headline)
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
        QuickActionButton(icon: "pencil.and.outline", title: "故事核心") {
          Task { await creationViewModel.run(step: .storyCore) }
        }
        QuickActionButton(icon: "person.2", title: "角色设计") {
          Task { await creationViewModel.run(step: .protagonist) }
        }
        QuickActionButton(icon: "square.grid.2x2", title: "情节序列") {
          Task { await creationViewModel.run(step: .plotSequence) }
        }
        QuickActionButton(icon: "doc.text", title: "生成正文") {
          Task { await creationViewModel.run(step: .writing) }
        }
      }
    }
  }

  private var recentProjectsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("最新项目")
          .font(.headline)
        Spacer()
      }
      ForEach(homeViewModel.projects.prefix(4)) { project in
        ProjectListRow(project: project)
          .padding(16)
          .background(.background)
          .clipShape(RoundedRectangle(cornerRadius: 16))
          .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
      }
    }
  }
}

struct StatCard: View {
  let title: String
  let value: String
  let trend: String

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)
      Text(value)
        .font(.title2)
        .bold()
      Text(trend)
        .font(.caption2)
        .foregroundStyle(.green)
    }
    .frame(maxWidth: .infinity)
    .padding()
    .background(.white)
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
  }
}

struct QuickActionButton: View {
  let icon: String
  let title: String
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(alignment: .leading, spacing: 8) {
        Image(systemName: icon)
          .font(.title2)
          .foregroundStyle(.purple)
        Text(title)
          .font(.headline)
        Text("立即生成")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding()
      .background(.purple.opacity(0.08))
      .clipShape(RoundedRectangle(cornerRadius: 16))
    }
    .buttonStyle(.plain)
  }
}

struct ProjectListRow: View {
  let project: Project

  var body: some View {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        Text(project.projectName)
          .font(.headline)
        Text(project.statusLabel)
          .font(.caption)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(.blue.opacity(0.12))
          .clipShape(Capsule())
      }
      Spacer()
      if let updated = project.updatedAt {
        Text(updated.formatted(date: .abbreviated, time: .shortened))
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
}
