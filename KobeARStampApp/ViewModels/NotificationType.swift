//
//  NotificationType.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/10/20.
//

import Foundation

/// 通知のタイプを定義する列挙型
enum NotificationType: String, Codable, CaseIterable {
    /// ピンへの接近通知
    case pinProximity = "pin_proximity"
    
    /// 実績解除通知
    case achievement = "achievement"
    
    /// システム通知
    case system = "system"
    
    /// ピンからの退出通知（オプション）
    case pinExit = "pin_exit"
    
    /// ピンの切り替え通知（オプション）
    case pinSwitch = "pin_switch"
    
    // MARK: - Display Properties
    
    /// 通知タイプに応じたデフォルトのアイコン名（SF Symbols）
    var defaultIcon: String {
        switch self {
        case .pinProximity:
            return "mappin.circle.fill"
        case .achievement:
            return "star.fill"
        case .system:
            return "gearshape.circle.fill"
        case .pinExit:
            return "arrow.uturn.left.circle.fill"
        case .pinSwitch:
            return "arrow.triangle.2.circlepath"
        }
    }
    
    /// 通知タイプに応じたデフォルトのアプリ名
    var defaultAppName: String {
        switch self {
        case .pinProximity:
            return "ARスタンプ"
        case .achievement:
            return "実績"
        case .system:
            return "システム"
        case .pinExit:
            return "ARスタンプ"
        case .pinSwitch:
            return "ARスタンプ"
        }
    }
    
    /// 通知タイプに応じたデフォルトの背景色（文字列で保存）
    var defaultColorName: String {
        switch self {
        case .pinProximity:
            return "blue"
        case .achievement:
            return "yellow"
        case .system:
            return "gray"
        case .pinExit:
            return "purple"
        case .pinSwitch:
            return "green"
        }
    }
}
