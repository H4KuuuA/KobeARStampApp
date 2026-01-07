//
//  UserProfile.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/12/08.
//

import Foundation

struct UserProfile: Codable {
    let id: UUID?
    let userId: UUID
    let email: String
    let username: String?
    let role: String
    let gender: Int?
    let address: String?
    let birthDate: String?  // 👈 変更点1: Date? ではなく String? で受け取る
    let isActive: Bool
    let lastLoginAt: Date?
    let createdAt: Date?
    let updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case email
        case username
        case role
        case gender
        case address
        case birthDate = "birth_date"
        case isActive = "is_active"
        case lastLoginAt = "last_login_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    // 👈 追加: 計算用にDate型として扱いたいときのための計算プロパティ
    var birthDateObject: Date? {
        guard let dateString = birthDate else { return nil }
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter.date(from: dateString)
    }

    // 新規登録用のイニシャライザ
    init(userId: UUID, email: String, birthDate: Date, gender: Int, prefecture: String) {
        self.id = nil
        self.userId = userId
        self.email = email
        self.username = nil
        self.role = "user"
        self.gender = gender
        self.address = prefecture
        
        // 👈 変更点2: Dateを渡されたら、ここで文字列("yyyy-MM-dd")に変換して保存する
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        self.birthDate = formatter.string(from: birthDate)
        
        self.isActive = true
        self.lastLoginAt = Date()
        self.createdAt = Date()
        self.updatedAt = nil
    }
    
    // 年齢を計算
    var age: Int? {
        // 👈 変更点3: birthDateObject を使うように修正
        guard let birthDate = birthDateObject else { return nil }
        let calendar = Calendar.current
        let ageComponents = calendar.dateComponents([.year], from: birthDate, to: Date())
        return ageComponents.year
    }
    
    // DB連携用のDictionary変換
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "user_id": userId.uuidString,
            "email": email,
            "role": role,
            "is_active": isActive
        ]
        
        if let username = username {
            dict["username"] = username
        }
        
        if let gender = gender {
            dict["gender"] = gender
        }
        
        if let address = address {
            dict["address"] = address
        }
        
        // 👈 変更点4: すでにStringになっているのでそのまま入れる
        if let birthDate = birthDate {
            dict["birth_date"] = birthDate
        }
        
        if let lastLoginAt = lastLoginAt {
            dict["last_login_at"] = ISO8601DateFormatter().string(from: lastLoginAt)
        }
        
        return dict
    }
}

// MARK: - 認証用のリクエスト・レスポンスなど (以下変更なし)
struct SignUpRequest {
    let email: String
    let password: String
    let birthDate: Date
    let gender: Int
    let prefecture: String
}

struct SignInRequest {
    let email: String
    let password: String
}

enum Gender: Int, CaseIterable {
    case male = 1
    case female = 2
    case other = 3
    case preferNotToSay = 4
    
    var displayName: String {
        switch self {
        case .male: return "男性"
        case .female: return "女性"
        case .other: return "その他"
        case .preferNotToSay: return "回答しない"
        }
    }
    
    static func fromDisplayName(_ name: String) -> Gender? {
        return Gender.allCases.first { $0.displayName == name }
    }
}
