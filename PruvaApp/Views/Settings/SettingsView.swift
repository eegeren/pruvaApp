import SwiftUI
import UIKit

struct SettingsView: View {
    @EnvironmentObject var authVM: AuthViewModel
    @EnvironmentObject var storeService: StoreService
    @Environment(\.openURL) private var openURL
    @State private var showLogin = false
    @State private var showPaywall = false
    @State private var showProfile = false
    @State private var weatherAlerts = true
    @State private var morningBriefing = true
    @State private var stormWarnings = true
    private let privacyURL = "https://sites.google.com/view/pruva-privacy-policy/home"
    private let termsURL = "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"

    var body: some View {
        ZStack {
            Color(hex: "03045E").ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Settings")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                            Text("Pruva v\(AppVersion.display)")
                                .font(.caption)
                                .foregroundColor(Color(hex: "90E0EF").opacity(0.6))
                        }
                        Spacer()
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 28))
                            .foregroundColor(Color(hex: "0077B6"))
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 20)

                    if authVM.isLoggedIn {
                        HStack(spacing: 16) {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color(hex: "0077B6"), Color(hex: "00B4D8")],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 56, height: 56)
                                Text(String(authVM.user?.username.prefix(1).uppercased() ?? "?"))
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                Text(authVM.user?.username ?? "")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Text(authVM.user?.email ?? "")
                                    .font(.caption)
                                    .foregroundColor(Color(hex: "90E0EF").opacity(0.7))

                                if storeService.isPremium {
                                    HStack(spacing: 4) {
                                        Image(systemName: "crown.fill")
                                            .font(.system(size: 10))
                                        Text("Pruva Pro")
                                            .font(.caption.bold())
                                    }
                                    .foregroundColor(Color(hex: "F4A261"))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 3)
                                    .background(Color(hex: "F4A261").opacity(0.15))
                                    .cornerRadius(8)
                                }
                            }

                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(Color(hex: "90E0EF").opacity(0.4))
                                .font(.caption)
                        }
                        .padding(20)
                        .background(Color(hex: "023E8A"))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color(hex: "0077B6").opacity(0.4), lineWidth: 1)
                        )
                        .padding(.horizontal, 20)
                        .onTapGesture { showProfile = true }
                    } else {
                        VStack(spacing: 16) {
                            HStack(spacing: 14) {
                                ZStack {
                                    Circle()
                                        .fill(Color(hex: "0077B6").opacity(0.2))
                                        .frame(width: 56, height: 56)
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color(hex: "90E0EF"))
                                }
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Not signed in")
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Text("Sign in to sync your data")
                                        .font(.caption)
                                        .foregroundColor(Color(hex: "90E0EF").opacity(0.7))
                                }
                                Spacer()
                            }

                            HStack(spacing: 12) {
                                Button { showLogin = true } label: {
                                    Text("Sign In")
                                        .font(.subheadline.bold())
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color(hex: "0077B6"))
                                        .foregroundColor(.white)
                                        .cornerRadius(12)
                                }
                                Button { showLogin = true } label: {
                                    Text("Sign Up")
                                        .font(.subheadline.bold())
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 12)
                                        .background(Color(hex: "023E8A"))
                                        .foregroundColor(Color(hex: "00B4D8"))
                                        .cornerRadius(12)
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 12)
                                                .stroke(Color(hex: "00B4D8").opacity(0.4), lineWidth: 1)
                                        )
                                }
                            }
                        }
                        .padding(20)
                        .background(Color(hex: "023E8A"))
                        .cornerRadius(20)
                        .padding(.horizontal, 20)
                    }

                    if storeService.isPremium {
                        SettingsSection(title: "Subscription", icon: "crown.fill", iconColor: Color(hex: "F4A261")) {
                            SettingsLinkRow(
                                icon: "creditcard.fill",
                                iconColor: Color(hex: "F4A261"),
                                title: "Manage Subscription",
                                subtitle: "Change or cancel in the App Store"
                            ) {
                                Task { await storeService.openManageSubscriptions() }
                            }
                        }
                        .padding(.horizontal, 20)
                    }

                    if !storeService.isPremium {
                        Button { showPaywall = true } label: {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color(hex: "F4A261").opacity(0.2))
                                            .frame(width: 48, height: 48)
                                        Image(systemName: "crown.fill")
                                            .foregroundColor(Color(hex: "F4A261"))
                                            .font(.system(size: 20))
                                    }

                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Go Pro")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        Text("Captain mode, risk analysis, and smart offline")
                                            .font(.caption)
                                            .foregroundColor(Color(hex: "90E0EF").opacity(0.8))
                                    }

                                    Spacer()

                                    Image(systemName: "chevron.right")
                                        .foregroundColor(Color(hex: "F4A261"))
                                        .font(.subheadline)
                                }
                                .padding(20)
                                .background(
                                    LinearGradient(
                                        colors: [Color(hex: "1a0a00"), Color(hex: "2d1500")],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color(hex: "F4A261").opacity(0.4), lineWidth: 1)
                                )
                            }
                        .padding(.horizontal, 20)
                    }

                    SettingsSection(title: "Notifications", icon: "bell.fill", iconColor: Color(hex: "00B4D8")) {
                        SettingsToggleRow(
                            icon: "cloud.sun.fill",
                            iconColor: Color(hex: "00B4D8"),
                            title: "Morning Briefing",
                            subtitle: "Daily weather summary at 7:00 AM",
                            isOn: $morningBriefing
                        )
                        SettingsDivider()
                        SettingsToggleRow(
                            icon: "bolt.fill",
                            iconColor: .orange,
                            title: "Storm Warnings",
                            subtitle: "Alert when conditions turn dangerous",
                            isOn: $stormWarnings
                        )
                        SettingsDivider()
                        SettingsToggleRow(
                            icon: "anchor",
                            iconColor: Color(hex: "2EC4B6"),
                            title: "Anchor Window",
                            subtitle: "Best time to anchor alerts",
                            isOn: $weatherAlerts
                        )
                    }
                    .padding(.horizontal, 20)

                    SettingsSection(title: "Data & Privacy", icon: "shield.fill", iconColor: Color(hex: "2EC4B6")) {
                        SettingsLinkRow(
                            icon: "location.fill",
                            iconColor: .blue,
                            title: "Location Access",
                            subtitle: "Used for nearby anchorages"
                        ) {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        }
                        SettingsDivider()
                        SettingsLinkRow(
                            icon: "hand.raised.fill",
                            iconColor: Color(hex: "00B4D8"),
                            title: "Privacy Policy",
                            subtitle: nil
                        ) {
                            if let url = URL(string: privacyURL) {
                                openURL(url)
                            }
                        }
                        SettingsDivider()
                        SettingsLinkRow(
                            icon: "doc.text.fill",
                            iconColor: Color(hex: "90E0EF"),
                            title: "Terms of Service",
                            subtitle: nil
                        ) {
                            if let url = URL(string: termsURL) {
                                openURL(url)
                            }
                        }
                    }
                    .padding(.horizontal, 20)

                    SettingsSection(title: "About", icon: "info.circle.fill", iconColor: Color(hex: "90E0EF")) {
                        SettingsInfoRow(title: "Version", value: AppVersion.display)
                        SettingsDivider()
                        SettingsInfoRow(title: "Map Details", value: AppVersion.mapPointDetailsRevision)
                        SettingsDivider()
                        SettingsInfoRow(title: "Data Source", value: "OpenSeaMap & Open-Meteo")
                        SettingsDivider()
                        SettingsLinkRow(
                            icon: "envelope.fill",
                            iconColor: Color(hex: "00B4D8"),
                            title: "Send Feedback",
                            subtitle: nil
                        ) { }
                    }
                    .padding(.horizontal, 20)

                    if authVM.isLoggedIn {
                        Button {
                            authVM.logout()
                        } label: {
                            HStack {
                                Image(systemName: "rectangle.portrait.and.arrow.right")
                                Text("Sign Out")
                                    .font(.subheadline.bold())
                            }
                            .foregroundColor(.red.opacity(0.8))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(Color(hex: "023E8A"))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.red.opacity(0.2), lineWidth: 1)
                            )
                        }
                        .padding(.horizontal, 20)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .sheet(isPresented: $showLogin) {
            LoginView().environmentObject(authVM)
        }
        .sheet(isPresented: $showProfile) {
            ProfileView()
                .environmentObject(authVM)
                .environmentObject(storeService)
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(storeService)
        }
    }
}

