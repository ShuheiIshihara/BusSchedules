import SwiftUI

struct StationSelectionView: View {
    @StateObject private var viewModel = StationSelectionViewModel()
    @State private var departureStation = ""
    @State private var arrivalStation = ""
    
    var onStationsPaired: (StationPair) -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("出発駅")) {
                    TextField("乗車駅を入力してください", text: $departureStation)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section(header: Text("到着駅")) {
                    TextField("降車駅を入力してください", text: $arrivalStation)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                }
                
                Section {
                    Button(action: {
                        let stationPair = StationPair(departure: departureStation, arrival: arrivalStation)
                        viewModel.saveStationPair(stationPair)
                        onStationsPaired(stationPair)
                    }) {
                        Text("確定")
                            .frame(maxWidth: .infinity)
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(departureStation.isEmpty || arrivalStation.isEmpty)
                }
                
                if !viewModel.searchHistory.isEmpty {
                    Section(header: HStack {
                        Text("検索履歴")
                        Spacer()
                        Button("クリア") {
                            viewModel.clearHistory()
                        }
                        .font(.caption)
                    }) {
                        ForEach(viewModel.searchHistory) { history in
                            Button(action: {
                                departureStation = history.departureStation
                                arrivalStation = history.arrivalStation
                            }) {
                                HStack {
                                    Text(history.displayName)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    Text(formatDate(history.createdAt))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("駅の選択")
            .onAppear {
                loadSavedStations()
            }
        }
    }
    
    private func loadSavedStations() {
        if let savedPair = viewModel.loadSavedStationPair() {
            departureStation = savedPair.departureStation
            arrivalStation = savedPair.arrivalStation
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d HH:mm"
        return formatter.string(from: date)
    }
}