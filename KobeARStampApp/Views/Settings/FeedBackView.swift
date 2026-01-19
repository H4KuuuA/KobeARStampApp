import SwiftUI

struct NativeFeedbackView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 60))
                .foregroundColor(.blue)
                .padding(.top, 40)
            
            Text("フィードバック送信")
                .font(.title2)
                .fontWeight(.bold)
            
            Text("アプリの改善にご協力ください。\nGoogleフォームでご意見やご感想をお聞かせください。")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            VStack(spacing: 16) {
                Button {
                    openFeedbackForm()
                } label: {
                    HStack {
                        Image(systemName: "link")
                        Text("フィードバックフォームを開く")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color("DarkBlue"))
                    .cornerRadius(12)
                }
                .padding(.horizontal)
                
                Text("外部のブラウザが開きます")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .navigationTitle("フィードバック送信")
        .navigationBarTitleDisplayMode(.inline)
        .padding(.bottom, 80)
    }
    
    private func openFeedbackForm() {
        let urlString = "https://docs.google.com/forms/d/e/1FAIpQLSejHsNv1yAZpYAH6KlMTKG5QRj7lGpq-abszn3ab5NdbitTVg/viewform"
        
        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        } else {
            print("⚠️ URLの生成に失敗しました")
        }
    }
}

#Preview {
    NavigationStack {
        NativeFeedbackView()
    }
}
