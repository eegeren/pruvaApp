import SwiftUI

struct CheckinView: View {
    let anchorage: Anchorage
    @ObservedObject var authVM: AuthViewModel
    @ObservedObject var boatVM: BoatViewModel
    @Environment(\.dismiss) private var dismiss

    @State private var boatName: String = ""
    @State private var note: String = ""
    @State private var depthObserved: String = ""
    @State private var waveHeight: Double = 0.5
    @State private var windSpeed: Double = 10
    @State private var bottomQuality: Int = 3
    @State private var isLoading = false
    @State private var error: String? = nil

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    VStack(spacing: 4) {
                        Image(systemName: "mappin.and.ellipse")
                            .font(.system(size: 40))
                            .foregroundColor(Color(hex: "00B4D8"))
                        Text("Check In")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        Text(anchorage.name)
                            .font(.subheadline)
                            .foregroundColor(Color(hex: "90E0EF"))
                    }
                    .padding(.top)

                    inputSection

                    if let error {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.caption)
                            .padding(.horizontal)
                    }

                    Button {
                        Task { await submit() }
                    } label: {
                        HStack {
                            if isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Image(systemName: "mappin.and.ellipse")
                                Text("Check In ⚓").bold()
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(hex: "00B4D8"))
                        .foregroundColor(.white)
                        .cornerRadius(14)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal)
                    .padding(.bottom, 30)
                }
            }
            .background(Color(hex: "0096C7").ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(Color(hex: "00B4D8"))
                }
            }
            .onAppear {
                if boatName.isEmpty { boatName = boatVM.selectedBoat?.name ?? "" }
            }
        }
    }

    private var inputSection: some View {
        VStack(spacing: 16) {
            fieldCard(label: "Boat Name", icon: "sailboat.fill") {
                TextField("Your boat name...", text: $boatName)
                    .foregroundColor(.white)
                    .padding(12)
                    .background(Color(hex: "0077B6"))
                    .cornerRadius(10)
            }

            fieldCard(label: "Note", icon: "note.text") {
                TextField("How's the anchorage? Any tips?", text: $note, axis: .vertical)
                    .foregroundColor(.white)
                    .lineLimit(3...6)
                    .padding(12)
                    .background(Color(hex: "0077B6"))
                    .cornerRadius(10)
            }

            fieldCard(label: "Depth Observed", icon: "arrow.down.to.line") {
                HStack {
                    TextField("0.0", text: $depthObserved)
                        .foregroundColor(.white)
                        .keyboardType(.decimalPad)
                        .padding(12)
                        .background(Color(hex: "0077B6"))
                        .cornerRadius(10)
                    Text("meters")
                        .foregroundColor(Color(hex: "90E0EF"))
                }
            }

            fieldCard(label: "Wave Height", icon: "water.waves") {
                VStack(spacing: 8) {
                    HStack {
                        Spacer()
                        Text(String(format: "%.1fm", waveHeight))
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    }
                    Slider(value: $waveHeight, in: 0...4, step: 0.1)
                        .tint(waveColor)
                }
            }

            fieldCard(label: "Wind Speed", icon: "wind") {
                VStack(spacing: 8) {
                    HStack {
                        Spacer()
                        Text("\(Int(windSpeed)) kn")
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    }
                    Slider(value: $windSpeed, in: 0...50, step: 1)
                        .tint(Color(hex: "00B4D8"))
                }
            }

            fieldCard(label: "Anchor Holding", icon: "ferry.fill") {
                HStack(spacing: 8) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= bottomQuality ? "star.fill" : "star")
                            .foregroundColor(star <= bottomQuality ? Color(hex: "F4A261") : .white.opacity(0.3))
                            .font(.title2)
                            .onTapGesture { bottomQuality = star }
                    }
                    Spacer()
                    Text(holdingLabel)
                        .font(.caption)
                        .foregroundColor(Color(hex: "90E0EF"))
                }
            }
        }
        .padding(.horizontal)
    }

    private func fieldCard<Content: View>(label: String, icon: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(label, systemImage: icon)
                .font(.caption)
                .foregroundColor(Color(hex: "90E0EF"))
            content()
        }
    }

    var waveColor: Color {
        if waveHeight < 0.5 { return .green }
        if waveHeight < 1.5 { return .orange }
        return .red
    }

    var holdingLabel: String {
        switch bottomQuality {
        case 1: return "Poor"
        case 2: return "Fair"
        case 3: return "Good"
        case 4: return "Very Good"
        case 5: return "Excellent"
        default: return ""
        }
    }

    func submit() async {
        isLoading = true
        error = nil
        defer { isLoading = false }
        do {
            var params: [String: Any] = [
                "wave_height": waveHeight,
                "wind_speed": windSpeed,
                "bottom_quality": bottomQuality
            ]
            if !boatName.isEmpty { params["boat_name"] = boatName }
            if !note.isEmpty { params["note"] = note }
            if let d = Double(depthObserved) { params["depth_observed"] = d }

            _ = try await APIService.shared.createCheckin(params, anchorageId: anchorage.id)
            dismiss()
        } catch {
            self.error = "Check in failed. Please try again."
        }
    }
}
