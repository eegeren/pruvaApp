import SwiftUI

struct MapFilterView: View {
    @EnvironmentObject var mapViewModel: MapViewModel

    var body: some View {
        VStack(spacing: 0) {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white.opacity(0.4))
                .frame(width: 40, height: 4)
                .padding(.top, 12)
                .padding(.bottom, 8)

            Text("Map Filters")
                .font(.title2.bold())
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.bottom, 16)

            Divider().background(Color.white.opacity(0.2))

            ScrollView {
                VStack(spacing: 12) {
                    filterRow(color: .oceanAccent, label: "Anchorages", isOn: $mapViewModel.showAnchorages)
                    filterRow(color: .oceanAccent, label: "Marinas", isOn: $mapViewModel.showMarinas)
                    filterRow(color: .oceanAccent, label: "Fuel Stations", isOn: $mapViewModel.showFuel)
                    filterRow(color: .oceanAccent, label: "Service Points", isOn: $mapViewModel.showService)
                    filterRow(color: .oceanAccent, label: "Dive Sites", isOn: $mapViewModel.showDiving)
                }
                .padding(20)
            }

            HStack(spacing: 12) {
                Button("Show All") {
                    mapViewModel.showAnchorages = true
                    mapViewModel.showMarinas = true
                    mapViewModel.showFuel = true
                    mapViewModel.showService = true
                    mapViewModel.showDiving = true
                }
                .buttonStyle(.borderedProminent)

                Button("Hide All") {
                    mapViewModel.showAnchorages = false
                    mapViewModel.showMarinas = false
                    mapViewModel.showFuel = false
                    mapViewModel.showService = false
                    mapViewModel.showDiving = false
                }
                .buttonStyle(.bordered)
                .tint(.white)
            }
            .padding(20)
        }
        .background(Color.seaBlue.ignoresSafeArea())
    }

    private func filterRow(color: Color, label: String, isOn: Binding<Bool>) -> some View {
        HStack {
            Circle().fill(color).frame(width: 16, height: 16)
            Text(label).foregroundStyle(.white)
            Spacer()
            Toggle("", isOn: isOn).labelsHidden().tint(color)
        }
        .padding()
        .background(Color.seaBlueMid)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
