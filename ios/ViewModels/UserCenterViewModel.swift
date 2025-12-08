import Foundation
import Combine

@MainActor
final class UserCenterViewModel: ObservableObject {
  @Published private(set) var points: PointsBalance?
  @Published private(set) var transactions: [PointsTransaction] = []
  @Published private(set) var plans: [PaymentPlan] = []
  @Published private(set) var pointsTiers: [PaymentPointsTier] = []
  @Published private(set) var isLoading: Bool = false
  @Published var selectedPlan: PaymentPlan?
  @Published var selectedPointsTier: PaymentPointsTier?
  @Published var desiredTokens: Int = 1500
  @Published var selectedChannel: String = "alipay_page"
  @Published var lastCredential: PaymentCredential?
  @Published var errorMessage: String?

  private let apiClient = APIClient.shared

  func refreshAll() async {
    await withTaskGroup(of: Void.self) { group in
      group.addTask { await self.fetchPoints() }
      group.addTask { await self.fetchTransactions() }
      group.addTask { await self.fetchPlans() }
    }
  }

  func fetchPoints() async {
    await requestWrapper { [weak self] in
      guard let self else { return }
      let endpoint = Endpoint(path: "/points/balance")
      let response: APIEnvelope<PointsBalance> = try await self.apiClient.send(endpoint)
      guard let data = response.data else { throw APIClientError.decoding("积分数据为空") }
      self.points = data
    }
  }

  func fetchTransactions() async {
    await requestWrapper { [weak self] in
      guard let self else { return }
      let endpoint = Endpoint(path: "/points/transactions")
      let response: APIEnvelope<PointsTransactionsResponse> = try await self.apiClient.send(endpoint)
      self.transactions = response.data?.transactions ?? []
    }
  }

  func fetchPlans() async {
    await requestWrapper { [weak self] in
      guard let self else { return }
      let endpoint = Endpoint(path: "/payments/plans")
      let response: APIEnvelope<PaymentPlanListResponseDTO> = try await self.apiClient.send(endpoint)
      if let payload = response.data {
        self.plans = payload.plans.map {
          PaymentPlan(
            planId: $0.planId,
            name: $0.name,
            tier: $0.tier,
            tierLabel: $0.tierLabel,
            description: $0.description,
            durationDays: $0.durationDays,
            pointsBonus: $0.pointsBonus,
            amountFormatted: $0.price.amountFormatted,
            currency: $0.price.currency.uppercased(),
            popular: $0.popular,
            badge: $0.badge,
            features: $0.features ?? []
          )
        }
        self.pointsTiers = payload.pointsTiers.map {
          PaymentPointsTier(
            tier: $0.tier,
            tierLabel: $0.tierLabel,
            points: $0.points,
            priceLabel: $0.priceLabel,
            multiplier: $0.multiplier
          )
        }
        self.selectedPlan = self.plans.first
        self.selectedPointsTier = self.pointsTiers.first
        if let defaultTier = self.pointsTiers.first {
          self.desiredTokens = defaultTier.points
        }
      }
    }
  }

  func createOrder(planId: String) async {
    await requestWrapper { [weak self] in
      guard let self else { return }
      let bodyDict: [String: Any] = [
        "plan_id": planId,
        "channel": self.selectedChannel
      ]
      guard let body = bodyDict.toJSONData() else { throw APIClientError.decoding("无效参数") }
      let endpoint = Endpoint(path: "/payments/orders", method: .post, body: body)
      let response: APIEnvelope<CreatePaymentOrderResponse> = try await self.apiClient.send(endpoint)
      guard let payload = response.data else { throw APIClientError.decoding("订单创建失败") }
      self.lastCredential = payload.credential
    }
  }

  func purchaseSelected() async {
    if let plan = selectedPlan {
      await createOrder(planId: plan.planId)
      return
    }
    if let tier = selectedPointsTier {
      await createPointsOrder(tier: tier)
    }
  }

  func createPointsOrder(tier: PaymentPointsTier) async {
    await requestWrapper { [weak self] in
      guard let self else { return }
      let bodyDict: [String: Any] = [
        "points_tier": tier.tier,
        "channel": self.selectedChannel
      ]
      guard let body = bodyDict.toJSONData() else { throw APIClientError.decoding("无效参数") }
      let endpoint = Endpoint(path: "/payments/points", method: .post, body: body)
      let response: APIEnvelope<CreatePaymentOrderResponse> = try await self.apiClient.send(endpoint)
      guard let payload = response.data else { throw APIClientError.decoding("订单创建失败") }
      self.lastCredential = payload.credential
      self.selectedPointsTier = tier
      self.desiredTokens = tier.points
    }
  }

  var desiredCostCNY: Double {
    TokenEstimator.costInCNY(forTokens: desiredTokens)
  }

  private func requestWrapper(_ block: @escaping () async throws -> Void) async {
    isLoading = true
    errorMessage = nil
    defer { isLoading = false }
    do {
      try await block()
    } catch {
      errorMessage = error.localizedDescription
    }
  }
}
