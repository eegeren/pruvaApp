import SwiftUI

struct RouteSearchView: View {
    @ObservedObject var routeVM: RouteViewModel
    @ObservedObject var mapVM: MapViewModel
    @State private var searchText = ""
    @Environment(\.dismiss) private var dismiss

    private var filteredResults: [Anchorage] {
        if searchText.isEmpty {
            return Array(mapVM.anchorages.prefix(20))
        }
        return mapVM.anchorages.filter {
            $0.name.localizedCaseInsensitiveContains(searchText)
        }
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.white.opacity(0.6))
                    TextField("Search anchorages...", text: $searchText)
                        .foregroundColor(.white)
                        .autocorrectionDisabled()
                }
                .padding(12)
                .background(Color(hex: "0077B6"))
                .cornerRadius(12)
                .padding()

                List(filteredResults) { anchorage in
                    Button {
                        routeVM.addAnchorage(anchorage)
                        routeVM.isRoutingMode = true
                        dismiss()
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(anchorage.name)
                                    .foregroundColor(.white)
                                    .font(.headline)
                                HStack {
                                    if let depth = anchorage.depth {
                                        Text("⚓ \(String(format: "%.1f", depth))m")
                                            .font(.caption)
                                            .foregroundColor(Color(hex: "90E0EF"))
                                    }
                                    if let bottom = anchorage.bottomType {
                                        Text("• \(bottom.capitalized)")
                                            .font(.caption)
                                            .foregroundColor(Color(hex: "90E0EF"))
                                    }
                                }
                            }
                            Spacer()
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(Color(hex: "00B4D8"))
                        }
                    }
                    .listRowBackground(Color(hex: "0077B6"))
                }
                .listStyle(.plain)
            }
            .background(Color(hex: "0096C7").ignoresSafeArea())
            .navigationTitle("Add Stop")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundColor(Color(hex: "00B4D8"))
                }
            }
        }
    }
}
