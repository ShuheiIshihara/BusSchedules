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
    @State private var showStationSelection = true

    var body: some Scene {
        WindowGroup {
            if showStationSelection {
                StationSelectionView { stationPair in
                    showStationSelection = false
                }
            } else {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
}
