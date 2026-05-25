import SwiftUI

struct VoyageLogView: View {
    @EnvironmentObject var vm: BoatViewModel
    @EnvironmentObject var storeService: StoreService
    @State private var showingAdd = false
    @State private var showPaywall = false
    @State private var privateLogbook = false

    var body: some View {
        VStack {
            Text("Total Cost NM: \(String(format: "%.1f", vm.totalDistanceNm))")
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.seaBlueMid.opacity(0.85))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)

            if !storeService.isPremium && vm.voyageLogs.count >= 3 {
                PremiumUpsellBanner(text: "Go Pro for unlimited voyage history and private logbook", icon: "book.fill", showPaywall: $showPaywall)
                    .padding(.horizontal)
            }

            if storeService.isPremium {
                Toggle("Private Logbook", isOn: $privateLogbook)
                    .tint(.oceanAccent)
                    .padding(.horizontal)
            }

            let visibleLogs = storeService.isPremium ? vm.voyageLogs : Array(vm.voyageLogs.prefix(3))

            if visibleLogs.isEmpty {
                ContentUnavailableView("No voyage logs yet", systemImage: "sailboat")
            } else {
                List(visibleLogs) { v in
                    VStack(alignment: .leading) {
                        Text(privateLogbook ? "Hidden route entry" : "\(v.fromName ?? "-") -> \(v.toName ?? "-")")
                        Text("\(String(format: "%.1f", v.distanceNm ?? 0)) NM").font(.caption)
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .listRowBackground(Color.seaBlueMid.opacity(0.75))
            }
        }
        .background(Color.seaBlue)
        .overlay(alignment: .bottomTrailing) {
            Button {
                if !storeService.isPremium && vm.voyageLogs.count >= 3 {
                    showPaywall = true
                } else {
                    showingAdd = true
                }
            } label: {
                Image(systemName: "plus")
                    .padding()
                    .background(Color.oceanAccent)
                    .foregroundStyle(.white)
                    .clipShape(Circle())
            }
            .padding()
        }
        .sheet(isPresented: $showingAdd) { NavigationStack { AddVoyageLogView() }.environmentObject(storeService) }
        .sheet(isPresented: $showPaywall) { PaywallView().environmentObject(storeService) }
    }
}
