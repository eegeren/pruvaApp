import SwiftUI

struct RecentVisitsView: View {
    let anchorageId: String
    @State private var checkins: [Checkin] = []
    @State private var isLoading = false
    @State private var showPaywall = false
    @EnvironmentObject var storeService: StoreService

    var displayedCheckins: [Checkin] {
        storeService.isPremium ? checkins : Array(checkins.prefix(3))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recent Visits")
                .font(.headline)
                .foregroundColor(.white)

            if isLoading {
                ProgressView().tint(.white)
            } else if checkins.isEmpty {
                Text("No visits recorded yet")
                    .foregroundColor(.white.opacity(0.6))
                    .font(.subheadline)
            } else {
                ForEach(displayedCheckins) { checkin in
                    RecentCheckinCard(checkin: checkin)
                }

                if !storeService.isPremium && checkins.count > 3 {
                    PremiumUpsellBanner(
                        text: "See all \(checkins.count) visits with Pro",
                        icon: "clock.fill",
                        showPaywall: $showPaywall
                    )
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView().environmentObject(storeService)
        }
        .onAppear { Task { await load() } }
    }

    func load() async {
        isLoading = true
        checkins = (try? await APIService.shared.fetchCheckins(anchorageId: anchorageId)) ?? []
        isLoading = false
    }
}

struct RecentCheckinCard: View {
    let checkin: Checkin

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(checkin.username ?? "Sailor")
                    .font(.headline)
                    .foregroundColor(.white)
                if let boat = checkin.boatName {
                    Text("· \(boat)")
                        .font(.caption)
                        .foregroundColor(Color(hex: "90E0EF"))
                }
                Spacer()
                Text(checkin.timeAgo)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }

            HStack(spacing: 12) {
                if let depth = checkin.depthObserved {
                    ConditionBadge(icon: "arrow.down.to.line", value: "\(String(format: "%.1f", depth))m", color: Color(hex: "00B4D8"))
                }
                if let wave = checkin.waveHeight {
                    ConditionBadge(icon: "water.waves", value: "\(String(format: "%.1f", wave))m", color: .blue)
                }
                if let wind = checkin.windSpeed {
                    ConditionBadge(icon: "wind", value: "\(Int(wind))kn", color: Color(hex: "90E0EF"))
                }
                if let quality = checkin.bottomQuality {
                    HStack(spacing: 2) {
                        ForEach(1...5, id: \.self) { star in
                            Image(systemName: star <= quality ? "star.fill" : "star")
                                .font(.system(size: 10))
                                .foregroundColor(star <= quality ? Color(hex: "F4A261") : .white.opacity(0.2))
                        }
                    }
                }
            }

            if let note = checkin.note, !note.isEmpty {
                Text(note)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let duration = checkin.durationText {
                Text("Stayed \(duration)")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(14)
        .background(Color(hex: "023E8A"))
        .cornerRadius(14)
    }
}

struct ConditionBadge: View {
    let icon: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10))
                .foregroundColor(color)
            Text(value)
                .font(.caption.bold())
                .foregroundColor(.white)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15))
        .cornerRadius(8)
    }
}
