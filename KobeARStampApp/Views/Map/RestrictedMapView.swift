//
//  RestrictedMapView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/07/07.
//

import SwiftUI
import MapKit

struct RestrictedMapView: UIViewRepresentable {
    let centerCoordinate: CLLocationCoordinate2D
    let radiusInMeters: CLLocationDistance
    
    /// 中心座標と半径をもとに、表示・移動・ズーム範囲を制限した MKMapView を生成する
    /// 円形オーバーレイを表示して、範囲の視覚的な目印も追加する
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()

        let center = centerCoordinate
        let radius = radiusInMeters

        let region = MKCoordinateRegion(
            center: center,
            latitudinalMeters: radius * 1.5,
            longitudinalMeters: radius * 1.5
        )
        mapView.setRegion(region, animated: false)

        // パン（移動）制限 
        let boundary = MKMapView.CameraBoundary(coordinateRegion: region)
        mapView.setCameraBoundary(boundary, animated: false)

        // ズームアウト制限
        let zoomRange = MKMapView.CameraZoomRange(
            maxCenterCoordinateDistance: radius * 5
        )
        mapView.setCameraZoomRange(zoomRange, animated: false)

        // 円の描画
        let circle = MKCircle(center: center, radius: radius)
        mapView.addOverlay(circle)

        mapView.delegate = context.coordinator

        return mapView
    }

    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // 状態に変更があった時の機能の追加場所
    }
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    /// オーバーレイ（例: 円など）を描画するためのレンダラーを返す
    /// - Returns: 対応する MKOverlayRenderer（例: MKCircleRenderer）
    class Coordinator: NSObject, MKMapViewDelegate {
        func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
            if let  circleOverlay = overlay as? MKCircle {
                let renderer = MKCircleRenderer(circle: circleOverlay)
                renderer.fillColor = UIColor.systemBlue.withAlphaComponent(0.2)
                renderer.strokeColor = UIColor.systemBlue
                renderer.lineWidth = 2
                return renderer
            }
            return MKOverlayRenderer(overlay: overlay)
        }
    }
    
}
