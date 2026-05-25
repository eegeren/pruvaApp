import Combine
import Foundation
import RevenueCat
import SwiftUI
import UIKit

@MainActor
final class StoreService: ObservableObject {
    static let shared = StoreService()

    @Published var isPremium: Bool = false
    @Published var isLoading: Bool = false
    @Published var purchaseError: String? = nil
    @Published var hasLoadedProducts: Bool = false

    @Published private(set) var monthlyPackage: Package?
    @Published private(set) var yearlyPackage: Package?

    private let productIDs = [
        "com.pruva.premium.monthly",
        "com.pruva.premium.yearly",
    ]

    private var customerInfoTask: Task<Void, Never>?

    private init() {
        configurePurchasesIfNeeded()

        Task {
            await loadProducts()
            await refreshPremiumFromRevenueCat()
        }

        customerInfoTask = Task { @MainActor in
            for await info in Purchases.shared.customerInfoStream {
                self.applyCustomerInfo(info)
            }
        }
    }

    deinit {
        customerInfoTask?.cancel()
    }

    private func configurePurchasesIfNeeded() {
        guard Purchases.isConfigured == false else { return }
        guard RevenueCatConfig.isConfigured else {
            #if DEBUG
            print("RevenueCat: set REVENUECAT_PUBLIC_API_KEY (appl_...) in Info.plist or build settings.")
            #endif
            return
        }
        #if DEBUG
        Purchases.logLevel = .debug
        #endif
        Purchases.configure(withAPIKey: RevenueCatConfig.publicAPIKey)
    }

    func loadProducts() async {
        guard RevenueCatConfig.isConfigured else {
            purchaseError = "Subscriptions are not configured. Add your RevenueCat public API key."
            return
        }

        if hasLoadedProducts, monthlyPackage != nil || yearlyPackage != nil { return }

        do {
            let offerings = try await Purchases.shared.offerings()
            guard let current = offerings.current else {
                purchaseError = "Could not load plans. Set a default offering in RevenueCat."
                return
            }

            monthlyPackage = current.monthly
                ?? current.availablePackages.first { $0.storeProduct.productIdentifier == productIDs[0] }

            yearlyPackage = current.annual
                ?? current.availablePackages.first { $0.storeProduct.productIdentifier == productIDs[1] }

            hasLoadedProducts = true
            purchaseError = nil
        } catch {
            purchaseError = "Could not load products. Please try again."
        }
    }

    func refreshPremiumFromRevenueCat() async {
        guard RevenueCatConfig.isConfigured else {
            isPremium = false
            return
        }
        do {
            let info = try await Purchases.shared.customerInfo()
            applyCustomerInfo(info)
        } catch {
            isPremium = false
        }
    }

    func purchase(package: Package) async {
        isLoading = true
        purchaseError = nil
        defer { isLoading = false }

        do {
            let result = try await Purchases.shared.purchase(package: package)
            if result.userCancelled { return }
            applyCustomerInfo(result.customerInfo)
        } catch {
            purchaseError = "Purchase failed: \(error.localizedDescription)"
        }
    }

    func restore() async {
        isLoading = true
        purchaseError = nil
        defer { isLoading = false }

        do {
            let info = try await Purchases.shared.restorePurchases()
            applyCustomerInfo(info)

            if !isPremium {
                purchaseError = "No active subscription found."
            }
        } catch {
            purchaseError = "Restore failed. Please try again."
        }
    }

    func openManageSubscriptions() async {
        if let url = URL(string: "https://apps.apple.com/account/subscriptions") {
            await UIApplication.shared.open(url)
        } else {
            purchaseError = "Could not open subscription settings."
        }
    }

    private func applyCustomerInfo(_ info: CustomerInfo) {
        isPremium = info.entitlements[RevenueCatConfig.premiumEntitlementID]?.isActive == true
    }
}
