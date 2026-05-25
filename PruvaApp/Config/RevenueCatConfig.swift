import Foundation

/// RevenueCat dashboard: Project settings → API keys → Public Apple key (`appl_...`).
/// Set `REVENUECAT_PUBLIC_API_KEY` in the target Info.plist or Xcode build settings.
enum RevenueCatConfig {
    static let publicAPIKey: String = {
        if let key = Bundle.main.object(forInfoDictionaryKey: "REVENUECAT_PUBLIC_API_KEY") as? String,
           !key.isEmpty,
           !key.contains("REPLACE_WITH") {
            return key
        }
        if let env = ProcessInfo.processInfo.environment["REVENUECAT_PUBLIC_API_KEY"],
           !env.isEmpty {
            return env
        }
        return ""
    }()

    /// Must match the entitlement identifier in RevenueCat (e.g. premium).
    static let premiumEntitlementID = "premium"

    static var isConfigured: Bool {
        let key = publicAPIKey
        return key.hasPrefix("appl_") || key.hasPrefix("test_")
    }
}
