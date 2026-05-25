import SwiftUI

enum BoatSection: String, CaseIterable {
    case profile = "My Boat"
    case fuel = "Fuel"
    case mooring = "Mooring"
    case maintenance = "Maintenance"
    case voyage = "Voyages"
}

struct BoatTabView: View {
    @EnvironmentObject var vm: BoatViewModel
    @EnvironmentObject var storeService: StoreService
    @State private var section: BoatSection = .profile
    @State private var showAddBoat = false
    @State private var showPaywall = false
    @State private var showDeleteBoatConfirm = false

    private func requestAddBoat() {
        if !storeService.isPremium && !vm.boats.isEmpty {
            showPaywall = true
        } else {
            showAddBoat = true
        }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                if vm.boats.isEmpty {
                    emptyState
                } else {
                    Color.seaBlue.ignoresSafeArea()
                    VStack(spacing: 14) {
                        topHeader
                        boatSelector
                        sectionPicker
                        content
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                    }
                }
            }
            .padding(.top, 10)
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showAddBoat) { NavigationStack { AddBoatView() } }
            .sheet(isPresented: $showPaywall) { PaywallView().environmentObject(storeService) }
            .task { await vm.loadAll() }
            .onChange(of: vm.selectedBoat?.id) { _, _ in
                Task { await vm.loadFuelLogs(); await vm.loadMoorings(); await vm.loadMaintenance(); await vm.loadVoyages() }
            }
            .alert("Delete selected boat?", isPresented: $showDeleteBoatConfirm) {
                Button("Delete", role: .destructive) {
                    Task { await vm.deleteSelectedBoat() }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action removes the boat and related records.")
            }
            .alert("Boat Error", isPresented: Binding(
                get: { vm.errorMessage != nil },
                set: { if !$0 { vm.errorMessage = nil } }
            )) {
                Button("OK") { vm.errorMessage = nil }
            } message: {
                Text(vm.errorMessage ?? "")
            }
            .onAppear {
                configureNavBarAppearance()
            }
        }
    }

    private var emptyState: some View {
        ZStack {
            LinearGradient(
                colors: [Color(hex: "03045E"), Color(hex: "0096C7")],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 32) {
                ZStack {
                    Circle()
                        .fill(Color(hex: "0077B6").opacity(0.2))
                        .frame(width: 160, height: 160)
                    Circle()
                        .fill(Color(hex: "0077B6").opacity(0.15))
                        .frame(width: 200, height: 200)
                    Image(systemName: "sailboat.fill")
                        .font(.system(size: 70))
                        .foregroundColor(Color(hex: "00B4D8"))
                }

                VStack(spacing: 12) {
                    Text("Add Your Boat")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("Track fuel, maintenance, moorings and voyage logs. Keep everything about your boat in one place.")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.7))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }

                VStack(spacing: 10) {
                    featureRow(icon: "fuelpump.fill", label: "Fuel tracking & costs", color: Color(hex: "F4A261"))
                    featureRow(icon: "wrench.and.screwdriver.fill", label: "Maintenance reminders", color: Color(hex: "2EC4B6"))
                    featureRow(icon: "map.fill", label: "Voyage log", color: Color(hex: "00B4D8"))
                    featureRow(icon: "anchor", label: "Mooring history", color: Color(hex: "90E0EF"))
                }
                .padding(.horizontal, 24)

                Button {
                    requestAddBoat()
                } label: {
                    HStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title3)
                        Text("Add My Boat")
                            .font(.headline)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(
                        LinearGradient(
                            colors: [Color(hex: "0077B6"), Color(hex: "00B4D8")],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .foregroundColor(.white)
                    .cornerRadius(16)
                    .shadow(color: Color(hex: "00B4D8").opacity(0.4), radius: 12, y: 6)
                }
                .padding(.horizontal, 24)
            }
        }
    }

    private func featureRow(icon: String, label: String, color: Color) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(color)
                .frame(width: 28)
            Text(label)
                .foregroundColor(.white.opacity(0.9))
                .font(.subheadline)
            Spacer()
            Image(systemName: "checkmark")
                .foregroundColor(color)
                .font(.caption)
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .background(Color(hex: "023E8A").opacity(0.6))
        .cornerRadius(12)
    }

    private func configureNavBarAppearance() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color(hex: "0096C7"))
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }

    private var topHeader: some View {
        HStack {
            Text("My Boat")
                .font(.system(size: 44, weight: .bold))
                .foregroundColor(.white)
            Spacer()
            headerActionButton
        }
        .padding(.horizontal)
    }

    private var boatSelector: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Active Boat")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.white.opacity(0.78))

            HStack {
                Menu {
                    ForEach(vm.boats) { boat in
                        Button(boat.name) { vm.selectedBoat = boat }
                    }
                    if vm.selectedBoat != nil {
                        Divider()
                        Button(role: .destructive) {
                            showDeleteBoatConfirm = true
                        } label: {
                            Label("Delete Selected Boat", systemImage: "trash")
                        }
                    }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "ferry.fill")
                            .foregroundColor(.white.opacity(0.9))
                        Text(vm.selectedBoat?.name ?? "Select boat")
                            .foregroundColor(.white)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundColor(.white.opacity(0.75))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.white.opacity(0.14))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    requestAddBoat()
                } label: {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.oceanAccent)
                        .clipShape(Circle())
                }
            }
        }
        .padding(12)
        .background(Color.seaBlueMid.opacity(0.55))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .padding(.horizontal)
    }

    private var sectionPicker: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(BoatSection.allCases, id: \.self) { s in
                    Button(s.rawValue) { section = s }
                        .font(.subheadline.weight(.semibold))
                        .padding(.horizontal, 14)
                        .padding(.vertical, 9)
                        .background(section == s ? Color.oceanAccent : Color.white.opacity(0.1))
                        .foregroundStyle(.white)
                        .clipShape(Capsule())
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.seaBlueMid.opacity(0.7))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private var content: some View {
        switch section {
        case .profile: BoatProfileView()
        case .fuel: FuelLogView()
        case .mooring: MooringView()
        case .maintenance: MaintenanceView()
        case .voyage: VoyageLogView()
        }
    }

    private var headerActionButton: some View {
        Group {
            if vm.boats.isEmpty || section == .profile {
                Button {
                    requestAddBoat()
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                        Text("Add Boat")
                    }
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.oceanAccent.opacity(0.95))
                    .clipShape(Capsule())
                }
            } else {
                Menu {
                    switch section {
                    case .fuel:
                        NavigationLink(destination: AddFuelLogView()) { Label("Add Fuel Log", systemImage: "plus") }
                    case .mooring:
                        NavigationLink(destination: AddMooringView()) { Label("Add Mooring", systemImage: "plus") }
                    case .maintenance:
                        NavigationLink(destination: AddMaintenanceView()) { Label("Add Maintenance", systemImage: "plus") }
                    case .voyage:
                        NavigationLink(destination: AddVoyageLogView()) { Label("Add Voyage", systemImage: "plus") }
                    case .profile:
                        Button("Add Boat") { requestAddBoat() }
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.subheadline.weight(.bold))
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.oceanAccent.opacity(0.95))
                        .clipShape(Circle())
                }
            }
        }
    }
}
