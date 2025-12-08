//
//  UserProfile.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/12/08.
//

import Foundation

struct UserProfile {
    let age: Int
    let gender: String
    let prefecture: String
    
    // DB連携用のDictionary変換
    func toDictionary() -> [String: Any] {
        return [
            "age": age,
            "gender": gender,
            "prefecture": prefecture
        ]
    }
}
