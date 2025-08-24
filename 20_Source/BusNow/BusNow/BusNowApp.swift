//
//  BusNowApp.swift
//  BusNow
//
//  Created by 石原脩平 on 2025/08/25.
//

import SwiftUI

@main
struct BusNowApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
