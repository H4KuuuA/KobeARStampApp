//
//  CustomPinAnnotation.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/07/08.
//

import Foundation
import MapKit

/// MKAnotation 準拠クラス
class CustomPinAnnotation: NSObject, MKAnnotation {
    
    let customPin: CustomPin
    
    init(pin: CustomPin) {
        self.customPin = pin
    }
    
    var coordinate: CLLocationCoordinate2D {
        customPin.coordinate
    }
    
    var title: String? {
        customPin.title
    }
    
    var subtitle: String? {
        customPin.subtitle
    }
}
