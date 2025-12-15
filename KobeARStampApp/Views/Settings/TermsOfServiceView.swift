import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // 前文
                Text("本利用規約（以下「本規約」といいます。）は、KobeARStampApp 実証実験（以下「本実証実験」といいます。）において、〇〇運営事務局（以下「当事務局」）が提供する地域体験型 AR アプリケーションサービス（以下「本サービス」といいます。）の利用条件について定めるものです。本サービスを利用することにより、利用者は本規約に同意したものとみなします。")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Divider()
                
                // 1. 用語の定義
                sectionTitle("1. 用語の定義")
                
                bulletPoint("匿名アカウント：利用登録時に発行される匿名の識別 ID をいいます。")
                bulletPoint("スタンプ情報：GPS によるスタンプ取得位置・日時等の情報をいいます。")
                bulletPoint("端末情報：OS、端末モデル、IP アドレス、利用ログ等をいいます。")
                bulletPoint("匿名化データ：個人を特定できない形式に加工した統計データをいいます。")
                
                Divider()
                
                // 2. 本サービスの内容
                sectionTitle("2. 本サービスの内容")
                
                numberedPoint("1", "本サービスは、神戸地域における観光回遊促進を目的とした AR スタンプラリーの実証実験です。")
                numberedPoint("2", "実証実験の内容・期間は予告なく変更される場合があります。")
                numberedPoint("3", "クーポンや金銭的報酬等は提供しません。")
                
                Divider()
                
                // 3. 個人情報の取扱い
                sectionTitle("3. 個人情報の取扱い")
                
                Text("本サービスにおける個人情報の取得・利用・管理等の詳細については、別途定める")
                    .font(.body)
                    .foregroundColor(.secondary)
                + Text("「プライバシーポリシー」")
                    .font(.body)
                    .fontWeight(.bold)
                    .foregroundColor(.secondary)
                + Text("をご確認ください。")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Divider()
                
                // 4. 禁止事項
                sectionTitle("4. 禁止事項")
                
                Text("利用者は以下の行為を行ってはなりません。")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(.bottom, 8)
                
                bulletPoint("本サービスの不正利用")
                bulletPoint("GPS の偽装等の行為")
                bulletPoint("サーバーに過度な負荷を与える行為")
                bulletPoint("法令または公序良俗に反する行為")
                bulletPoint("その他、当事務局が不適切と判断する行為")
                
                Divider()
                
                // 5. サービスの停止・変更
                sectionTitle("5. サービスの停止・変更")
                
                numberedPoint("1", "当事務局は、以下の場合にサービスの全部または一部を停止・中断することがあります。")
                
                VStack(alignment: .leading, spacing: 4) {
                    subBulletPoint("システムの保守・点検")
                    subBulletPoint("システム障害の発生")
                    subBulletPoint("天災・事変等の不可抗力")
                    subBulletPoint("その他、運営上必要と判断した場合")
                }
                .padding(.leading, 8)
                
                numberedPoint("2", "当事務局は、サービス内容を予告なく変更することがあります。")
                numberedPoint("3", "これらにより利用者に発生した損害について当事務局は責任を負いません。")
                
                Divider()
                
                // 6. 免責事項
                sectionTitle("6. 免責事項")
                
                numberedPoint("1", "本サービスは実証実験であり、データ消失・仕様変更が発生する可能性があります。")
                numberedPoint("2", "AR 表示や GPS 精度による誤差について当事務局は責任を負いません。")
                numberedPoint("3", "利用者の端末・通信環境による不具合について当事務局は責任を負いません。")
                numberedPoint("4", "本サービスの利用により生じた損害について、当事務局は一切の責任を負いません。")
                
                Divider()
                
                // 7. 知的財産権
                sectionTitle("7. 知的財産権")
                
                Text("本サービスに関する一切の知的財産権は当事務局または正当な権利者に帰属します。利用者は本サービスの利用許諾を受けるものであり、知的財産権の譲渡を受けるものではありません。")
                    .font(.body)
                    .foregroundColor(.secondary)
                
                Divider()
                
                // 8. 規約の改定
                sectionTitle("8. 規約の改定")
                
                numberedPoint("1", "当事務局は、必要に応じて本規約を変更することができます。")
                numberedPoint("2", "変更後の規約は、本アプリ内に掲示した時点より効力を生じます。")
                numberedPoint("3", "変更後も本サービスを継続利用した場合、変更内容に同意したものとみなします。")
                
                Divider()
                
                // 9. お問い合わせ
                sectionTitle("9. お問い合わせ")
                
                VStack(alignment: .leading, spacing: 8) {
                    Text("E-mail：example@example.com")
                }
                .font(.body)
                .foregroundColor(.secondary)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                
                Text("以上")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top)
            }
            .padding()
            .padding(.bottom, 80)
        }
        .navigationTitle("利用規約")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    // MARK: - Helper Views
    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(.title3)
            .fontWeight(.bold)
            .foregroundColor(.primary)
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
    
    private func subBulletPoint(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text("・")
                .foregroundColor(.secondary)
                .font(.caption)
            Text(text)
                .foregroundColor(.secondary)
                .font(.body)
        }
        .padding(.leading, 16)
    }
    
    private func numberedPoint(_ number: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Text(number + ".")
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
        TermsOfServiceView()
    }
}
