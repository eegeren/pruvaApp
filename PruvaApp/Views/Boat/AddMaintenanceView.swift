import SwiftUI

struct AddMaintenanceView: View {
    @EnvironmentObject var vm: BoatViewModel
    @Environment(\.dismiss) var dismiss

    @State private var title = ""
    @State private var category = "motor"
    @State private var cost = ""

    private let categories = ["motor", "hull", "electrical", "sails"]

    var body: some View {
        Form {
            TextField("Title", text: $title)
            Picker("Category", selection: $category) {
                ForEach(categories, id: \.self) { Text($0.capitalized).tag($0) }
            }
            TextField("Cost", text: $cost).keyboardType(.decimalPad)

            Button("Save") {
                Task {
                    guard let id = vm.selectedBoat?.id else { return }
                    var params: [String: Any] = ["title": title, "category": category]
                    if let c = Double(cost) { params["cost"] = c }

                    if let log = try? await APIService.shared.createMaintenance(params, boatId: id) {
                        vm.maintenanceLogs.insert(log, at: 0)
                    }
                    dismiss()
                }
            }
            .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .navigationTitle("Maintenance Add")
    }
}
