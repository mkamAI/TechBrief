import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(StoreManager.self) private var store

    @State private var showErrorAlert = false

    private let perks: [(String, String, Color)] = [
        ("infinity",          "Unlimited briefs every day",          .blue),
        ("icloud.and.arrow.down", "Save briefs to your library",     .purple),
        ("doc.richtext.fill", "Offline PDF access",                  .green),
        ("bolt.fill",         "Priority generation speed",           .orange),
    ]

    var body: some View {
        VStack(spacing: 0) {
            // ── Handle ────────────────────────────────────────────────────
            Capsule()
                .fill(Color(.separator))
                .frame(width: 36, height: 4)
                .padding(.top, 12)

            ScrollView {
                VStack(spacing: 28) {
                    // ── Crown badge ───────────────────────────────────────
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.accent, Color.accent.opacity(0.7)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        Image(systemName: "crown.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(.white)
                    }
                    .padding(.top, 24)

                    VStack(spacing: 8) {
                        Text("Upgrade to TechBrief Pro")
                            .font(.title2.weight(.black))
                            .multilineTextAlignment(.center)
                        Text("You've hit today's free limit.\nGo Pro for unlimited briefs.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .lineSpacing(3)
                    }

                    // ── Perks ─────────────────────────────────────────────
                    VStack(spacing: 12) {
                        ForEach(perks, id: \.0) { sf, label, color in
                            HStack(spacing: 14) {
                                ZStack {
                                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                                        .fill(color.opacity(0.12))
                                        .frame(width: 34, height: 34)
                                    Image(systemName: sf)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundStyle(color)
                                }
                                Text(label)
                                    .font(.subheadline)
                                Spacer()
                                Image(systemName: "checkmark")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(Color.accent)
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(.horizontal, 20)

                    // ── CTA ───────────────────────────────────────────────
                    VStack(spacing: 12) {
                        Button {
                            Task { await startPurchase() }
                        } label: {
                            ZStack {
                                Text("Start Pro — \(store.proPriceDisplay) / month")
                                    .font(.headline)
                                    .opacity(store.isPurchasing ? 0 : 1)
                                if store.isPurchasing {
                                    ProgressView().tint(.white)
                                }
                            }
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color.accent, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .disabled(store.isPurchasing || store.proProduct == nil)

                        Button("Restore Purchases") {
                            Task { await store.restorePurchases() }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)

                        Button("Maybe later") { dismiss() }
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        Text("Cancel anytime. Billed monthly.")
                            .font(.caption)
                            .foregroundStyle(Color(.tertiaryLabel))
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
                }
            }
        }
        .background(Color(.systemGroupedBackground))
        .onChange(of: store.isPro) { _, isPro in
            if isPro { dismiss() }
        }
        .onChange(of: store.errorMessage) { _, message in
            showErrorAlert = message != nil
        }
        .alert("Something went wrong", isPresented: $showErrorAlert) {
            Button("OK") { store.errorMessage = nil }
        } message: {
            Text(store.errorMessage ?? "")
        }
    }

    private func startPurchase() async {
        let outcome = await store.purchasePro()
        switch outcome {
        case .success:
            dismiss()
        case .pending:
            // Awaiting approval (e.g. Ask to Buy) — nothing more to do here.
            break
        case .userCancelled, .failed:
            break
        }
    }
}

#Preview { PaywallView().environment(StoreManager()) }
