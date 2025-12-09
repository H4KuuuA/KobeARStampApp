//
//  InitalLoginViewModel.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/12/08.
//

import Foundation
import Combine

class InitialLoginViewModel: ObservableObject {
    @Published var selectedAge: Int = 0
    @Published var selectedGender: String = ""
    @Published var selectedPrefecture: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // 年齢の選択肢（0を追加して空欄を表現、18歳〜100歳）
    let ages = [0] + Array(18...100)
    
    // 性別の選択肢（空文字を追加）
    let genders = ["", "男性", "女性", "その他", "回答しない"]
    
    // 都道府県の選択肢（空文字を追加）
    let prefectures = ["", "北海道", "青森県", "岩手県", "宮城県", "秋田県", "山形県", "福島県",
        "茨城県", "栃木県", "群馬県", "埼玉県", "千葉県", "東京都", "神奈川県",
        "新潟県", "富山県", "石川県", "福井県", "山梨県", "長野県", "岐阜県",
        "静岡県", "愛知県", "三重県", "滋賀県", "京都府", "大阪府", "兵庫県",
        "奈良県", "和歌山県", "鳥取県", "島根県", "岡山県", "広島県", "山口県",
        "徳島県", "香川県", "愛媛県", "高知県", "福岡県", "佐賀県", "長崎県",
        "熊本県", "大分県", "宮崎県", "鹿児島県", "沖縄県"
    ]
    
    func saveUserProfile(completion: @escaping (Bool) -> Void) {
        isLoading = true
        errorMessage = nil
        
        let profile = UserProfile(
            age: selectedAge,
            gender: selectedGender,
            prefecture: selectedPrefecture
        )
        
        DatabaseService.shared.saveUserProfile(profile) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success:
                    print("プロフィールをSupabaseに保存しました")
                    completion(true)
                case .failure(let error):
                    print("保存エラー: \(error.localizedDescription)")
                    self?.errorMessage = error.localizedDescription
                    completion(false)
                }
            }
        }
    }
}
