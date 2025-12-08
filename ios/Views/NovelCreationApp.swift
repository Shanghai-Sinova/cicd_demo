import SwiftUI

@main
struct NovelCreationApp: App {
  @StateObject private var authViewModel = AuthViewModel()
  @StateObject private var homeViewModel = HomeViewModel()
  @StateObject private var projectsViewModel = ProjectsViewModel()
  @StateObject private var creationViewModel = CreationViewModel()
  @StateObject private var narrativeViewModel = NarrativeViewModel()
  @StateObject private var userCenterViewModel = UserCenterViewModel()

  var body: some Scene {
    WindowGroup {
      RootView()
        .environmentObject(authViewModel)
        .environmentObject(homeViewModel)
        .environmentObject(projectsViewModel)
        .environmentObject(creationViewModel)
        .environmentObject(narrativeViewModel)
        .environmentObject(userCenterViewModel)
        .task {
          await authViewModel.bootstrapSession()
        }
    }
  }
}

struct RootView: View {
  @EnvironmentObject private var authViewModel: AuthViewModel

  var body: some View {
    if authViewModel.isAuthenticated {
      MainTabView()
    } else {
      LoginView()
    }
  }
}
