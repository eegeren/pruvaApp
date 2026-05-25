import SwiftUI

struct MaintenanceView: View {
    @EnvironmentObject var vm: BoatViewModel
    @State private var showingAdd = false

    var body: some View {
        List {
            Section("Upcoming Maintenance") {
                if vm.upcomingMaintenance.isEmpty {
                    Text("No upcoming maintenance").foregroundStyle(.secondary)
                } else {
                    ForEach(vm.upcomingMaintenance) { item in
                        VStack(alignment: .leading) {
                            Text(icon(item.category) + " " + item.title)
                            Text(item.nextDueAt ?? "No date").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }

            Section("History") {
                if vm.maintenanceLogs.isEmpty {
                    Text("No maintenance logs").foregroundStyle(.secondary)
                } else {
                    ForEach(vm.maintenanceLogs) { item in
                        VStack(alignment: .leading) {
                            Text(icon(item.category) + " " + item.title)
                            Text(item.doneAt).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .listRowBackground(Color.seaBlueMid.opacity(0.75))
        .background(Color.seaBlue)
        .overlay(alignment: .bottomTrailing) {
            Button { showingAdd = true } label: {
                Image(systemName: "plus")
                    .padding()
                    .background(Color.oceanAccent)
                    .foregroundStyle(.white)
                    .clipShape(Circle())
            }
            .padding()
        }
        .sheet(isPresented: $showingAdd) { NavigationStack { AddMaintenanceView() } }
    }

    func icon(_ c: String?) -> String {
        switch c?.lowercased() {
        case "motor": return "⚙️"
        case "hull", "boats": return "⛵"
        case "electrical", "elektrik": return "⚡"
        case "sails", "yelken": return "🔺"
        default: return "•"
        }
    }
}
