//
//  TabModel.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/06/30.
//

import Foundation

enum TabModel: String, CaseIterable {
    case home = "house.fill"
    case stamp = "menucard.fill"
    
    var title: String {
        switch self {
        case .home:
            return "ホーム"
        case .stamp:
            return "スタンプカード"
        }
    }
}

/// animated SF Tab Model
struct AnimatedTabModel: Identifiable {
    var id: UUID = .init()
    var tab: TabModel
    var isAnimating: Bool?
}
