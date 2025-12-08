import Foundation

struct RegisterRequest: Encodable {
  let username: String
  let email: String
  let password: String
  let nickname: String?
}

struct PointsBalance: Decodable {
  let userId: String
  let totalPoints: Int
  let usablePoints: Int
  let frozenPoints: Int
  let lifetimeEarned: Int
  let lifetimeSpent: Int
  let level: Int
  let levelName: String
  let nextLevelPoints: Int
  let levelProgress: Double
  let lastUpdated: Date
}

struct PointsTransaction: Decodable, Identifiable {
  let id: String
  let userId: String
  let type: String
  let amount: Int
  let reason: String
  let status: String
  let description: String
  let createdAt: Date
}

struct PaymentPlan: Decodable, Identifiable {
  let planId: String
  let name: String
  let tier: String
  let tierLabel: String
  let description: String
  let durationDays: Int
  let pointsBonus: Int
  let amountFormatted: String
  let currency: String
  let popular: Bool
  let badge: String?
  let features: [String]

  var id: String { planId }

  var displayAmountCNY: String {
    if amountFormatted.contains("¥") || amountFormatted.contains("CNY") {
      return amountFormatted.replacingOccurrences(of: "CNY", with: "¥")
    }
    return "¥\(amountFormatted)"
  }
}

struct PaymentPointsTier: Decodable, Identifiable {
  let tier: String
  let tierLabel: String
  let points: Int
  let priceLabel: String
  let multiplier: Double
  var id: String { tier }

  var priceDisplayCNY: String {
    if priceLabel.contains("¥") || priceLabel.contains("CNY") {
      return priceLabel.replacingOccurrences(of: "CNY", with: "¥")
    }
    return "¥\(priceLabel)"
  }
}

struct PaymentPlanListResponseDTO: Decodable {
  let plans: [PlanDTO]
  let pointsTiers: [TierDTO]

  struct PlanDTO: Decodable {
    let planId: String
    let name: String
    let tier: String
    let tierLabel: String
    let description: String
    let durationDays: Int
    let pointsBonus: Int
    let price: PriceDTO
    let popular: Bool
    let badge: String?
    let features: [String]?
  }

  struct TierDTO: Decodable {
    let tier: String
    let tierLabel: String
    let points: Int
    let priceLabel: String
    let multiplier: Double
  }

  struct PriceDTO: Decodable {
    let amountFormatted: String
    let currency: String
  }
}

struct PaymentOrderView: Decodable {
  let orderNo: String
  let planName: String
  let channel: String
  let status: String
  let pointsBonus: Int
  let amountFormatted: String
}

struct PaymentCredential: Decodable {
  let channel: String
  let display: String
  let alipayPage: AlipayPageCredential?
  let wechatNative: WechatNativeCredential?

  struct AlipayPageCredential: Decodable {
    let pageUrl: String
  }

  struct WechatNativeCredential: Decodable {
    let codeUrl: String
  }
}

struct CreatePaymentOrderResponse: Decodable {
  let order: PaymentOrderView
  let credential: PaymentCredential
}

struct PointsTransactionsResponse: Decodable {
  let transactions: [PointsTransaction]
  let total: Int
}
