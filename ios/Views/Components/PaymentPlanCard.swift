import SwiftUI

struct PaymentPlanCard: View {
  let plan: PaymentPlan
  let isSelected: Bool
  var onSelect: (() -> Void)?

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          Text(plan.name)
            .font(.headline)
          Text(plan.tierLabel)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        Spacer()
        Text(plan.displayAmountCNY)
          .font(.title3)
          .bold()
      }
      Text(plan.description)
        .font(.caption)
        .foregroundStyle(.secondary)
      if !plan.features.isEmpty {
        LazyVStack(alignment: .leading, spacing: 4) {
          ForEach(plan.features.prefix(3), id: \.self) { feature in
            Label(feature, systemImage: "checkmark.seal")
              .font(.caption)
              .foregroundStyle(.green)
          }
        }
      }
      HStack {
        Label("送积分 \(plan.pointsBonus)", systemImage: "gift.fill")
          .font(.caption)
          .foregroundStyle(.secondary)
        Spacer()
        if plan.popular {
          Text(plan.badge ?? "热门")
            .font(.caption2)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.orange.opacity(0.15))
            .clipShape(Capsule())
        }
      }
    }
    .padding()
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(isSelected ? Color.green.opacity(0.12) : Color(.systemBackground))
    .overlay(
      RoundedRectangle(cornerRadius: 14)
        .stroke(isSelected ? Color.green : Color.gray.opacity(0.2), lineWidth: 1)
    )
    .clipShape(RoundedRectangle(cornerRadius: 14))
    .onTapGesture {
      onSelect?()
    }
  }
}
