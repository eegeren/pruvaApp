import SwiftUI
import CoreData

@main
struct PruvaApp: App {
    @StateObject private var authViewModel = AuthViewModel()
    @StateObject private var mapViewModel = MapViewModel()
    @StateObject private var boatViewModel = BoatViewModel()
    @StateObject private var storeService = StoreService.shared
    let persistenceController = PersistenceController.shared

    init() {
        URLCache.shared = URLCache(memoryCapacity: 50 * 1024 * 1024, diskCapacity: 500 * 1024 * 1024)
    }

    var body: some Scene {
        WindowGroup {
            SplashView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
                .environmentObject(authViewModel)
                .environmentObject(mapViewModel)
                .environmentObject(boatViewModel)
                .environmentObject(storeService)
        }
    }
}
