import SwiftUI

struct AddVoyageLogView: View {
    @EnvironmentObject var vm: BoatViewModel
    @EnvironmentObject var storeService: StoreService
    @Environment(\.dismiss) var dismiss

    @State private var from = ""
    @State private var to = ""
    @State private var distance = ""
    @State private var notes = ""
    @State private var showPaywall = false

    var body: some View {
        Form {
            TextField("Departure", text: $from)
            TextField("Arrival", text: $to)
            TextField("Distance (NM)", text: $distance).keyboardType(.decimalPad)
            TextField("Notes", text: $notes)

            Button("Save") {
                Task {
                    if !storeService.isPremium && vm.voyageLogs.count >= 3 {
                        showPaywall = true
                        return
                    }

                    guard let id = vm.selectedBoat?.id else { return }
                    var params: [String: Any] = ["from_name": from, "to_name": to]
                    if let d = Double(distance) { params["distance_nm"] = d }
                    if !notes.isEmpty { params["notes"] = notes }

                    if let voyage = try? await APIService.shared.createVoyage(params, boatId: id) {
                        vm.voyageLogs.insert(voyage, at: 0)
                    }
                    dismiss()
                }
            }
            .disabled(from.isEmpty || to.isEmpty)
        }
        .navigationTitle("Voyages Add")
        .sheet(isPresented: $showPaywall) { PaywallView().environmentObject(storeService) }
    }
}
