//
//  UIColor.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/07/08.
//

import SwiftUI
import UIKit

extension UIColor {
    convenience init?(hex: String) {
        var hexSantiized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSantiized = hexSantiized.replacingOccurrences(of: "#", with: "")
        
        var rgb: UInt64 = 0
        guard Scanner(string: hexSantiized).scanHexInt64(&rgb) else {
            return nil
        }
        
        switch hexSantiized.count {
            // 6桁カラーコード
        case 6:
            self.init(
                red: CGFloat((rgb & 0xFF0000) >> 16) / 255,
                green: CGFloat((rgb & 0x00FF00) >> 8) / 255,
                blue: CGFloat(rgb & 0x0000FF) / 255,
                alpha: 1
            )
            // 8桁カラーコード
        case 8:
            self.init(
                red: CGFloat((rgb & 0xFF000000) >> 24) / 255,
                green: CGFloat((rgb & 0x00FF0000) >> 16) / 255,
                blue: CGFloat((rgb & 0x0000FF00) >> 8) / 255,
                alpha: CGFloat(rgb & 0x000000FF) / 255
            )
        default:
            return nil
        }
    }
}

extension Color {
    init?(hex: String) {
        guard let uiColor = UIColor(hex: hex) else { return nil }
        self.init(uiColor)
    }
}
