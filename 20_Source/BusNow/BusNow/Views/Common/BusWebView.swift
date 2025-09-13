import SwiftUI
import WebKit

struct BusWebView: UIViewRepresentable {
    let url: URL
    @Binding var isLoading: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let webView = WKWebView()
        webView.navigationDelegate = context.coordinator
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        let parent: BusWebView
        
        init(_ parent: BusWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            // 絶え間なく呼ばれているのでここでtrueを設定すろと無限ループに入る
            // parent.isLoading = true
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            parent.isLoading = false
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            parent.isLoading = false
        }
    }
}

struct BusProximityWebView: View {
    let departureStation: String
    let arrivalStation: String
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = false
    
    private var proximityURL: URL? {
        var components = URLComponents(string: "https://www.kotsu.city.nagoya.jp/jp/pc/bus/stand_access.html")
        components?.queryItems = [
            URLQueryItem(name: "name", value: departureStation),
            URLQueryItem(name: "toname", value: arrivalStation)
        ]
        return components?.url
    }
    
    var body: some View {
        NavigationView {
            VStack {
                if let url = proximityURL {
                    ZStack {
                        BusWebView(url: url, isLoading: $isLoading)
                        
                        if isLoading {
                            VStack {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                                    .scaleEffect(1.2)
                                
                                Text("バス接近情報を読み込み中...")
                                    .font(.body)
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(Color(.systemBackground).opacity(0.8))
                        }
                    }
                } else {
                    VStack(spacing: 16) {
                        Image(systemName: "exclamationmark.triangle")
                            .font(.system(size: 40))
                            .foregroundColor(.orange)
                        
                        Text("バス接近情報のURLを構築できませんでした")
                            .font(.body)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("バス接近情報")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("完了") {
                        dismiss()
                    }
                    .foregroundColor(.blue)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .blue))
                            .scaleEffect(0.8)
                    }
                }
            }
        }
    }
}

#Preview {
    BusProximityWebView(
        departureStation: "名古屋駅",
        arrivalStation: "ささしまライブ"
    )
}
