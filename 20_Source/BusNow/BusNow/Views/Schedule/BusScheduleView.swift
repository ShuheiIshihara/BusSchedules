import SwiftUI

struct BusScheduleView: View {
    @StateObject private var viewModel: BusScheduleViewModel
    let onBack: () -> Void
    
    init(stationPair: StationPair, onBack: @escaping () -> Void) {
        self._viewModel = StateObject(wrappedValue: BusScheduleViewModel(stationPair: stationPair))
        self.onBack = onBack
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header Section
            headerSection
            
            // Service Type Tabs (平日/土日祝)
            serviceTypeTabsSection
            
            // Current Time Display
            currentTimeSection
            
            // Bus Schedule List
            scheduleListSection
            
            // Direction Tabs (行き/帰り)
            directionTabsSection
        }
        .background(Color(.systemGroupedBackground))
        .navigationBarHidden(true)
        .refreshable {
            viewModel.refreshSchedules()
        }
    }
    
    private var headerSection: some View {
        VStack(spacing: 8) {
            HStack {
                Button(action: onBack) {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.body)
                        Text("戻る")
                            .font(.body)
                    }
                    .foregroundColor(.blue)
                }
                
                Spacer()
            }
            .padding(.horizontal, 20)
            
            Text(viewModel.stationPair.displayName)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(viewModel.dateString)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 60)
        .padding(.bottom, 20)
    }
    
    private var serviceTypeTabsSection: some View {
        HStack {
            ForEach(BusScheduleViewModel.ServiceType.allCases, id: \.rawValue) { serviceType in
                Button(action: {
                    viewModel.selectServiceType(serviceType)
                }) {
                    Text(serviceType.displayName)
                        .font(.body)
                        .fontWeight(.medium)
                        .foregroundColor(viewModel.selectedServiceType == serviceType ? .white : .blue)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(viewModel.selectedServiceType == serviceType ? Color.blue : Color.clear)
                        )
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    private var currentTimeSection: some View {
        HStack {
            Text("現在時刻")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(viewModel.currentTimeString)
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 16)
    }
    
    private var scheduleListSection: some View {
        Group {
            if viewModel.isLoading {
                loadingView
            } else if let errorMessage = viewModel.errorMessage {
                errorView(message: errorMessage)
            } else if viewModel.busSchedules.isEmpty {
                emptyStateView
            } else {
                scheduleList
            }
        }
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                .scaleEffect(1.2)
            
            Text("時刻表を読み込み中...")
                .font(.body)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
    }
    
    private func errorView(message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 40))
                .foregroundColor(.orange)
            
            Text(message)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
            
            Button("再試行") {
                viewModel.refreshSchedules()
            }
            .foregroundColor(.blue)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "tram")
                .font(.system(size: 40))
                .foregroundColor(.gray)
            
            Text("時刻表が見つかりません")
                .font(.body)
                .foregroundColor(.secondary)
            
            Button("更新") {
                viewModel.refreshSchedules()
            }
            .foregroundColor(.blue)
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 40)
    }
    
    private var scheduleList: some View {
        ScrollView {
            LazyVStack(spacing: 0) {
                ForEach(Array(viewModel.busSchedules.enumerated()), id: \.element.departureTime) { index, schedule in
                    BusScheduleRowView(
                        schedule: schedule,
                        isPastTime: viewModel.isPastTime(schedule.departureTime)
                    )
                    
                    if index < viewModel.busSchedules.count - 1 {
                        Divider()
                            .padding(.leading, 20)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(8)
            .padding(.horizontal, 20)
            .padding(.bottom, 100) // Direction tabsのスペース確保
        }
    }
    
    private var directionTabsSection: some View {
        VStack {
            Spacer()
            
            HStack {
                ForEach(BusScheduleViewModel.Direction.allCases, id: \.rawValue) { direction in
                    Button(action: {
                        viewModel.selectDirection(direction)
                    }) {
                        Text(direction.displayName)
                            .font(.body)
                            .fontWeight(.medium)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                Color.blue.opacity(viewModel.selectedDirection == direction ? 1.0 : 0.6)
                            )
                    }
                }
            }
            .cornerRadius(8)
            .padding(.horizontal, 20)
            .padding(.bottom, 34) // Safe area bottom padding
        }
    }
}

struct BusScheduleRowView: View {
    let schedule: BusScheduleData
    let isPastTime: Bool
    @State private var isExpanded: Bool = false
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                isExpanded.toggle()
            }
        }) {
            VStack(spacing: 0) {
                HStack(alignment: .center, spacing: 12) {
                    // Time Display
                    VStack {
                        Text(schedule.departureTime)
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(isPastTime ? .gray : .primary)
                        
                        if isPastTime {
                            Text("発車済")
                                .font(.caption2)
                                .foregroundColor(.gray)
                        }
                    }
                    .frame(width: 60, alignment: .leading)
                    
                    // Route and Destination Info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(schedule.routeName)
                                .font(.body)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(4)
                            
                            Text(schedule.destination)
                                .font(.body)
                                .foregroundColor(isPastTime ? .gray : .primary)
                                .lineLimit(1)
                        }
                        
                        if !isExpanded {
                            Text("タップして詳細を表示")
                                .font(.caption)
                                .foregroundColor(.blue)
                        }
                    }
                    
                    Spacer()
                    
                    // Platform and Info Button
                    VStack(spacing: 8) {
                        Button(action: {
                            // のりば情報表示処理
                        }) {
                            HStack(spacing: 4) {
                                Image(systemName: "location")
                                    .font(.caption)
                                Text("のりば")
                                    .font(.caption)
                            }
                            .foregroundColor(.blue)
                        }
                        
                        Text(schedule.platform)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                
                if isExpanded {
                    VStack(alignment: .leading, spacing: 8) {
                        Divider()
                            .padding(.horizontal, 20)
                        
                        HStack {
                            Text("詳細情報")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)
                    }
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    NavigationView {
        BusScheduleView(stationPair: StationPair(departure: "名古屋駅", arrival: "ささしまライブ")) {
            // Preview用の空のコールバック
        }
    }
}