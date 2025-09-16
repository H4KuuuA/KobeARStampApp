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

enum SideMenuTab: String, CaseIterable, Identifiable {
    case home = "house"
    case stampRally = "menucard"
    case camera = "camera"
    case notification = "bell"
    case settings = "gearshape"
    
    var id: String { rawValue }
    
    var title: String {
        switch self {
        case .home:
            return "ホーム"
        case .stampRally:
            return "スタンプカード"
        case .camera:
            return "カメラ"
        case .notification:
            return "通知"
        case .settings:
            return "設定"
        }
    }
}
