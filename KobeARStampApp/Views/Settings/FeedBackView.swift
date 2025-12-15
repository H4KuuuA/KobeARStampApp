import SwiftUI
import WebKit

// MARK: - Feedback View
struct FeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var showAlert = false
    @State private var alertMessage = ""
    
    // Google FormsのURL（ここに実際のGoogle FormsのURLを設定してください）
    // 例: https://docs.google.com/forms/d/e/YOUR_FORM_ID/viewform?embedded=true
    private let googleFormURL = "https://docs.google.com/forms/d/e/1FAIpQLSdXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX/viewform?embedded=true"
    
    var body: some View {
        NavigationStack {
            ZStack {
                // WebView
                GoogleFormsWebView(
                    urlString: googleFormURL,
                    isLoading: $isLoading
                )
                .ignoresSafeArea(edges: .bottom)
                
                // ローディングインジケーター
                if isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .scaleEffect(1.5)
                        Text("フォームを読み込んでいます...")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                }
            }
            .navigationTitle("フィードバック送信")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("閉じる") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button(action: {
                            // ブラウザで開く
                            if let url = URL(string: googleFormURL.replacingOccurrences(of: "?embedded=true", with: "")) {
                                UIApplication.shared.open(url)
                            }
                        }) {
                            Label("ブラウザで開く", systemImage: "safari")
                        }
                        
                        Button(action: {
                            // URLをコピー
                            UIPasteboard.general.string = googleFormURL
                            alertMessage = "URLをコピーしました"
                            showAlert = true
                        }) {
                            Label("URLをコピー", systemImage: "doc.on.doc")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        .alert("情報", isPresented: $showAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(alertMessage)
        }
    }
}

// MARK: - Google Forms WebView
struct GoogleFormsWebView: UIViewRepresentable {
    let urlString: String
    @Binding var isLoading: Bool
    
    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        
        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator
        webView.scrollView.bounces = true
        webView.isOpaque = false
        webView.backgroundColor = .clear
        
        // モバイル表示を強制
        let userAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"
        webView.customUserAgent = userAgent
        
        // ズームを無効化
        let source = """
        var meta = document.createElement('meta');
        meta.name = 'viewport';
        meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
        document.getElementsByTagName('head')[0].appendChild(meta);
        """
        let script = WKUserScript(source: source, injectionTime: .atDocumentEnd, forMainFrameOnly: true)
        webView.configuration.userContentController.addUserScript(script)
        
        return webView
    }
    
    func updateUIView(_ webView: WKWebView, context: Context) {
        if let url = URL(string: urlString) {
            var request = URLRequest(url: url)
            // モバイルビューをリクエスト
            request.setValue("Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15", forHTTPHeaderField: "User-Agent")
            webView.load(request)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, WKNavigationDelegate {
        var parent: GoogleFormsWebView
        
        init(_ parent: GoogleFormsWebView) {
            self.parent = parent
        }
        
        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // ページの読み込みが完了後、CSSを注入してモバイル最適化
            let css = """
            var style = document.createElement('style');
            style.innerHTML = `
                body { 
                    margin: 0 !important; 
                    padding: 0 !important; 
                }
                .freebirdFormviewerViewFormCard {
                    max-width: 100% !important;
                    margin: 0 !important;
                    padding: 16px !important;
                    box-shadow: none !important;
                }
                .freebirdFormviewerViewItemsItemItem {
                    padding: 12px 0 !important;
                }
            `;
            document.head.appendChild(style);
            """
            
            webView.evaluateJavaScript(css) { _, error in
                if let error = error {
                    print("CSS注入エラー: \(error)")
                }
            }
            
            // ローディング終了
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.parent.isLoading = false
            }
        }
        
        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            // エラー発生時
            self.parent.isLoading = false
        }
    }
}

// MARK: - Alternative: Native Feedback Form
// Google Formsが使えない場合の代替案として、ネイティブフォームも用意
struct NativeFeedbackView: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var feedbackType: FeedbackType = .bug
    @State private var feedbackText: String = ""
    @State private var email: String = ""
    @State private var showAlert = false
    @State private var alertTitle = ""
    @State private var alertMessage = ""
    
    enum FeedbackType: String, CaseIterable {
        case bug = "バグ報告"
        case improvement = "改善提案"
        case feature = "機能要望"
        case other = "その他"
        
        var icon: String {
            switch self {
            case .bug: return "ladybug.fill"
            case .improvement: return "lightbulb.fill"
            case .feature: return "star.fill"
            case .other: return "ellipsis.circle.fill"
            }
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("フィードバックの種類", selection: $feedbackType) {
                        ForEach(FeedbackType.allCases, id: \.self) { type in
                            HStack {
                                Image(systemName: type.icon)
                                Text(type.rawValue)
                            }
                            .tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                } header: {
                    Text("種類")
                }
                
                Section {
                    TextEditor(text: $feedbackText)
                        .frame(minHeight: 150)
                        .overlay(alignment: .topLeading) {
                            if feedbackText.isEmpty {
                                Text("ご意見・ご感想をお聞かせください...")
                                    .foregroundColor(.secondary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                } header: {
                    Text("内容")
                } footer: {
                    Text("具体的な状況や改善案などをお書きください")
                }
                
                Section {
                    TextField("メールアドレス（任意）", text: $email)
                        .keyboardType(.emailAddress)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)
                } header: {
                    Text("連絡先")
                } footer: {
                    Text("返信が必要な場合はご記入ください")
                }
                
                Section {
                    Button(action: sendFeedback) {
                        HStack {
                            Spacer()
                            Text("送信")
                                .fontWeight(.semibold)
                            Spacer()
                        }
                    }
                    .disabled(feedbackText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("フィードバック")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
        .alert(alertTitle, isPresented: $showAlert) {
            Button("OK") {
                if alertTitle == "送信完了" {
                    dismiss()
                }
            }
        } message: {
            Text(alertMessage)
        }
    }
    
    private func sendFeedback() {
        // メールアプリを使って送信
        let subject = "【KobeARStampApp】\(feedbackType.rawValue)"
        var body = """
        フィードバックの種類: \(feedbackType.rawValue)
        
        内容:
        \(feedbackText)
        
        """
        
        if !email.isEmpty {
            body += "\n返信先: \(email)\n"
        }
        
        body += """
        
        ---
        アプリバージョン: 1.0.0
        デバイス: \(UIDevice.current.model)
        iOS: \(UIDevice.current.systemVersion)
        """
        
        let emailAddress = "example@example.com"
        
        if let encodedSubject = subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let encodedBody = body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed),
           let url = URL(string: "mailto:\(emailAddress)?subject=\(encodedSubject)&body=\(encodedBody)") {
            
            if UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url) { success in
                    if success {
                        alertTitle = "送信完了"
                        alertMessage = "メールアプリが開きました。送信を完了してください。"
                    } else {
                        alertTitle = "エラー"
                        alertMessage = "メールアプリを開けませんでした。"
                    }
                    showAlert = true
                }
            } else {
                alertTitle = "エラー"
                alertMessage = "メールアプリが設定されていません。"
                showAlert = true
            }
        }
    }
}

// MARK: - Preview
#Preview("Google Forms") {
    FeedbackView()
}

#Preview("Native Form") {
    NativeFeedbackView()
}
