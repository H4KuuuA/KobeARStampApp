import SwiftUI
import CoreLocation
import AVFoundation

struct SettingsView: View {
    // MARK: - Properties
    @State private var lastSyncDate: Date? = Date()
    @State private var profileImage: UIImage? // ローカル表示用
    @State private var showImagePicker = false
    @AppStorage("pushNotificationEnabled") private var pushNotificationEnabled = true
    @AppStorage("dataCollectionConsent") private var dataCollectionConsent = true
    
    // 追加: @AppStorageで画像データを直接監視
    @AppStorage("profileImageData") private var profileImageData: Data?
    
    var body: some View {
        NavigationStack {
            List {
                // MARK: - アカウント・設定セクション
                Section {
                    // プロフィールアイコン
                    HStack {
                        Spacer()
                        ZStack(alignment: .topTrailing) {
                            // プロフィールアイコン
                            if let image = profileImage {
                                Image(uiImage: image)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: 100, height: 100)
                                    .clipShape(Circle())
                            } else {
                                ZStack {
                                    Circle()
                                        .fill(Color.gray.opacity(0.1))
                                        .frame(width: 100, height: 100)
                                    
                                    Image(systemName: "person.circle.fill")
                                        .resizable()
                                        .scaledToFit()
                                        .frame(width: 100, height: 100)
                                        .foregroundColor(.gray.opacity(0.3))
                                }
                            }
                            
                            // 編集ボタン
                            Button {
                                showImagePicker = true
                            } label: {
                                ZStack {
                                    Circle()
                                        .fill(Color.gray)
                                        .frame(width: 32, height: 32)
                                    
                                    Image(systemName: "pencil")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(.white)
                                }
                            }
                            .offset(x: 0, y: 0)
                        }
                        .padding(.vertical, 16)
                        Spacer()
                    }
                    
                    // ユーザーID
                    HStack {
                        Text("ユーザーID")
                        Spacer()
                        Text("USER_12345678")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    // 最終同期日時
                    HStack {
                        Text("最終同期日時")
                        Spacer()
                        if let date = lastSyncDate {
                            Text(date, style: .relative)
                                .foregroundColor(.secondary)
                                .font(.caption)
                        } else {
                            Text("未同期")
                                .foregroundColor(.secondary)
                                .font(.caption)
                        }
                    }
                    
                    // プッシュ通知設定
                    NavigationLink(destination: PushNotificationSettingView(isEnabled: $pushNotificationEnabled)) {
                        Text("プッシュ通知")
                    }
                    
                    // 位置情報権限
                    NavigationLink(destination: LocationPermissionView()) {
                        Text("位置情報の利用")
                    }
                    
                    // カメラ権限
                    NavigationLink(destination: CameraPermissionView()) {
                        Text("カメラの利用")
                    }
                    
                } header: {
                    Text("アカウント・設定")
                }
                
                // MARK: - 実証実験セクション
                Section {
                    // 行動データ収集の同意
                    NavigationLink(destination: DataCollectionConsentView(isEnabled: $dataCollectionConsent)) {
                        Text("行動データ収集の同意")
                    }
                    
                    // 参加中のイベント（遷移なし）
                    HStack {
                        Text("参加中のイベント")
                        Spacer()
                        Text("春の桜まつり")
                            .foregroundColor(.secondary)
                            .font(.caption)
                    }
                    
                    // フィードバック送信
                    NavigationLink(destination: NativeFeedbackView()) {
                        Text("フィードバック送信")
                    }
                    
                } header: {
                    Text("実証実験")
                }
                
                // MARK: - ヘルプ・サポートセクション
                Section {
                    
                    // 使い方ガイド
                    NavigationLink(destination: UserGuideView()) {
                        Text("使い方ガイド")
                    }
                    
                    // よくある質問
                    NavigationLink(destination: FAQView()) {
                        Text("よくある質問")
                    }
                    
                    // お問い合わせ
                    NavigationLink(destination: ContactView()) {
                        Text("お問い合わせ")
                    }
                    
                } header: {
                    Text("ヘルプ・サポート")
                }
                
                // MARK: - アプリ情報セクション
                Section {
                    // バージョン情報
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    // プライバシーポリシー
                    NavigationLink(destination: PrivacyPolicyView()) {
                        Text("プライバシーポリシー")
                    }
                    
                    // 利用規約
                    NavigationLink(destination: TermsOfServiceView()) {
                        Text("利用規約")
                    }
                    
                } header: {
                    Text("アプリ情報")
                }
                
                // MARK: - データ削除セクション(最下部)
                Section {
                    Button(role: .destructive) {
                        // データ削除処理(確認ダイアログを表示)
                    } label: {
                        HStack {
                            Spacer()
                            Text("データを削除")
                            Spacer()
                        }
                    }
                } footer: {
                    Text("すべてのデータが削除され、復元できません。")
                        .font(.caption)
                        .padding(.bottom, 80)
                }
            }
            .sheet(isPresented: $showImagePicker) {
                ImagePicker(image: $profileImage, onImageSelected: saveImageLocally)
            }
            .onAppear {
                loadImageLocally()
            }
            .onChange(of: profileImageData) { _, newValue in
                // AppStorageの変更を監視してローカルのUIImageを更新
                if let data = newValue, let image = UIImage(data: data) {
                    profileImage = image
                }
            }
        }
    }
    
