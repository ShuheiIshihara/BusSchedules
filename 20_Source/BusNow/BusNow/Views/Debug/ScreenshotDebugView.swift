import SwiftUI

struct ScreenshotDebugView: View {
    private let scheduleViewModel: BusScheduleViewModel?

    init(scheduleViewModel: BusScheduleViewModel? = nil) {
        self.scheduleViewModel = scheduleViewModel
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 24) {
                if let viewModel = scheduleViewModel {
                    timeControlSection(viewModel: viewModel)
                } else {
                    emptyStateView
                }

                Spacer()
            }
            .padding()
            .navigationTitle("スクリーンショット用設定")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    private func timeControlSection(viewModel: BusScheduleViewModel) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("時刻設定")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 12) {
                HStack(spacing: 12) {
                    Button("朝ラッシュ (8:01)") {
                        viewModel.enableDebugMode()
                        viewModel.setDebugTimeToMorningRush()
                    }
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)

                    Button("夕ラッシュ (18:30)") {
                        viewModel.enableDebugMode()
                        viewModel.setDebugTimeToEveningRush()
                    }
                    .font(.body)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(Color.orange)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }

                Button("リアルタイムに戻す") {
                    viewModel.disableDebugMode()
                }
                .font(.body)
                .foregroundColor(.red)
                .padding(.vertical, 8)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(8)
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera")
                .font(.system(size: 40))
                .foregroundColor(.gray)

            Text("時刻表画面からアクセスしてください")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview {
    ScreenshotDebugView(scheduleViewModel: nil)
}
