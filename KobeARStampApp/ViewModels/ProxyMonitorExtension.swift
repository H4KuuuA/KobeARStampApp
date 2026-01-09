//
//  ProxyMonitorExtension.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/11/14.
//

import Foundation
import CoreLocation

// MARK: - ProximityDetector Extension for Spot

extension ProximityDetector {
    
    /// Spot用の距離計算
    func calculateDistances(
        from location: CLLocation,
        to spots: [Spot]
    ) -> [(spot: Spot, distance: CLLocationDistance)] {

        return spots.map { spot in
            let coord = spot.coordinate
            
            let spotLocation = CLLocation(
                latitude: coord.latitude,
                longitude: coord.longitude
            )

            let distance = location.distance(from: spotLocation)
            
            return (spot: spot, distance: distance)
        }
    }
    
    /// Spot用の近接判定（シンプル版）
    func findNearestSpot(
        from location: CLLocation,
        in spots: [Spot],
        maxDistance: CLLocationDistance = 25.0
    ) -> (spot: Spot, distance: CLLocationDistance)? {
        
        let spotsWithDistance = calculateDistances(from: location, to: spots)
        
        guard let nearest = spotsWithDistance.min(by: { $0.distance < $1.distance }) else {
            return nil
        }
        
        // maxDistance以内の場合のみ返す
        if nearest.distance <= maxDistance {
            return nearest
        } else {
            return nil
        }
    }
}

