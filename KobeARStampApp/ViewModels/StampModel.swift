//
//  StampModel.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/10/22.
//

import Foundation
import CoreLocation
/// A data structure representing a single AR spot.
struct Spot: Identifiable {
    let id: String // e.g., "kobe-port-tower"
    let name: String
    let placeholderImageName: String
    /// The filename of the 3D model associated with this spot (e.g., "port_tower.usdz").
    let modelName: String
    let coordinate: CLLocationCoordinate2D
}

/// A data structure representing a single collected stamp.
/// The `spotID` links this stamp to a specific `Spot`.
struct AcquiredStamp: Identifiable, Codable {
    let id: UUID
    let spotID: String
    let imageFileName: String
    let acquiredDate: Date
}

