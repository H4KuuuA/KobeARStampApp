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
        title: "神戸ポートタワー",
        subtitle: "港のランドマーク",
        coordinate: CLLocationCoordinate2D(latitude: 34.6824, longitude: 135.1945),
        pinColorName: "red",
        imageURL: URL(string: "https://example.com/images/port_tower.png"),
        description: "神戸港のシンボル的存在。夜景が美しい。",
        category: "観光",
        createdAt: Date(timeIntervalSince1970: 1_689_000_000),
        updatedAt: nil
    ),
    CustomPin(
        id: UUID(),
        title: "メリケンパーク",
        subtitle: nil,
        coordinate: CLLocationCoordinate2D(latitude: 34.6805, longitude: 135.1868),
        pinColorName: "blue",
        imageURL: URL(string: "https://example.com/images/meriken_park.png"),
        description: "広々とした公園でイベントも開催される。",
        category: "公園",
        createdAt: Date(timeIntervalSince1970: 1_689_000_100),
        updatedAt: Date(timeIntervalSince1970: 1_689_500_000)
    ),
    CustomPin(
        id: UUID(),
        title: "中華街 南京町",
        subtitle: "食べ歩きスポット",
        coordinate: CLLocationCoordinate2D(latitude: 34.6900, longitude: 135.1900),
        pinColorName: "orange",
        imageURL: URL(string: "https://example.com/images/nankinmachi.png"),
        description: "関西屈指の中華街。観光客に人気。",
        category: "グルメ",
        createdAt: Date(),
        updatedAt: Date()
    )
]

