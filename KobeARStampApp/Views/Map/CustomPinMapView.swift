//
//  CustomPinMapView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/07/08.
//

import SwiftUI
import MapKit

struct CustomPinMapView: UIViewRepresentable {
    let pins: [CustomPin]
    
    /// MKMapViewを初期化して返す
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        
        // pinの追加
        let annotations = pins.map { CustomPinAnnotation(pin: $0)}
        mapView.addAnnotations(annotations)
        
        return mapView
    }
    
    func updateUIView(_ view: MKMapView, context: Context) {
        // 必要に応じて更新
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate {
        
        /// CustomPinView
        ///  - 戻り値：view
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard let annotation = annotation as? CustomPinAnnotation else {
                return nil
            }
            let identifier = "CustomPin"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            if view == nil {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
                view?.canShowCallout = true
                
                // カスタム画像があれば
                if let imageURL = annotation.customPin.imageURL {
                    let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
                    // 画像URLから読み込む（非同期推奨)
                    if let data = try? Data(contentsOf: imageURL),
                       let image = UIImage(data: data) {
                        imageView.image = image
                        view?.leftCalloutAccessoryView = imageView
                    }
                }
            }else {
                view?.annotation = annotation
            }
            
            // カラーコードでのピンの色変更
            if let hex = annotation.customPin.pinColorName,
               let color = UIColor(hex: hex) {
                view?.markerTintColor = color
            }
            return view
        }
    }
}

