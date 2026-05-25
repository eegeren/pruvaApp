import SwiftUI

struct BoatProfileView: View {
    @EnvironmentObject var vm: BoatViewModel

    var body: some View {
        let boat = vm.selectedBoat

        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                ZStack(alignment: .bottomLeading) {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color(hex: "023E8A"), Color(hex: "045C9A")],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(height: 140)
                    HStack {
                        Image(systemName: "ferry.fill")
                            .font(.title)
                            .foregroundStyle(.white)
                            .padding(10)
                            .background(Color.white.opacity(0.15))
                            .clipShape(Circle())
                        VStack(alignment: .leading, spacing: 2) {
                            Text(boat?.name ?? "No boat selected")
                                .font(.headline.weight(.bold))
                                .foregroundStyle(.white)
                            Text(boat?.type ?? "Type not specified")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                    .padding(14)
                }

                HStack(spacing: 10) {
                    stat("Draft", boat?.draftM.map { String(format: "%.1fm", $0) } ?? "-")
                    stat("Fuel", boat?.fuelCapacityL.map { String(format: "%.0fL", $0) } ?? "-")
                }

                HStack(spacing: 10) {
                    stat("Distance", String(format: "%.0f NM", vm.totalDistanceNm))
                    stat("Fuel Cost", String(format: "%.0f TL", vm.totalFuelCost))
                }

                if let current = vm.moorings.first(where: { $0.isCurrent }) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Current Mooring").font(.caption).foregroundStyle(.secondary)
                        Text(current.marinaName).bold()
                        if let berthNo = current.berthNo, !berthNo.isEmpty {
                            Text("Berth: \(berthNo)").font(.caption)
                        }
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                if let upcoming = vm.upcomingMaintenance.first {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Upcoming Maintenance").font(.caption).foregroundStyle(.secondary)
                        Text(upcoming.title).bold()
                        Text(upcoming.nextDueAt ?? "No date").font(.caption)
                    }
                    .padding()
                    .background(.thinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding()
        }
    }

    func stat(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).bold().foregroundStyle(.white)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(Color.white.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
