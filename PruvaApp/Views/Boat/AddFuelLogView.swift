import SwiftUI

struct AddFuelLogView: View {
    @EnvironmentObject var vm: BoatViewModel
    @Environment(\.dismiss) var dismiss

    @State private var liters = ""
    @State private var pricePerLiter = ""
    @State private var location = ""
    @State private var notes = ""

    var body: some View {
        Form {
            TextField("Liters", text: $liters).keyboardType(.decimalPad)
            TextField("Liters fiyati", text: $pricePerLiter).keyboardType(.decimalPad)
            TextField("Location", text: $location)
            TextField("Notes", text: $notes)

            Button("Save") {
                Task {
                    guard let boatId = vm.selectedBoat?.id, let l = Double(liters) else { return }
                    var params: [String: Any] = ["liters": l]
                    if let p = Double(pricePerLiter) { params["price_per_liter"] = p }
                    if !location.isEmpty { params["location_name"] = location }
                    if !notes.isEmpty { params["notes"] = notes }

                    if let log = try? await APIService.shared.createFuelLog(params, boatId: boatId) {
                        vm.fuelLogs.insert(log, at: 0)
                    }
                    dismiss()
                }
            }
            .disabled(Double(liters) == nil)
        }
        .navigationTitle("Fuel Kaydi")
    }
}
