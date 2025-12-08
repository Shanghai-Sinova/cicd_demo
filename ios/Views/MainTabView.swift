import SwiftUI

struct MainTabView: View {
  @EnvironmentObject private var homeViewModel: HomeViewModel
  @EnvironmentObject private var projectsViewModel: ProjectsViewModel
  @EnvironmentObject private var creationViewModel: CreationViewModel
  @EnvironmentObject private var narrativeViewModel: NarrativeViewModel
  @EnvironmentObject private var userCenterViewModel: UserCenterViewModel

  var body: some View {
    TabView {
      HomeView()
        .tabItem {
          Label("首页", systemImage: "house.fill")
        }

      ProjectsView()
        .tabItem {
          Label("项目", systemImage: "books.vertical.fill")
        }

      CreationWorkflowView()
        .tabItem {
          Label("创作", systemImage: "sparkles")
        }

      NarrativeLabView()
        .tabItem {
          Label("叙事", systemImage: "map")
        }

      PaymentCenterView()
        .tabItem {
          Label("会员", systemImage: "creditcard.fill")
        }

      ProfileView()
        .tabItem {
          Label("我的", systemImage: "person.crop.circle")
        }
    }
    .task {
      await homeViewModel.load()
      await projectsViewModel.load()
      if !creationViewModel.projectId.isEmpty {
        await creationViewModel.attachProject(id: creationViewModel.projectId)
      }
    }
  }
}

struct ProfileView: View {
  @EnvironmentObject private var authViewModel: AuthViewModel
  @EnvironmentObject private var creationViewModel: CreationViewModel
  @EnvironmentObject private var narrativeViewModel: NarrativeViewModel

  var body: some View {
    NavigationView {
      List {
        Section("账户") {
          HStack {
            VStack(alignment: .leading) {
              Text(authViewModel.user?.displayName ?? "未知用户")
                .font(.headline)
              Text(authViewModel.user?.email ?? "--")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            Spacer()
            if let status = authViewModel.user?.status {
              Text(status)
                .font(.caption)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.blue.opacity(0.1))
                .clipShape(Capsule())
            }
          }
        }

        Section("创作项目") {
          if creationViewModel.projectId.isEmpty {
            Text("尚未绑定项目")
              .foregroundStyle(.secondary)
          } else {
            VStack(alignment: .leading, spacing: 4) {
              Text(creationViewModel.projectName.isEmpty ? "项目 #\(creationViewModel.projectId)" : creationViewModel.projectName)
              Text("ID: \(creationViewModel.projectId)")
                .font(.caption)
                .foregroundStyle(.secondary)
            }
          }
        }

        Section("用户中心") {
          NavigationLink(destination: UserCenterView()) {
            Label("积分 / 充值", systemImage: "creditcard")
          }
          NavigationLink(destination: NarrativeLabView()) {
            Label("多线叙事 / 记忆罗盘", systemImage: "map")
          }
        }

        Section {
          Button(role: .destructive) {
            authViewModel.logout()
          } label: {
            Label("退出登录", systemImage: "rectangle.portrait.and.arrow.right")
          }
        }
      }
      .navigationTitle("个人中心")
    }
  }
}
