//
//  mockPins.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/07/07.
//

//
//  mockPins.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/07/07.
//

import Foundation
import CoreLocation

let mockPins: [CustomPin] = [
    CustomPin(
        id: UUID(),
        title: "王子動物園",
        subtitle: "パンダもいる人気動物園",
        coordinate: CLLocationCoordinate2D(latitude: 34.709591901580474, longitude: 135.21519562134145),
        pinColorName: "#B2EEDA",
        imageURL: URL(string: "https://example.com/images/ojizoo.png"),
        description: "神戸市灘区にある、パンダとコアラが見られる動物園。",
        category: "レジャー",
        createdAt: Date(timeIntervalSince1970: 1_689_000_000),
        updatedAt: nil
    ),
    CustomPin(
        id: UUID(),
        title: "兵庫県立美術館",
        subtitle: "海辺のモダンな美術館",
        coordinate: CLLocationCoordinate2D(latitude: 34.700080471831484, longitude: 135.21794931523175),
        pinColorName: "#ABBEE0", 
        imageURL: URL(string: "https://example.com/images/hyogo_museum.png"),
        description: "安藤忠雄設計による建築と、現代アートの展示で知られる。",
        category: "文化",
        createdAt: Date(timeIntervalSince1970: 1_689_000_100),
        updatedAt: Date(timeIntervalSince1970: 1_689_500_000)
    ),
    CustomPin(
        id: UUID(),
        title: "HAT神戸の道",
        subtitle: "海沿いの散策路",
        coordinate: CLLocationCoordinate2D(latitude: 34.697385064900914, longitude: 135.21659017406387),
        pinColorName: "#FFECAE",
        imageURL: URL(string: "https://example.com/images/hat_path.png"),
        description: "HAT神戸地区を海沿いに歩ける快適な散歩道。",
        category: "散策",
        createdAt: Date(),
        updatedAt: Date()
    )
]
