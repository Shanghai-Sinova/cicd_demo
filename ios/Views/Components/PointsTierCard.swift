import SwiftUI

struct PointsTierCard: View {
  let tier: PaymentPointsTier
  let isSelected: Bool
  var onSelect: (() -> Void)?

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Text(tier.tierLabel)
          .font(.headline)
        Spacer()
        Text(tier.priceDisplayCNY)
          .font(.subheadline)
      }
      Text("积分 \(tier.points) · 倍数 x\(String(format: "%.2f", tier.multiplier))")
        .font(.caption)
        .foregroundStyle(.secondary)
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(isSelected ? Color.blue.opacity(0.12) : Color(.secondarySystemBackground))
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(isSelected ? Color.blue : Color.gray.opacity(0.2), lineWidth: 1)
    )
    .clipShape(RoundedRectangle(cornerRadius: 12))
    .onTapGesture { onSelect?() }
  }
}
