import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 前文
                Text("本プライバシーポリシーは、神戸電子専門学校（以下「当校」といいます。）が提供する地域密着型の実証実験用 AR スタンプラリーアプリ（以下「本アプリ」といいます。）における個人情報の取扱いについて定めるものです。")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Text("本アプリは神戸市が実施する実証実験の一環として運用され、取得したデータは個人を特定しない形式で神戸市に提供され、地域の賑わい創出・回遊性向上の検証に利用されます。")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Divider()
                
                // 1. 取得する情報
                sectionTitle("1. 取得する情報")
                
                subSectionTitle("登録情報")
                bulletPoint("性別（任意）")
                bulletPoint("年齢層")
                bulletPoint("居住都道府県")
                
                subSectionTitle("利用状況情報")
                bulletPoint("スタンプ取得日時")
                bulletPoint("チェックポイント訪問履歴")
                bulletPoint("AR コンテンツ利用状況")
                bulletPoint("操作ログ")
                
                subSectionTitle("位置情報")
                bulletPoint("GPS による現在地情報（必要時のみ取得）")
                
                subSectionTitle("端末情報")
                bulletPoint("端末モデル")
                bulletPoint("OS バージョン")
                bulletPoint("アプリバージョン")
                bulletPoint("クラッシュ情報")
                bulletPoint("IP アドレス")
                
                subSectionTitle("届出情報（お問い合わせ時）")
                bulletPoint("氏名（必要な場合）")
                bulletPoint("メールアドレス")
                bulletPoint("問い合わせ内容")
                
                Divider()
                
                // 2. 個人情報の利用目的
                sectionTitle("2. 個人情報の利用目的")
                
                subSectionTitle("サービス提供")
                bulletPoint("スタンプラリー機能の提供")
                bulletPoint("本アプリに関する連絡・通知")
                bulletPoint("問い合わせ対応")
                
                subSectionTitle("実証実験の評価")
                bulletPoint("利用状況の統計分析")
                bulletPoint("回遊性分析（匿名統計）")
                bulletPoint("アプリ改善のための参考データ")
                
                subSectionTitle("安全な運営")
                bulletPoint("不正利用の検知")
                bulletPoint("不具合調査・品質向上")
                
                Divider()
                
                // 3. 第三者提供
                sectionTitle("3. 第三者提供")
                
                Text("当校は、取得した情報のうち以下の")
                    .font(.body)
                    .foregroundColor(.secondary)
                + Text("匿名加工された統計データ")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                + Text("を神戸市（実証実験主催者）に提供する場合があります。")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 4) {
                    bulletPoint("利用者数統計")
                    bulletPoint("チェックポイント別訪問状況")
                    bulletPoint("年代層・居住地カテゴリ別傾向")
                    bulletPoint("回遊ルート等の行動解析データ")
                }
                
                Text("提供する情報はすべて匿名加工されており、")
                    .font(.body)
                    .foregroundColor(.secondary)
                + Text("個人を特定することはありません。")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                
                Divider()
                
                // 4. 匿名加工情報の利用
                sectionTitle("4. 匿名加工情報の利用")
                
                Text("当校は取得した情報を匿名加工し、以下の目的で利用します：")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                bulletPoint("地域回遊性・賑わい創出施策の分析")
                bulletPoint("実証実験の評価")
                bulletPoint("アプリの改善・研究")
                
                Divider()
                
                // 5. 安全管理措置
                sectionTitle("5. 安全管理措置")
                
                Text("当校は以下の措置を講じ、個人情報を適切に管理します：")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                bulletPoint("不正アクセス防止")
                bulletPoint("情報漏えい・紛失の防止")
                bulletPoint("アクセス権限管理")
                bulletPoint("委託先への適切な監督（必要な場合）")
                
                Divider()
                
                // 6. 個人情報の開示・訂正・利用停止等
                sectionTitle("6. 個人情報の開示・訂正・利用停止等")
                
                Text("本人からの請求に応じ、保有個人データの開示・訂正・利用停止等について、法令に基づき対応いたします。")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Divider()
                
                // 7. お問い合わせ窓口
                sectionTitle("7. お問い合わせ窓口")
                
                Text("個人情報に関するお問い合わせは以下までご連絡ください：")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("神戸電子専門学校")
                    Text("MAIL: example@example.com")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .padding()
                .cornerRadius(8)
                
                Text("以上")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top)
            }
            .padding()
            .padding(.bottom,80)
        }
        .navigationTitle("プライバシーポリシー")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Helper Views
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.title3)
            .fontWeight(.bold)
            .foregroundColor(.primary)
    }
    
    private func subSectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.headline)
            .fontWeight(.semibold)
            .foregroundColor(.primary)
            .padding(.top, 8)
    }
    
    private func bulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("・")
                .foregroundColor(.secondary)
            Text(text)
                .foregroundColor(.secondary)
        }
        .font(.body)
        .padding(.leading, 8)
    }
}

#Preview {
    NavigationStack {
        PrivacyPolicyView()
    }
}
