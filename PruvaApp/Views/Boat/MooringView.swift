import SwiftUI
import MapKit

struct MooringView: View {
    @EnvironmentObject var vm: BoatViewModel
    @State private var showingAdd = false

    var body: some View {
        List {
            if let current = vm.moorings.first(where: { $0.isCurrent }) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current").font(.caption).foregroundStyle(.secondary)
                    Text(current.marinaName).bold()
                    if let berth = current.berthNo { Text("Berth: \(berth)").font(.caption) }
                    Map(initialPosition: .region(.init(center: .init(latitude: 36.9, longitude: 28.2), span: .init(latitudeDelta: 0.08, longitudeDelta: 0.08)))) { }
                        .frame(height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }

            if vm.moorings.isEmpty {
                ContentUnavailableView("No mooring logs yet", systemImage: "ferry")
            } else {
                ForEach(vm.moorings) { mooring in
                    VStack(alignment: .leading) {
                        Text(mooring.marinaName)
                        Text(mooring.startDate ?? "No date").font(.caption).foregroundStyle(.secondary)
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
        .sheet(isPresented: $showingAdd) { NavigationStack { AddMooringView() } }
    }
}
