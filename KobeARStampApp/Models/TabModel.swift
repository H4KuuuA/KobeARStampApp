//
//  TabModel.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/06/30.
//

import Foundation

enum TabModel: String, CaseIterable {
    case home = "house"
    case stamp = "menucard"
    
    var title: String {
        switch self {
        case .home:
            return "ホーム"
        case .stamp:
            return "スタンプ"
        }
    }
}
