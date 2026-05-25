import RevenueCat
import SwiftUI

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @EnvironmentObject private var storeService: StoreService
    @State private var selectedPlan: Plan = .yearly
    @State private var animateIcon = false

    enum Plan { case monthly, yearly }

    var body: some View {
        ZStack(alignment: .topTrailing) {
            Color(hex: "03045E").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 18) {
                    if let error = storeService.purchaseError {
                        Text(error)
                            .font(.caption)
                            .padding(10)
                            .frame(maxWidth: .infinity)
                            .background(Color.red.opacity(0.2))
                            .foregroundStyle(.red)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .padding(.horizontal)
                    }

                    Image(systemName: "sailboat.fill")
                        .font(.system(size: 68))
                        .foregroundStyle(Color(hex: "F4A261"))
                        .scaleEffect(animateIcon ? 1.07 : 0.92)
                        .opacity(animateIcon ? 1 : 0.7)
                        .animation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true), value: animateIcon)

                    Text(PaywallCopy.headline)
                        .font(.largeTitle.bold())
                        .tracking(4)
                        .foregroundStyle(.white)
                    Text(PaywallCopy.tagline)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)

                    VStack(spacing: 10) {
                        ForEach(Array(PaywallCopy.features.enumerated()), id: \.offset) { _, item in
                            feature(item.icon, item.title, item.subtitle)
                        }
                    }
                    .padding(.top, 4)

                    if !storeService.hasLoadedProducts && storeService.monthlyPackage == nil && storeService.yearlyPackage == nil {
                        HStack(spacing: 10) {
                            ProgressView().tint(.white)
                            Text(PaywallCopy.loadingPlans)
                                .font(.subheadline)
                                .foregroundStyle(.gray)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                    } else if storeService.monthlyPackage == nil && storeService.yearlyPackage == nil {
                        Text(PaywallCopy.plansUnavailable)
                            .font(.caption)
                            .foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }

                    HStack(spacing: 12) {
                        planCard(
                            title: PaywallCopy.monthlyTitle,
                            price: monthlyPrice,
                            subtitle: PaywallCopy.perMonth,
                            selected: selectedPlan == .monthly,
                            badge: nil
                        )
                        .onTapGesture { selectedPlan = .monthly }

                        planCard(
                            title: PaywallCopy.yearlyTitle,
                            price: yearlyPrice,
                            subtitle: PaywallCopy.perYear,
                            selected: selectedPlan == .yearly,
                            badge: yearlySavingsBadge,
                            monthlyEquivalent: yearlyMonthlyEquivalent
                        )
                        .scaleEffect(1.02)
                        .onTapGesture { selectedPlan = .yearly }
                    }

                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        Task {
                            guard let package = selectedPackage else { return }
                            await storeService.purchase(package: package)
                            if storeService.isPremium { dismiss() }
                        }
                    } label: {
                        HStack {
                            if storeService.isLoading { ProgressView().tint(.white) }
                            Text(storeService.isLoading ? PaywallCopy.ctaLoading : "\(PaywallCopy.ctaSubscribe) • \(selectedPriceText)")
                                .bold()
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.oceanBlue)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(storeService.isLoading || selectedPackage == nil)

                    Button(PaywallCopy.restore) {
                        Task { await storeService.restore() }
                    }
                    .font(.footnote)
                    .foregroundStyle(.gray)

                    Text(PaywallCopy.renewalNotice)
                        .font(.caption2)
                        .foregroundStyle(.gray)
                        .multilineTextAlignment(.center)

                    HStack(spacing: 16) {
                        Button(PaywallCopy.privacy) {
                            if let url = URL(string: "https://sites.google.com/view/pruva-privacy-policy/home") {
                                openURL(url)
                            }
                        }
                        .font(.caption)
                        .foregroundColor(Color(hex: "90E0EF"))

                        Text("·").font(.caption).foregroundColor(.white.opacity(0.3))

                        Button(PaywallCopy.terms) {
                            if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                                openURL(url)
                            }
                        }
                        .font(.caption)
                        .foregroundColor(Color(hex: "90E0EF"))
                    }
                    .padding(.bottom, 8)
                }
                .padding()
            }

            Button {
                dismiss()
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(.white)
                    .padding(10)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
            }
            .accessibilityLabel(PaywallCopy.closeAccessibility)
            .padding()
        }
        .environment(\.locale, PaywallCopy.englishLocale)
        .task {
            animateIcon = true
            await storeService.loadProducts()
        }
    }

    private func feature(_ icon: String, _ title: String, _ subtitle: String) -> some View {
        HStack(alignment: .top) {
            Image(systemName: icon)
                .foregroundStyle(Color(hex: "00B4D8"))
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).bold().foregroundStyle(.white)
                Text(subtitle).font(.caption).foregroundStyle(.gray)
            }
            Spacer()
        }
    }

    private func planCard(
        title: String,
        price: String,
        subtitle: String,
        selected: Bool,
        badge: String?,
        monthlyEquivalent: String? = nil
    ) -> some View {
        VStack(spacing: 6) {
            Text(title).font(.caption.bold()).foregroundStyle(.white)
            if let badge {
                Text(badge)
                    .font(.caption2.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.green)
                    .foregroundStyle(.white)
                    .clipShape(Capsule())
            }
            Text(price).font(.title2.bold()).foregroundStyle(.white)
            Text(subtitle).font(.caption).foregroundStyle(.gray)
            if let monthlyEquivalent {
                Text(monthlyEquivalent).font(.caption2).foregroundStyle(.gray)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color.navyMid.opacity(0.5))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(selected ? Color.oceanBlue : Color.gray.opacity(0.5), lineWidth: selected ? 2 : 1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private var selectedPackage: Package? {
        selectedPlan == .monthly ? storeService.monthlyPackage : storeService.yearlyPackage
    }

    private func priceString(for package: Package?) -> String {
        guard let product = package?.storeProduct else { return "—" }
        return PaywallCopy.formattedPrice(product.price as Decimal) ?? product.localizedPriceString
    }

    private var monthlyPrice: String { priceString(for: storeService.monthlyPackage) }

    private var yearlyPrice: String { priceString(for: storeService.yearlyPackage) }

    private var selectedPriceText: String { priceString(for: selectedPackage) }

    private var yearlySavingsBadge: String? {
        guard let monthly = storeService.monthlyPackage?.storeProduct.price as Decimal?,
              let yearly = storeService.yearlyPackage?.storeProduct.price as Decimal? else { return nil }
        return PaywallCopy.savingsBadge(monthly: monthly, yearly: yearly)
    }

    private var yearlyMonthlyEquivalent: String? {
        guard let yearly = storeService.yearlyPackage?.storeProduct.price as Decimal?,
              let text = PaywallCopy.formattedPrice(yearly / 12) else { return nil }
        return "\(text)\(PaywallCopy.perMonthShort)"
    }
}