    // MARK: - Local Storage Methods
    private func saveImageLocally(_ image: UIImage) {
        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        profileImageData = data // AppStorageに保存
    }
    
    private func loadImageLocally() {
        guard let data = profileImageData,
              let image = UIImage(data: data) else { return }
        profileImage = image
    }
}

// MARK: - Push Notification Setting View
struct PushNotificationSettingView: View {
    @Binding var isEnabled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("スタンプラリーを楽しむために役立つ通知（ポイント接近・獲得・イベント情報など）の受信設定です。")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.top)
            
            List {
                Toggle("プッシュ通知", isOn: $isEnabled)
            }
            
            Spacer()
        }
        .navigationTitle("Push通知管理")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Data Collection Consent View
struct DataCollectionConsentView: View {
    @Binding var isEnabled: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("位置情報や滞在時間などの行動データを収集することに同意します。実証実験の改善に役立てられます。")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .padding(.top)
            
            List {
                Toggle("行動データ収集に同意する", isOn: $isEnabled)
            }
            
            Spacer()
        }
        .navigationTitle("行動データ収集の同意")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Location Permission View
struct LocationPermissionView: View {
    @State private var locationStatus: String = "確認中..."
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 現在の設定
            VStack(alignment: .leading, spacing: 8) {
                Text("現在の設定")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 24)
                
                Divider()
                    .padding(.horizontal)
                
