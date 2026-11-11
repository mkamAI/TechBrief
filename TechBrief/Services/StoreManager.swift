import Foundation
import StoreKit

/// Manages the "TechBrief Pro" subscription: loading the product from StoreKit,
/// driving the purchase flow, and tracking the user's current entitlement.
///
/// Product ID below must match exactly what you create in App Store Connect
/// (Features → Subscriptions). It also must match the product ID in
/// TechBrief.storekit if you're testing locally in the simulator.
@MainActor
@Observable
final class StoreManager {

    // ── Config ─────────────────────────────────────────────────────────────────
    static let proMonthlyID = "com.techbrief.app.pro.monthly"

    // ── State ──────────────────────────────────────────────────────────────────
    private(set) var products: [Product] = []
    private(set) var isPro: Bool = false
    private(set) var isLoadingProducts: Bool = false
    private(set) var isPurchasing: Bool = false
    var errorMessage: String?

    nonisolated(unsafe) private var updateListenerTask: Task<Void, Never>?

    /// The Pro monthly product, once loaded.
    var proProduct: Product? {
        products.first { $0.id == Self.proMonthlyID }
    }

    /// Display price string (e.g. "$4.99"), falling back to a static label
    /// if StoreKit hasn't returned the product yet (offline, not configured, etc).
    var proPriceDisplay: String {
        proProduct?.displayPrice ?? "$4.99"
    }

    init() {
        updateListenerTask = listenForTransactionUpdates()
        Task {
            await loadProducts()
            await refreshEntitlement()
        }
    }

    deinit {
        updateListenerTask?.cancel()
    }

    // ── Loading ────────────────────────────────────────────────────────────────

    func loadProducts() async {
        isLoadingProducts = true
        defer { isLoadingProducts = false }
        do {
            products = try await Product.products(for: [Self.proMonthlyID])
        } catch {
            errorMessage = "Couldn't load subscription info: \(error.localizedDescription)"
        }
    }

    /// Re-derive `isPro` from the current entitlements StoreKit knows about.
    func refreshEntitlement() async {
        var active = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               transaction.productID == Self.proMonthlyID,
               transaction.revocationDate == nil {
                active = true
            }
        }
        isPro = active
    }

    // ── Purchase ───────────────────────────────────────────────────────────────

    enum PurchaseOutcome {
        case success, userCancelled, pending, failed
    }

    @discardableResult
    func purchasePro() async -> PurchaseOutcome {
        guard let product = proProduct else {
            errorMessage = "Subscription isn't available right now. Try again in a moment."
            return .failed
        }

        isPurchasing = true
        defer { isPurchasing = false }

        do {
            let result = try await product.purchase()

            switch result {
            case .success(let verification):
                switch verification {
                case .verified(let transaction):
                    await transaction.finish()
                    await refreshEntitlement()
                    return .success
                case .unverified:
                    errorMessage = "We couldn't verify this purchase. Please try again."
                    return .failed
                }

            case .userCancelled:
                return .userCancelled

            case .pending:
                // e.g. waiting on Ask to Buy / parental approval
                return .pending

            @unknown default:
                return .failed
            }
        } catch {
            errorMessage = error.localizedDescription
            return .failed
        }
    }

    func restorePurchases() async {
        do {
            try await AppStore.sync()
            await refreshEntitlement()
            if !isPro {
                errorMessage = "No previous Pro subscription was found for this Apple ID."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // ── Transaction updates (renewals, refunds, purchases from other devices) ───

    private func listenForTransactionUpdates() -> Task<Void, Never> {
        Task.detached { [weak self] in
            for await result in Transaction.updates {
                guard case .verified(let transaction) = result else { continue }
                await transaction.finish()
                await self?.refreshEntitlement()
            }
        }
    }
}
