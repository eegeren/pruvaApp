//
//  PruvaAppApp.swift
//  PruvaApp
//
//  Created by Ege on 28.04.2026.
//

import SwiftUI
import CoreData

@main
struct PruvaAppApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
