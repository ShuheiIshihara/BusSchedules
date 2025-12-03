import SwiftUI

// タブ種類の列挙型（将来のマップタブ追加に対応）
enum StationSelectionTab: String, CaseIterable {
    case searchHistory = "検索履歴"
    // case map = "マップ" // 将来追加予定

    var displayName: String {
        return rawValue
    }
}

struct StationSelectionView: View {
    @StateObject private var viewModel = StationSelectionViewModel()
    @State private var departureStation = ""
    @State private var arrivalStation = ""
    @State private var showingClearAlert = false
    @State private var showingSettings = false
    @State private var selectedTab: StationSelectionTab = .searchHistory

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
                        
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.gray)
                                .frame(width: 20)
                            
                            TextField("野並", text: $departureStation)
                                .textFieldStyle(PlainTextFieldStyle())
                                .tint(.blue)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.separator), lineWidth: 0.5)
                        )
                        .cornerRadius(8)
                    }
                    
                    // Station Swap Button
                    Button(action: {
                        viewModel.swapStations(&departureStation, &arrivalStation)
                    }) {
                        ZStack {
                            Circle()
                                .fill(Color.blue)
                                .frame(width: 48, height: 48)
                                .shadow(color: Color.blue.opacity(0.3), radius: 4, x: 0, y: 2)

                            Image(systemName: "arrow.up.arrow.down")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                    }
                    .buttonStyle(ScaleButtonStyle())
                    .padding(.vertical, 8)
                    
                    // Arrival Station
                    VStack(alignment: .leading, spacing: 8) {
                        Text("到着バス停")
                            .font(.body)
                            .foregroundColor(.primary)
                        
                        HStack {
                            Image(systemName: "location.fill")
                                .foregroundColor(.gray)
                                .frame(width: 20)
                            
                            TextField("緑車庫", text: $arrivalStation)
                                .textFieldStyle(PlainTextFieldStyle())
                                .tint(.blue)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.separator), lineWidth: 0.5)
                        )
                        .cornerRadius(8)
                    }
                }
                .padding(.horizontal, 20)
                
                // Search Button
                Button(action: {
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

                // セグメントコントロール風タブ
                SegmentedTabView(selectedTab: $selectedTab)
                    .padding(.horizontal, 20)
                    .padding(.top, 32)

                // タブコンテンツ
                switch selectedTab {
                case .searchHistory:
                    searchHistoryContent
                }

                Spacer(minLength: 40)
            }
        }
        .background(Color(.systemGroupedBackground))
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

    // 検索履歴コンテンツ
    @ViewBuilder
    private var searchHistoryContent: some View {
        if viewModel.searchHistory.isEmpty {
            VStack(spacing: 12) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 40))
                    .foregroundColor(.gray)
                Text("検索履歴がありません")
                    .font(.body)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 40)
        } else {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Spacer()

                    Button("クリア") {
                        showingClearAlert = true
                    }
                    .font(.body)
                    .foregroundColor(.blue)
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

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
    }
}

// セグメントコントロール風タブビュー
struct SegmentedTabView: View {
    @Binding var selectedTab: StationSelectionTab

    var body: some View {
        HStack(spacing: 0) {
            ForEach(StationSelectionTab.allCases, id: \.self) { tab in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTab = tab
                    }
                }) {
                    Text(tab.displayName)
                        .font(.body)
                        .fontWeight(selectedTab == tab ? .medium : .regular)
                        .foregroundColor(selectedTab == tab ? .white : .primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(selectedTab == tab ? Color.blue : Color.clear)
                        )
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
        .padding(4)
        .background(Color(.systemGray5))
        .cornerRadius(10)
    }
}

// Custom button style for scale animation feedback
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.92 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