struct SettingsSection<Content: View>: View {
    let title: String
    let icon: String
    let iconColor: Color
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.caption.bold())
                    .foregroundColor(iconColor)
                Text(title.uppercased())
                    .font(.caption.bold())
                    .tracking(1.2)
                    .foregroundColor(Color(hex: "90E0EF").opacity(0.7))
            }
            .padding(.leading, 4)

            VStack(spacing: 0) {
                content
            }
            .background(Color(hex: "023E8A"))
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color(hex: "0077B6").opacity(0.2), lineWidth: 1)
            )
        }
    }
}

struct SettingsToggleRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(iconColor.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundColor(iconColor)
                    .font(.system(size: 15))
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(Color(hex: "90E0EF").opacity(0.6))
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .tint(Color(hex: "00B4D8"))
                .labelsHidden()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct SettingsLinkRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String?
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(iconColor.opacity(0.15))
                        .frame(width: 36, height: 36)
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.system(size: 15))
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.subheadline)
                        .foregroundColor(.white)
                    if let subtitle = subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(Color(hex: "90E0EF").opacity(0.6))
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(Color(hex: "90E0EF").opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
        }
    }
}

struct SettingsInfoRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack {
            Text(title)
                .font(.subheadline)
                .foregroundColor(.white)
            Spacer()
            Text(value)
                .font(.caption)
                .foregroundColor(Color(hex: "90E0EF").opacity(0.6))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

struct SettingsDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 1)
            .padding(.leading, 66)
    }
}
