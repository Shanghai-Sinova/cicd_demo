import SwiftUI

struct UserCenterView: View {
  @EnvironmentObject private var viewModel: UserCenterViewModel

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        pointsCard
        transactionsSection
        rechargeSection
      }
      .padding(20)
    }
    .task { await viewModel.refreshAll() }
    .navigationTitle("用户中心")
    .alert(isPresented: Binding<Bool>(get: { viewModel.errorMessage != nil }, set: { _ in viewModel.errorMessage = nil })) {
      Alert(title: Text("提示"), message: Text(viewModel.errorMessage ?? ""), dismissButton: .default(Text("好的")))
    }
  }

  private var pointsCard: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("积分概览").font(.headline)
      if let points = viewModel.points {
        HStack {
          VStack(alignment: .leading) {
            Text("可用积分")
              .font(.caption)
              .foregroundStyle(.secondary)
            Text("\(points.usablePoints)")
              .font(.title)
              .bold()
          }
          Spacer()
          VStack(alignment: .leading) {
            Text("等级 \(points.levelName)")
            ProgressView(value: points.levelProgress, total: 1)
          }
        }
      } else {
        ProgressView()
      }
    }
    .padding()
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 16))
  }

  private var transactionsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("积分流水").font(.headline)
        Spacer()
        Button("刷新") { Task { await viewModel.fetchTransactions() } }
      }
      ForEach(viewModel.transactions.prefix(5)) { tx in
        HStack {
          VStack(alignment: .leading) {
            Text("\(tx.reason) · \(tx.status)").font(.subheadline)
            Text(tx.description).font(.caption).foregroundStyle(.secondary)
          }
          Spacer()
          Text("\(tx.amount > 0 ? "+" : "")\(tx.amount)")
            .foregroundColor(tx.amount >= 0 ? .green : .red)
        }
        .padding(.vertical, 6)
      }
    }
    .padding()
    .background(Color(uiColor: .systemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 16))
  }

  private var rechargeSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("充值 / 会员").font(.headline)
      NavigationLink {
        PaymentCenterView()
      } label: {
        Label("打开支付页面", systemImage: "creditcard.fill")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)

      if let credential = viewModel.lastCredential {
        CredentialView(credential: credential)
      }
    }
    .padding()
    .background(Color(uiColor: .systemBackground))
    .clipShape(RoundedRectangle(cornerRadius: 16))
  }
}

struct CredentialView: View {
  let credential: PaymentCredential

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("支付凭证").font(.headline)
      Text(credential.display)
      if let url = credential.alipayPage?.pageUrl, let link = URL(string: url) {
        Link("打开支付宝页面", destination: link)
      }
      if let code = credential.wechatNative?.codeUrl,
         let imageURL = URL(string: "https://api.qrserver.com/v1/create-qr-code/?size=200x200&data=\(code)") {
        AsyncImage(url: imageURL) { phase in
          switch phase {
          case .empty: ProgressView()
          case .failure: Text(code).font(.caption)
          case .success(let img): img.resizable().frame(width: 160, height: 160)
          @unknown default: EmptyView()
          }
        }
      }
    }
    .padding()
    .background(.ultraThinMaterial)
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
}
