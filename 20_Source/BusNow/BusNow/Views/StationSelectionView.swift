import SwiftUI

struct StationSelectionView: View {
    @StateObject private var viewModel = StationSelectionViewModel()
    @State private var departureStation = ""
    @State private var arrivalStation = ""
    @State private var showingClearAlert = false
    @State private var showingSettings = false
    @State private var isDepartureFieldFocused = false
    @State private var isArrivalFieldFocused = false

    var onStationsPaired: (StationPair) -> Void
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                Button(action: {
                    showingSettings = true
                }) {
                    Image(systemName: "gearshape")
                        .font(.body)
                        .foregroundColor(.blue)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.top, 40)
                .padding(.horizontal, 20)
                
                Text("バス停を入力")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                
                // Station Input Section
                VStack(spacing: 16) {
                    // Departure Station
                    VStack(alignment: .leading, spacing: 8) {
                        Text("出発バス停")
                            .font(.body)
                            .foregroundColor(.primary)

                        VStack(spacing: 0) {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)

                                TextField("野並", text: $departureStation)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .tint(.blue)
                                    .onChange(of: departureStation) { newValue in
                                        viewModel.searchDepartureStations(query: newValue)
                                    }
                                    .onTapGesture {
                                        isDepartureFieldFocused = true
                                        isArrivalFieldFocused = false
                                        if !departureStation.isEmpty {
                                            viewModel.searchDepartureStations(query: departureStation)
                                        }
                                    }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.separator), lineWidth: 0.5)
                            )
                            .cornerRadius(8)

                            // Departure Suggestions List
                            if isDepartureFieldFocused && !viewModel.departureSuggestions.isEmpty {
                                VStack(spacing: 0) {
                                    ForEach(viewModel.departureSuggestions) { busStop in
                                        Button(action: {
                                            departureStation = busStop.stopName
                                            viewModel.clearDepartureSuggestions()
                                            isDepartureFieldFocused = false
                                        }) {
                                            HStack {
                                                Image(systemName: "mappin.circle.fill")
                                                    .foregroundColor(.blue)
                                                    .font(.caption)
                                                Text(busStop.stopName.normalizedForDisplay())
                                                    .foregroundColor(.primary)
                                                    .font(.body)
                                                Spacer()
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(Color(.systemBackground))
                                        }
                                        .buttonStyle(PlainButtonStyle())

                                        if busStop.id != viewModel.departureSuggestions.last?.id {
                                            Divider()
                                                .padding(.leading, 16)
                                        }
                                    }
                                }
                                .background(Color(.systemBackground))
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                .padding(.top, 4)
                            }
                        }
                    }
                    
                    // Station Swap Button
                    Button(action: {
                        viewModel.swapStations(&departureStation, &arrivalStation)
                    }) {
                        Image(systemName: "arrow.up.arrow.down")
                            .font(.title2)
                            .foregroundColor(.blue)
                            .frame(width: 44, height: 44)
                            .background(
                                Circle()
                                    .fill(Color.blue.opacity(0.1))
                                    .overlay(
                                        Circle()
                                            .stroke(Color.blue.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                    .padding(.vertical, 8)
                    
                    // Arrival Station
                    VStack(alignment: .leading, spacing: 8) {
                        Text("到着バス停")
                            .font(.body)
                            .foregroundColor(.primary)

                        VStack(spacing: 0) {
                            HStack {
                                Image(systemName: "location.fill")
                                    .foregroundColor(.gray)
                                    .frame(width: 20)

                                TextField("緑車庫", text: $arrivalStation)
                                    .textFieldStyle(PlainTextFieldStyle())
                                    .tint(.blue)
                                    .onChange(of: arrivalStation) { newValue in
                                        viewModel.searchArrivalStations(query: newValue)
                                    }
                                    .onTapGesture {
                                        isArrivalFieldFocused = true
                                        isDepartureFieldFocused = false
                                        if !arrivalStation.isEmpty {
                                            viewModel.searchArrivalStations(query: arrivalStation)
                                        }
                                    }
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(Color(.systemGray5))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(.separator), lineWidth: 0.5)
                            )
                            .cornerRadius(8)

                            // Arrival Suggestions List
                            if isArrivalFieldFocused && !viewModel.arrivalSuggestions.isEmpty {
                                VStack(spacing: 0) {
                                    ForEach(viewModel.arrivalSuggestions) { busStop in
                                        Button(action: {
                                            arrivalStation = busStop.stopName
                                            viewModel.clearArrivalSuggestions()
                                            isArrivalFieldFocused = false
                                        }) {
                                            HStack {
                                                Image(systemName: "mappin.circle.fill")
                                                    .foregroundColor(.blue)
                                                    .font(.caption)
                                                Text(busStop.stopName.normalizedForDisplay())
                                                    .foregroundColor(.primary)
                                                    .font(.body)
                                                Spacer()
                                            }
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(Color(.systemBackground))
                                        }
                                        .buttonStyle(PlainButtonStyle())

                                        if busStop.id != viewModel.arrivalSuggestions.last?.id {
                                            Divider()
                                                .padding(.leading, 16)
                                        }
                                    }
                                }
                                .background(Color(.systemBackground))
                                .cornerRadius(8)
                                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                                .padding(.top, 4)
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                
                // Search Button
                Button(action: {
                    // 候補リストを閉じる
                    isDepartureFieldFocused = false
                    isArrivalFieldFocused = false
                    viewModel.clearDepartureSuggestions()
                    viewModel.clearArrivalSuggestions()

                    let stationPair = StationPair(departure: departureStation, arrival: arrivalStation)
                    viewModel.saveStationPair(stationPair)
                    onStationsPaired(stationPair)
                }) {
                    Text("検索")
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(8)
                }
                .disabled(departureStation.isEmpty || arrivalStation.isEmpty)
                .padding(.horizontal, 20)
                .padding(.top, 32)
                
                // Search History Section
                if !viewModel.searchHistory.isEmpty {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("検索履歴")
                                .font(.body)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            Button("クリア") {
                                showingClearAlert = true
                            }
                            .font(.body)
                            .foregroundColor(.blue)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 40)
                        
                        List {
                            ForEach(viewModel.searchHistory, id: \.id) { history in
                                Button(action: {
                                    departureStation = history.departureStation
                                    arrivalStation = history.arrivalStation
                                }) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(history.displayName.normalizedForDisplay())
                                                .foregroundColor(.primary)
                                            
                                            Text(formatDate(history.createdAt))
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        Spacer()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                    }
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                }
                                .listRowBackground(Color(.secondarySystemGroupedBackground))
                                .listRowSeparator(.visible, edges: .bottom)
                                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 0, trailing: 0))
                                .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                    Button("削除") {
                                        if let index = viewModel.searchHistory.firstIndex(where: { $0.id == history.id }) {
                                            viewModel.removeHistoryItem(at: index)
                                        }
                                    }
                                    .tint(.red)
                                }
                            }
                        }
                        .listStyle(.plain)
                        .scrollDisabled(true)
                        .frame(height: CGFloat(viewModel.searchHistory.count * 60))
                        .background(Color(.secondarySystemGroupedBackground))
                        .cornerRadius(8)
                        .padding(.horizontal, 20)
                    }
                }
                
                Spacer(minLength: 40)
            }
        }
        .background(Color(.systemGroupedBackground))
        .onTapGesture {
            // 他の場所をタップしたら候補リストを閉じる
            isDepartureFieldFocused = false
            isArrivalFieldFocused = false
        }
        .onAppear {
            loadSavedStations()
        }
        .alert("検索履歴をクリア", isPresented: $showingClearAlert) {
            Button("キャンセル", role: .cancel) { }
            Button("クリア", role: .destructive) {
                viewModel.clearHistory()
            }
        } message: {
            Text("検索履歴を削除しますか？この操作は取り消すことができません。")
        }
        .sheet(isPresented: $showingSettings) {
                    SettingsView(scheduleViewModel: nil)
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
