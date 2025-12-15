//
//  TabModel.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/06/30.
//

import Foundation
import SwiftUI

// MARK: - メイン画面の切り替え用
// 下のタブバーと、メイン画面の表示切り替えに使います
enum TabModel: String, CaseIterable {
    case home = "house.fill"
    case stamp = "menucard.fill"
    // ★追加: MainTabView内で設定画面に切り替えるために必要です
    case settings = "gearshape.fill"
    
    var title: String {
        switch self {
        case .home:
            return "ホーム"
        case .stamp:
            return "スタンプカード"
        case .settings:
            return "設定"
        }
    }
}

// MARK: - タブバーのアニメーション用
struct AnimatedTabModel: Identifiable {
    var id: UUID = .init()
    var tab: TabModel
    var isAnimating: Bool?
}

// MARK: - サイドメニューのリスト用
// サイドバーに並べる項目の定義だけに使います
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
