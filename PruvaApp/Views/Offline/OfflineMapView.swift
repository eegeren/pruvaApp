import SwiftUI

struct OfflineMapView: View {
    @StateObject private var offline = OfflineMapService.shared
    @EnvironmentObject var storeService: StoreService
    @State private var showing = false
    @State private var radius = 10.0
    @State private var name = ""
    @State private var showPaywall = false
    @State private var autoDownloadByRoute = true
    @State private var offlineTracking = true

    var body: some View {
        ZStack {
            List {
                Section("Storage") { ProgressView(value: offline.storageUsage) }
                Section("Downloaded Regions") {
                    ForEach(offline.regions) { r in Text("\(r.name) (\(String(format: "%.0f", r.radiusKm)) km)") }
                }
                if storeService.isPremium {
                    Section("Smart Offline System") {
                        Toggle("Auto-download by route", isOn: $autoDownloadByRoute)
                        Toggle("Offline tracking", isOn: $offlineTracking)
                        Label("Map + weather + route cache enabled", systemImage: "externaldrive.fill.badge.checkmark")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .blur(radius: storeService.isPremium ? 0 : 3)
            .disabled(!storeService.isPremium)

            if !storeService.isPremium {
                VStack(spacing: 12) {
                    Image(systemName: "lock.fill").font(.system(size: 34)).foregroundStyle(.white)
                    Text("Smart offline maps are a Pro feature").foregroundStyle(.white).bold()
                    Button("Go Pro") { showPaywall = true }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 10)
                        .background(Color.oceanAccent)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
                .padding()
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .toolbar {
            Button("Download") {
                if storeService.isPremium { showing = true }
                else { showPaywall = true }
            }
        }
        .sheet(isPresented: $showing) {
            NavigationStack {
                Form {
                    TextField("Region Name", text: $name)
                    Slider(value: $radius, in: 5...100, step: 5)
                    Text("\(String(format: "%.0f", radius)) km")
                    Button("Start") {
                        offline.addRegion(name: name, radiusKm: radius)
                        showing = false
                    }
                }
            }
        }
        .sheet(isPresented: $showPaywall) { PaywallView().environmentObject(storeService) }
    }
}
