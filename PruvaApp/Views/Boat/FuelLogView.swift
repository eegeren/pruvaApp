import SwiftUI
import Charts

struct FuelLogView: View {
    @EnvironmentObject var vm: BoatViewModel
    @State private var showingAdd = false

    var body: some View {
        VStack(spacing: 10) {
            Text("Total Cost: \(String(format: "%.0f", vm.totalFuelCost)) TL")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.seaBlueMid.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

            if vm.fuelLogs.isEmpty {
                ContentUnavailableView("No fuel logs yet", systemImage: "fuelpump")
            } else {
                Chart(vm.fuelLogs.suffix(10)) {
                    BarMark(x: .value("Date", $0.loggedAt), y: .value("Liters", $0.liters))
                }
                .frame(height: 180)
                .padding(.horizontal)

                List(vm.fuelLogs) { log in
                    VStack(alignment: .leading) {
                        Text(log.locationName ?? "Location not set")
                        Text("\(String(format: "%.1f", log.liters))L").font(.caption).foregroundStyle(.secondary)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .listRowBackground(Color.seaBlueMid.opacity(0.75))
            }
        }
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
        .sheet(isPresented: $showingAdd) { NavigationStack { AddFuelLogView() } }
    }
}
