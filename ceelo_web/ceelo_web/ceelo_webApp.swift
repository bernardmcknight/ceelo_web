//
//  ceelo_webApp.swift
//  ceelo_web
//
//  Created by Bishop Mcknight on 11/15/25.
//

import SwiftUI
import CoreData

@main
struct ceelo_webApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
