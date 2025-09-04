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
    @State private var selectedStationPair: StationPair?

    var body: some Scene {
        WindowGroup {
            if showStationSelection {
                StationSelectionView { stationPair in
                    selectedStationPair = stationPair
                    showStationSelection = false
                }
            } else if let stationPair = selectedStationPair {
                BusScheduleView(stationPair: stationPair) {
                    showStationSelection = true
                }
            } else {
                ContentView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
            }
        }
    }
}
