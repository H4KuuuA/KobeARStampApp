//
//  stamp.swift
//  KobeARStampApp
//
//  Created by shikiji akito on 2025/10/14.
//

import Foundation

/// A data structure representing a single collected stamp.
struct Stamp: Identifiable, Codable {
    let id: UUID
    /// The filename of the saved image in the app's documents directory.
    let imageFileName: String
    let acquiredDate: Date
}
