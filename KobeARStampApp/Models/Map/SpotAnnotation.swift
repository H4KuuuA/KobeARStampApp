//
//  SpotAnnotation.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/07/08.
//

import Foundation
import MapKit

/// MKAnnotation 準拠クラス（Spot版）
class SpotAnnotation: NSObject, MKAnnotation {
    
    let spot: Spot
    
    init(spot: Spot) {
        self.spot = spot
    }
    
    var coordinate: CLLocationCoordinate2D {
        spot.coordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0)
    }
    
    var title: String? {
        spot.name
    }
    
    var subtitle: String? {
        spot.subtitle
    }
}
