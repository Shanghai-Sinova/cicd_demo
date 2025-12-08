import SwiftUI

struct LoginView: View {
  @EnvironmentObject private var authViewModel: AuthViewModel
  @State private var isRegisterMode = false

  var body: some View {
    VStack(spacing: 32) {
      VStack(spacing: 8) {
        Image(systemName: "sparkles")
          .font(.system(size: 48))
          .foregroundStyle(.purple)
        Text("创作工作台")
          .font(.largeTitle)
          .bold()
        Text("与 Web 前端一致的剧情创作流程")
          .foregroundStyle(.secondary)
      }

      Picker("模式", selection: $isRegisterMode) {
        Text("登录").tag(false)
        Text("注册").tag(true)
      }
      .pickerStyle(.segmented)

      VStack(spacing: 16) {
        TextField("用户名", text: $authViewModel.username)
          .textContentType(.username)
          .autocapitalization(.none)
          .disableAutocorrection(true)
          .padding()
          .background(.gray.opacity(0.1))
          .clipShape(RoundedRectangle(cornerRadius: 12))

        if isRegisterMode {
          TextField("邮箱", text: $authViewModel.email)
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            .padding()
            .background(.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))

          TextField("昵称", text: $authViewModel.nickname)
            .padding()
            .background(.gray.opacity(0.1))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }

        SecureField("密码", text: $authViewModel.password)
          .textContentType(.password)
          .padding()
          .background(.gray.opacity(0.1))
          .clipShape(RoundedRectangle(cornerRadius: 12))
      }

      if let error = authViewModel.errorMessage {
        Text(error)
          .foregroundStyle(.red)
          .font(.footnote)
      }

      Button {
        Task {
          if isRegisterMode {
            await authViewModel.registerAccount()
          } else {
            await authViewModel.login()
          }
        }
      } label: {
        if authViewModel.isLoading {
          ProgressView()
            .progressViewStyle(.circular)
            .tint(.white)
        } else {
          Text(isRegisterMode ? "注册并登录" : "登录")
            .fontWeight(.semibold)
        }
      }
      .frame(maxWidth: .infinity)
      .padding()
      .background(.purple)
      .foregroundStyle(.white)
      .clipShape(RoundedRectangle(cornerRadius: 12))
      .disabled(authViewModel.isLoading)

      Button("已有账号？切换登录") {
        isRegisterMode.toggle()
      }
      .font(.footnote)
      .foregroundColor(.secondary)

      Spacer()
    }
    .padding(32)
  }
}
