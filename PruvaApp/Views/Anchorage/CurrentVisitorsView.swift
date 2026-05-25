import SwiftUI

struct CurrentVisitorsView: View {
    let anchorageId: String
    @State private var checkins: [Checkin] = []
    @State private var isLoading = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("At this anchorage now", systemImage: "mappin.circle.fill")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                if !checkins.isEmpty {
                    Text("\(checkins.count) boat\(checkins.count > 1 ? "s" : "")")
                        .font(.caption.bold())
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color(hex: "00B4D8").opacity(0.3))
                        .foregroundColor(Color(hex: "00B4D8"))
                        .cornerRadius(10)
                }
            }

            if isLoading {
                HStack {
                    ProgressView().tint(.white)
                    Text("Loading...")
                        .foregroundColor(.white.opacity(0.6))
                        .font(.caption)
                }
            } else if checkins.isEmpty {
                HStack(spacing: 12) {
                    Image(systemName: "sailboat")
                        .foregroundColor(.white.opacity(0.3))
                        .font(.title2)
                    VStack(alignment: .leading) {
                        Text("No boats checked in yet")
                            .foregroundColor(.white.opacity(0.6))
                            .font(.subheadline)
                        Text("Be the first!")
                            .foregroundColor(Color(hex: "00B4D8"))
                            .font(.caption)
                    }
                }
                .padding()
                .background(Color(hex: "023E8A"))
                .cornerRadius(12)
            } else {
                ForEach(checkins) { checkin in
                    CurrentCheckinRow(checkin: checkin)
                }
            }
        }
        .onAppear { Task { await load() } }
    }

    func load() async {
        isLoading = true
        checkins = (try? await APIService.shared.fetchCurrentCheckins(anchorageId: anchorageId)) ?? []
        isLoading = false
    }
}

struct CurrentCheckinRow: View {
    let checkin: Checkin

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color(hex: "00B4D8").opacity(0.2))
                    .frame(width: 40, height: 40)
                Image(systemName: "sailboat.fill")
                    .foregroundColor(Color(hex: "00B4D8"))
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack {
                    Text(checkin.username ?? "Sailor")
                        .font(.headline)
                        .foregroundColor(.white)
                    if let boat = checkin.boatName {
                        Text("· \(boat)")
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "90E0EF"))
                    }
                }

                HStack(spacing: 8) {
                    Text(checkin.timeAgo)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))

                    if let depth = checkin.depthObserved {
                        Text("⚓ \(String(format: "%.1f", depth))m")
                            .font(.caption)
                            .foregroundColor(Color(hex: "90E0EF"))
                    }

                    if let wave = checkin.waveHeight {
                        Text("🌊 \(String(format: "%.1f", wave))m")
                            .font(.caption)
                            .foregroundColor(Color(hex: "90E0EF"))
                    }
                }

                if let note = checkin.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                        .lineLimit(2)
                }
            }
            Spacer()
        }
        .padding(12)
        .background(Color(hex: "023E8A"))
        .cornerRadius(12)
    }
}
