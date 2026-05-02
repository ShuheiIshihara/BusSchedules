//
//  BusNowApp.swift
//  BusNow
//

import SwiftUI

@main
struct BusNowApp: App {
    let persistenceController = PersistenceController.shared
    @State private var showStationSelection = true
    @State private var selectedStationPair: StationPair?
    // iTunes Lookup API で新バージョンが見つかった場合にセットされる
    @State private var updateInfo: AppUpdateInfo?

    var body: some Scene {
        WindowGroup {
            Group {
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
            // 画面表示と同時にバックグラウンドでバージョンチェックを開始
            .task { await checkForUpdate() }
            // updateInfo がセットされると自動でアラートを表示（任意更新）
            .alert(
                "アップデートがあります",
                isPresented: Binding(get: { updateInfo != nil }, set: { if !$0 { updateInfo = nil } }),
                presenting: updateInfo
            ) { info in
                Button("App Storeで更新") {
                    UIApplication.shared.open(info.storeURL)
                }
                // キャンセルでアラートを閉じてそのまま利用継続
                Button("後で", role: .cancel) {}
            } message: { info in
                Text("バージョン \(info.latestVersion) が利用できます。")
            }
        }
    }

    private func checkForUpdate() async {
        // 失敗（圏外・API エラー等）は無視してアプリを正常起動させる
        updateInfo = try? await AppUpdateService.shared.checkForUpdate()
    }
}
