import SwiftUI

struct PaymentCenterView: View {
  @EnvironmentObject private var viewModel: UserCenterViewModel

  private var usageSnapshot: TokenUsage {
    TokenUsage(promptTokens: viewModel.desiredTokens, completionTokens: 0, cachedTokens: 0)
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        channelPicker
        planSection
        pointsSection
        estimateSection
        credentialSection
      }
      .padding(20)
    }
    .navigationTitle("支付 / 会员")
    .task { await viewModel.refreshAll() }
    .alert(isPresented: Binding<Bool>(get: { viewModel.errorMessage != nil }, set: { _ in viewModel.errorMessage = nil })) {
      Alert(title: Text("提示"), message: Text(viewModel.errorMessage ?? ""), dismissButton: .default(Text("好的")))
    }
  }

  private var channelPicker: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("支付渠道").font(.headline)
      Picker("支付渠道", selection: $viewModel.selectedChannel) {
        Text("支付宝").tag("alipay_page")
        Text("微信扫码").tag("wechat_native")
      }
      .pickerStyle(.segmented)
    }
  }

  private var planSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("会员套餐").font(.headline)
        Spacer()
        Button("刷新") { Task { await viewModel.fetchPlans() } }
          .font(.caption)
      }
      LazyVStack(spacing: 10) {
        ForEach(viewModel.plans) { plan in
          PaymentPlanCard(plan: plan, isSelected: viewModel.selectedPlan?.planId == plan.planId) {
            viewModel.selectedPlan = plan
            viewModel.selectedPointsTier = nil
            viewModel.desiredTokens = plan.pointsBonus
          }
        }
      }
      Button {
        Task { await viewModel.purchaseSelected() }
      } label: {
        Label("购买会员", systemImage: "creditcard")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .disabled(viewModel.selectedPlan == nil)
    }
  }

  private var pointsSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("积分包").font(.headline)
        Spacer()
        Stepper("预估 Tokens: \(viewModel.desiredTokens)", value: $viewModel.desiredTokens, in: 500...200000, step: 500)
          .labelsHidden()
      }
      LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
        ForEach(viewModel.pointsTiers) { tier in
          PointsTierCard(tier: tier, isSelected: viewModel.selectedPointsTier?.tier == tier.tier) {
            viewModel.selectedPointsTier = tier
            viewModel.selectedPlan = nil
            viewModel.desiredTokens = tier.points
          }
        }
      }
      Button {
        if let tier = viewModel.selectedPointsTier {
          Task { await viewModel.createPointsOrder(tier: tier) }
        }
      } label: {
        Label("购买积分", systemImage: "cart.fill")
          .frame(maxWidth: .infinity)
      }
      .buttonStyle(.borderedProminent)
      .disabled(viewModel.selectedPointsTier == nil)
    }
  }

  private var estimateSection: some View {
    VStack(alignment: .leading, spacing: 10) {
      Text("成本预估").font(.headline)
      TokenUsageStrip(usage: usageSnapshot)
      Text("约需 ¥\(String(format: "%.2f", viewModel.desiredCostCNY))，按千 Tokens ¥0.08 计算。展示为人民币。")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
  }

  private var credentialSection: some View {
    Group {
      if let credential = viewModel.lastCredential {
        CredentialView(credential: credential)
      }
    }
  }
}
