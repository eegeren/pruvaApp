import SwiftUI

struct AddBoatView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var boatVM: BoatViewModel
    @State private var name = ""
    @State private var type = "Sailboat"
    @State private var lengthM = ""
    @State private var draftM = ""
    @State private var fuelCapacityL = ""
    @State private var engineType = "Diesel"
    @State private var registrationNo = ""
    @State private var isLoading = false

    private let boatTypes = ["Sailboat", "Motorboat", "Gulet", "Catamaran", "RIB", "Other"]
    private let engineTypes = ["Diesel", "Petrol", "Electric", "Sail only"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color(hex: "0096C7").ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        ZStack {
                            Circle()
                                .fill(Color(hex: "0077B6").opacity(0.2))
                                .frame(width: 100, height: 100)
                            Image(systemName: "sailboat.fill")
                                .font(.system(size: 44))
                                .foregroundColor(Color(hex: "00B4D8"))
                        }
                        .padding(.top, 8)

                        FormSection(title: "General", icon: "info.circle.fill") {
                            DarkTextField(placeholder: "Boat Name *", text: $name, icon: "sailboat")
                            DarkPickerField(label: "Type", icon: "list.bullet", selection: $type, options: boatTypes)
                        }

                        FormSection(title: "Dimensions", icon: "ruler.fill") {
                            DarkNumberField(
                                placeholder: "Length (m)",
                                text: $lengthM,
                                icon: "arrow.left.and.right",
                                unit: "m"
                            )
                            DarkNumberField(
                                placeholder: "Draft (m)",
                                text: $draftM,
                                icon: "arrow.down.to.line",
                                unit: "m"
                            )
                        }

                        FormSection(title: "Engine & Fuel", icon: "fuelpump.fill") {
                            DarkPickerField(
                                label: "Engine Type",
                                icon: "engine.combustion",
                                selection: $engineType,
                                options: engineTypes
                            )
                            DarkNumberField(
                                placeholder: "Fuel Capacity",
                                text: $fuelCapacityL,
                                icon: "fuelpump",
                                unit: "L"
                            )
                        }

                        FormSection(title: "Registration", icon: "doc.fill") {
                            DarkTextField(
                                placeholder: "Registration Number",
                                text: $registrationNo,
                                icon: "number"
                            )
                        }

                        Button {
                            Task { await save() }
                        } label: {
                            HStack(spacing: 8) {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Image(systemName: "checkmark.circle.fill")
                                    Text("Save Boat")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .background(
                                Group {
                                    if name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                                        Color.gray
                                    } else {
                                        LinearGradient(
                                            colors: [Color(hex: "0077B6"), Color(hex: "00B4D8")],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    }
                                }
                            )
                            .foregroundColor(.white)
                            .cornerRadius(16)
                            .shadow(
                                color: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .clear : Color(hex: "00B4D8").opacity(0.4),
                                radius: 12, y: 6
                            )
                        }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || isLoading)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationTitle("Add Boat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "00B4D8"))
                }
            }
        }
    }

    private func save() async {
        guard !isLoading else { return }
        isLoading = true
        defer { isLoading = false }

        var params: [String: Any] = [
            "name": name,
            "type": type,
            "engine_type": engineType
        ]
        if let l = Double(lengthM) { params["length_m"] = l }
        if let d = Double(draftM) { params["draft_m"] = d }
        if let f = Double(fuelCapacityL) { params["fuel_capacity_l"] = f }
        if !registrationNo.isEmpty { params["registration_no"] = registrationNo }

        do {
            let boat = try await APIService.shared.createBoat(params)
            await boatVM.loadBoats()
            boatVM.selectedBoat = boat
            dismiss()
        } catch {
            boatVM.errorMessage = "Save boat error: \(error.localizedDescription)"
        }
    }
}

struct FormSection<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundColor(Color(hex: "00B4D8"))
                    .font(.subheadline)
                Text(title.uppercased())
                    .font(.caption.bold())
                    .tracking(1.5)
                    .foregroundColor(Color(hex: "90E0EF"))
            }

            VStack(spacing: 0) {
                content
            }
            .background(Color(hex: "023E8A"))
            .cornerRadius(16)
        }
    }
}

struct DarkTextField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "90E0EF"))
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .tint(Color(hex: "00B4D8"))
        }
        .padding(16)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

struct DarkNumberField: View {
    let placeholder: String
    @Binding var text: String
    let icon: String
    let unit: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "90E0EF"))
                .frame(width: 20)
            TextField(placeholder, text: $text)
                .foregroundColor(.white)
                .keyboardType(.decimalPad)
                .tint(Color(hex: "00B4D8"))
            Spacer()
            Text(unit)
                .font(.caption)
                .foregroundColor(Color(hex: "90E0EF"))
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color(hex: "0077B6").opacity(0.5))
                .cornerRadius(6)
        }
        .padding(16)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}

struct DarkPickerField: View {
    let label: String
    let icon: String
    @Binding var selection: String
    let options: [String]

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(Color(hex: "90E0EF"))
                .frame(width: 20)
            Picker(label, selection: $selection) {
                ForEach(options, id: \.self) { option in
                    Text(option).tag(option)
                }
            }
            .tint(Color(hex: "00B4D8"))
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(16)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1),
            alignment: .bottom
        )
    }
}
