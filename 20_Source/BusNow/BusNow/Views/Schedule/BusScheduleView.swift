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
            
            Text(viewModel.stationPair.displayName.normalizedForDisplay())
                .fontWeight(.semibold)
                .foregroundColor(.primary)
            
            Text(viewModel.dateString)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(.top, 40)
        .padding(.bottom, 10)
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
        .padding(.bottom, 8)
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
        .padding(.bottom, 8)
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
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(Array(viewModel.busSchedules.enumerated()), id: \.element.departureTime) { index, schedule in
                        BusScheduleRowView(
                            schedule: schedule,
                            isPastTime: viewModel.isPastTime(schedule.departureTime),
                            isNextBus: viewModel.nextBusIndex == index,
                            minutesUntil: viewModel.nextBusIndex == index ? viewModel.minutesUntilNextBus() : nil,
                            currentTime: viewModel.currentTime
                        )
                        .id("schedule_\(index)") // 固定IDに変更してView再生成を防ぐ
                        
                        if index < viewModel.busSchedules.count - 1 {
                            Divider()
                                .padding(.leading, 20)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(8)
                .padding(.horizontal, 20)
                .padding(.bottom, 20) // Direction tabsのスペース確保
            }
            .onChange(of: viewModel.nextBusIndex) { _, newIndex in
                // 次のバスが変わった時に自動スクロール
                if let index = newIndex {
                    withAnimation(.easeInOut(duration: 0.8)) {
                        proxy.scrollTo("schedule_\(index)", anchor: .center)
                    }
                }
            }
            .onAppear {
                // 初回表示時に次のバスにスクロール
                if let index = viewModel.nextBusIndex {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation(.easeInOut(duration: 0.8)) {
                            proxy.scrollTo("schedule_\(index)", anchor: .center)
                        }
                    }
                }
            }
        }
    }
    
    private var directionTabsSection: some View {
        VStack {
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
            .padding(.bottom, 20) // Safe area bottom padding
        }
    }
}

struct BusScheduleRowView: View {
    let schedule: BusScheduleData
    let isPastTime: Bool
    let isNextBus: Bool
    let minutesUntil: Int?
    @State private var isExpanded: Bool = false
    
    // Force view update by making it depend on a changing value
    let currentTime: Date
    
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
                        } else if isNextBus {
                            if let minutes = minutesUntil {
                                Text(minutes == 1 ? "まもなく" : "あと\(minutes)分")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            } else {
                                Text("次のバス")
                                    .font(.caption2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .frame(width: 60, alignment: .leading)
                    
                    // Route and Destination Info
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(schedule.routeName.normalizedForDisplay())
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 2)
                                .background(Color.orange)
                                .cornerRadius(4)
                            
                            Text(schedule.destination.normalizedForDisplay())
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
                            Text("経由するバス停")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Spacer()
                        }
                        .padding(.horizontal, 20)
                        
                        if !schedule.busStops.isEmpty {
                            BusStopsView(busStops: schedule.busStops)
                                .padding(.horizontal, 20)
                        } else {
                            Text("バス停情報がありません")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.horizontal, 20)
                        }
                    }
                    .padding(.bottom, 8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isNextBus ? Color.blue.opacity(0.1) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isNextBus ? Color.blue : Color.clear, lineWidth: isNextBus ? 2 : 0)
        )
        .padding(.horizontal, isNextBus ? 16 : 0)
    }
}

struct BusStopsView: View {
    let busStops: [String]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            ForEach(Array(busStops.enumerated()), id: \.offset) { index, stop in
                HStack(spacing: 8) {
                    // バス停アイコンまたは番号
                    Text("\(index + 1)")
                        .font(.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(.blue)
                        .frame(width: 20, height: 20)
                        .background(
                            Circle()
                                .fill(Color.blue.opacity(0.1))
                        )
                    
                    Text(stop)
                        .font(.caption)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                .padding(.vertical, 2)
                
                // 最後の要素以外は点線を表示
                if index < busStops.count - 1 {
                    HStack {
                        Rectangle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 2, height: 8)
                            .padding(.leading, 9) // アイコンの中心に合わせる
                        
                        Spacer()
                    }
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        BusScheduleView(stationPair: StationPair(departure: "名古屋駅", arrival: "ささしまライブ")) {
            // Preview用の空のコールバック
        }
    }
}