                Text(locationStatus)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                
                Divider()
                    .padding(.horizontal)
            }
            
            // 説明文
            VStack(alignment: .leading, spacing: 16) {
                Text("位置情報はスタンプ取得やルート案内などに使用されます。")
                    .font(.body)
                
                Text("許可しない場合、一部機能がご利用いただけない場合がございます。")
                    .font(.body)
                
                Text("取得した位置情報は安全に取り扱い、サービスの目的以外には利用いたしません。")
                    .font(.body)
                
                Text("現在の設定が「常に許可」になっていると、最後にアプリにログインしたときの位置情報を元に、周辺で開催中のスタンプラリー情報等が通知されます。")
                    .font(.body)
            }
            .foregroundColor(.secondary)
            .padding(.horizontal)
            .padding(.top, 24)
            
            Spacer()
            
            // 設定画面へボタン
            Button {
                openAppSettings()
            } label: {
                Text("設定画面へ")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("DarkBlue"))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 88)
        }
        .navigationTitle("位置情報設定")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkLocationPermission()
        }
    }
    
    private func checkLocationPermission() {
        let manager = CLLocationManager()
        let status = manager.authorizationStatus
        
        switch status {
        case .authorizedAlways:
            locationStatus = "常に許可"
        case .authorizedWhenInUse:
            locationStatus = "使用中のみ許可"
        case .denied, .restricted:
            locationStatus = "許可しない"
        case .notDetermined:
            locationStatus = "未設定"
        @unknown default:
            locationStatus = "不明"
        }
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Contact View
struct ContactView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "envelope.fill")
                .font(.system(size: 60))
                .foregroundColor(.gray)
                .padding(.top, 40)
            
            Text("お問い合わせ")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("アプリに関するご質問やご意見がございましたら、\n以下のメールアドレスまでお気軽にお問い合わせください。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("KobeARStampApp 実証実験チーム")
                        .font(.headline)
                    Text("example@example.com")
                        .font(.body)
                        .foregroundColor(.blue)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
                
                Button {
                    openMail()
                } label: {
                    HStack {
                        Image(systemName: "envelope")
                        Text("メールアプリで開く")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("DarkBlue"))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .navigationTitle("お問い合わせ")
        .navigationBarTitleDisplayMode(.inline)
        .padding(.bottom, 80)
    }
    
    private func openMail() {
        let email = "example@example.com"
        let subject = "KobeARStampApp お問い合わせ"
        let body = ""
        
        let urlString = "mailto:\(email)?subject=\(subject.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")&body=\(body.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? "")"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - Camera Permission View
struct CameraPermissionView: View {
    @State private var cameraStatus: String = "確認中..."
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // 現在の設定
            VStack(alignment: .leading, spacing: 8) {
                Text("現在の設定")
                    .font(.headline)
                    .padding(.horizontal)
                    .padding(.top, 24)
                
                Divider()
                    .padding(.horizontal)
                
                Text(cameraStatus)
                    .font(.body)
                    .foregroundColor(.primary)
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                
                Divider()
                    .padding(.horizontal)
            }
            
            // 説明文
            VStack(alignment: .leading, spacing: 16) {
                Text("カメラはAR表示やスタンプ獲得時に使用されます。")
                    .font(.body)
                
                Text("許可しない場合、ARスタンプラリーの機能がご利用いただけない場合がございます。")
                    .font(.body)
                
                Text("撮影した画像は端末内でのみ処理され、サーバーには送信されません。")
                    .font(.body)
            }
            .foregroundColor(.secondary)
            .padding(.horizontal)
            .padding(.top, 24)
            
            Spacer()
            
            // 設定画面へボタン
            Button {
                openAppSettings()
            } label: {
                Text("設定画面へ")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("DarkBlue"))
                    .cornerRadius(12)
            }
            .padding(.horizontal)
            .padding(.bottom, 88)
        }
        .navigationTitle("カメラ設定")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            checkCameraPermission()
        }
    }
    
    private func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        
        switch status {
        case .authorized:
            cameraStatus = "許可"
        case .denied, .restricted:
            cameraStatus = "許可しない"
        case .notDetermined:
            cameraStatus = "未設定"
        @unknown default:
            cameraStatus = "不明"
        }
    }
    
    private func openAppSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
}

// MARK: - ImagePicker
struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) private var dismiss
    let onImageSelected: (UIImage) -> Void
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.delegate = context.coordinator
        picker.sourceType = .photoLibrary
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let image = info[.originalImage] as? UIImage {
                parent.image = image
                parent.onImageSelected(image)
            }
            parent.dismiss()
        }
        
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
            parent.dismiss()
        }
    }
}

// MARK: - Policy Section
struct PolicySection: View {
    let title: String
    let content: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.headline)
                .foregroundColor(.primary)
            
            Text(content)
                .font(.body)
                .foregroundColor(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .background(Color.gray.opacity(0.05))
        .cornerRadius(12)
    }
}

// MARK: - Preview
#Preview {
    SettingsView()
}
