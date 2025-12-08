import SwiftUI

struct ProjectsView: View {
  @EnvironmentObject private var viewModel: ProjectsViewModel
  @State private var isPresentingCreation = false

  var body: some View {
    NavigationView {
      VStack {
        searchBar
        statusFilter
        projectList
      }
      .background(Color(.systemGroupedBackground))
      .navigationTitle("项目管理")
      .toolbar {
        ToolbarItem(placement: .navigationBarTrailing) {
          Button {
            isPresentingCreation = true
          } label: {
            Image(systemName: "plus")
          }
        }
        ToolbarItem(placement: .navigationBarLeading) {
          Button {
            Task { await viewModel.fetchProjects() }
          } label: {
            Image(systemName: "arrow.clockwise")
          }
        }
      }
      .sheet(isPresented: $isPresentingCreation) {
        CreateProjectSheet(isPresented: $isPresentingCreation)
      }
    }
  }

  private var searchBar: some View {
    HStack {
      Image(systemName: "magnifyingglass")
      TextField("搜索项目名称", text: $viewModel.searchText)
        .submitLabel(.search)
        .onSubmit {
          Task { await viewModel.fetchProjects() }
        }
      if !viewModel.searchText.isEmpty {
        Button {
          viewModel.searchText = ""
          Task { await viewModel.fetchProjects() }
        } label: {
          Image(systemName: "xmark.circle.fill")
            .foregroundStyle(.secondary)
        }
      }
    }
    .padding(10)
    .background(.ultraThickMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 16))
    .padding()
  }

  private var statusFilter: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 12) {
        ForEach(filterOptions) { status in
          let isSelected = viewModel.selectedStatus == status.value
          Button {
            if isSelected {
              viewModel.selectedStatus = nil
            } else {
              viewModel.selectedStatus = status.value
            }
            Task { await viewModel.fetchProjects() }
          } label: {
            Text(status.label)
              .font(.subheadline)
              .padding(.horizontal, 16)
              .padding(.vertical, 8)
              .background(isSelected ? Color.blue.opacity(0.15) : Color(.systemBackground))
              .foregroundColor(isSelected ? .blue : .primary)
              .clipShape(Capsule())
          }
        }
      }
      .padding(.horizontal)
    }
  }

  private var projectList: some View {
    ScrollView {
      LazyVStack(spacing: 12) {
        ForEach(viewModel.projects) { project in
          ProjectCard(project: project,
                      favoriteAction: {
                        Task { await viewModel.toggleFavorite(for: project) }
                      },
                      deleteAction: {
                        Task { await viewModel.delete(project: project) }
                      })
        }
        if viewModel.isLoading {
          ProgressView()
            .padding()
        }
        if let error = viewModel.errorMessage {
          Text(error)
            .foregroundStyle(.red)
            .padding()
        }
      }
      .padding(.horizontal)
    }
  }

  private struct StatusFilterOption: Identifiable {
    let id = UUID()
    let label: String
    let value: String?
  }

  private var filterOptions: [StatusFilterOption] {
    [
      StatusFilterOption(label: "全部", value: nil),
      StatusFilterOption(label: "创作中", value: "in_progress"),
      StatusFilterOption(label: "已完成", value: "completed"),
      StatusFilterOption(label: "归档", value: "archived")
    ]
  }
}

struct CreateProjectSheet: View {
  @EnvironmentObject private var viewModel: ProjectsViewModel
  @Binding var isPresented: Bool

  var body: some View {
    NavigationView {
      Form {
        Section("基本信息") {
          TextField("项目名称", text: $viewModel.newProjectName)
          TextField("创作灵感 (可选)", text: $viewModel.newProjectIdea)
        }

        if let error = viewModel.errorMessage {
          Section {
            Text(error)
              .foregroundStyle(.red)
          }
        }
      }
      .navigationTitle("新建项目")
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("取消") { isPresented = false }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button {
            Task {
              await viewModel.createProject()
              if !viewModel.isCreating {
                isPresented = false
              }
            }
          } label: {
            if viewModel.isCreating {
              ProgressView()
            } else {
              Text("创建")
            }
          }
          .disabled(viewModel.newProjectName.isEmpty)
        }
      }
    }
  }
}
