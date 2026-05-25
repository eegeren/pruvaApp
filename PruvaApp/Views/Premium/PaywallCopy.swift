import Foundation

enum PaywallCopy {
    static let headline = "PRUVA PRO"
    static let tagline = "The full power of the sea in your pocket"

    static let monthlyTitle = "MONTHLY"
    static let yearlyTitle = "YEARLY"
    static let perMonth = "/month"
    static let perYear = "/year"
    static let perMonthShort = "/mo"

    static let ctaLoading = "Loading..."
    static let ctaSubscribe = "Get Pruva Pro"
    static let restore = "Restore Purchases"
    static let renewalNotice = "Subscription renews automatically. Cancel anytime in App Store settings."
    static let privacy = "Privacy Policy"
    static let terms = "Terms of Service"
    static let closeAccessibility = "Close"

    static let loadingPlans = "Loading subscription options..."
    static let plansUnavailable = "Subscription plans are not available right now. Check your connection and try again."

    static let features: [(icon: String, title: String, subtitle: String)] = [
        ("cloud.sun.fill", "7-Day Weather Forecast", "Waves, wind, and anchorage analysis"),
        ("book.fill", "Voyage Logbook", "Unlimited trip records"),
        ("arrow.down.circle.fill", "Offline Maps", "Navigate without a connection"),
        ("sailboat.fill", "Unlimited Boats", "Manage every vessel you own"),
        ("bell.fill", "Storm Alerts", "Instant warnings in dangerous conditions"),
        ("doc.fill", "Document Reminders", "Insurance and registration expiry alerts"),
    ]

    static let englishLocale = Locale(identifier: "en_US")

    static func formattedPrice(_ amount: Decimal, locale: Locale = englishLocale) -> String? {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = locale
        formatter.maximumFractionDigits = 2
        return formatter.string(from: amount as NSDecimalNumber)
    }

    static func savingsBadge(monthly: Decimal, yearly: Decimal) -> String? {
        guard monthly > 0 else { return nil }
        let annualized = monthly * 12
        guard annualized > yearly else { return nil }
        let savings = (1 - (yearly / annualized)) * 100
        let percent = NSDecimalNumber(decimal: savings).doubleValue
        guard percent >= 1 else { return nil }
        return String(format: "SAVE %.0f%%", locale: englishLocale, percent)
    }
}
