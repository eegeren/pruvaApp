import SwiftUI

struct AddMooringView: View {
    @EnvironmentObject var vm: BoatViewModel
    @Environment(\.dismiss) var dismiss

    @State private var marina = ""
    @State private var pontoon = ""
    @State private var berthNo = ""
    @State private var monthlyFee = ""
    @State private var isCurrent = true

    var body: some View {
        Form {
            TextField("Marina Name", text: $marina)
            TextField("Pontoon", text: $pontoon)
            TextField("Berth", text: $berthNo)
            TextField("Monthly Fee", text: $monthlyFee).keyboardType(.decimalPad)
            Toggle("Currently here", isOn: $isCurrent)

            Button("Save") {
                Task {
                    guard let id = vm.selectedBoat?.id else { return }
                    var params: [String: Any] = ["marina_name": marina, "is_current": isCurrent]
                    if !pontoon.isEmpty { params["pontoon"] = pontoon }
                    if !berthNo.isEmpty { params["berth_no"] = berthNo }
                    if let fee = Double(monthlyFee) { params["monthly_fee"] = fee }

                    if let mooring = try? await APIService.shared.createMooring(params, boatId: id) {
                        vm.moorings.insert(mooring, at: 0)
                    }
                    dismiss()
                }
            }
            .disabled(marina.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .navigationTitle("Mooring Add")
    }
}
