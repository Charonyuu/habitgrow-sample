import SwiftUI
import StoreKit
import WidgetKit
import Observation

/// One-time "Pro" unlock (non-consumable). Ownership comes from StoreKit's own
/// entitlements, so the same Apple ID gets it back on a new phone via Restore.
@MainActor
@Observable
final class ProStore {
    static let productID = "com.charonyuu.habitgrow.pro"
    static let defaultsKey = "isPro"
    static let freeHabitLimit = 5

    private(set) var isPro: Bool
    private(set) var product: Product?
    private(set) var isWorking = false
    private(set) var isLoadingPrice = false
    var errorMessage: String?

    @ObservationIgnored private var updatesTask: Task<Void, Never>?
    private static var forceProForTesting: Bool {
        #if DEBUG
        return CommandLine.arguments.contains("-forcePro")
        #else
        return false
        #endif
    }
    @ObservationIgnored private let forced = ProStore.forceProForTesting

    init() {
        let forced = Self.forceProForTesting
        if CommandLine.arguments.contains("-resetPro") { L10n.defaults.set(false, forKey: Self.defaultsKey) }
        isPro = forced || L10n.defaults.bool(forKey: Self.defaultsKey)
        if forced { L10n.defaults.set(true, forKey: Self.defaultsKey) }
        updatesTask = Task { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result { await transaction.finish() }
                await self?.refreshEntitlement()
            }
        }
        Task {
            await loadProduct()
            await refreshEntitlement()
        }
    }

    /// Only show the localized price supplied by the current App Store storefront.
    var priceText: String { product?.displayPrice ?? "" }
    var priceStatusText: String {
        isLoadingPrice
            ? tr("載入價格中", "Loading price", ko: "가격 불러오는 중", ja: "価格を読み込み中")
            : tr("價格暫時無法取得", "Price unavailable", ko: "가격을 불러올 수 없어요", ja: "価格を取得できません")
    }

    func loadProduct() async {
        guard !isLoadingPrice else { return }
        isLoadingPrice = true
        defer { isLoadingPrice = false }
        product = try? await Product.products(for: [Self.productID]).first
    }

    func refreshEntitlement() async {
        var owned = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let t) = result, t.productID == Self.productID, t.revocationDate == nil {
                owned = true
            }
        }
        setPro(owned || forced)
    }

    func purchase() async {
        if product == nil { await loadProduct() }
        guard let product else {
            errorMessage = tr("目前無法連線到 App Store", "Can't reach the App Store right now")
            return
        }
        isWorking = true
        defer { isWorking = false }
        do {
            switch try await product.purchase() {
            case .success(let verification):
                if case .verified(let transaction) = verification {
                    await transaction.finish()
                    setPro(true)
                } else {
                    errorMessage = tr("無法驗證這筆購買", "Couldn't verify this purchase")
                }
            case .pending:
                errorMessage = tr("購買正在等待核准", "Purchase is waiting for approval")
            case .userCancelled:
                break
            @unknown default:
                break
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func restore() async {
        isWorking = true
        defer { isWorking = false }
        do { try await AppStore.sync() } catch { errorMessage = error.localizedDescription }
        await refreshEntitlement()
        if !isPro { errorMessage = tr("找不到可以還原的購買", "No purchase found to restore") }
    }

    private func setPro(_ value: Bool) {
        guard value != isPro else { return }
        isPro = value
        L10n.defaults.set(value, forKey: Self.defaultsKey)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
