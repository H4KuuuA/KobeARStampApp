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
    let pins: [CustomPin]
    
    /// 中心座標と半径をもとに、表示・移動・ズーム範囲を制限した MKMapView を生成する
    /// 円形オーバーレイを表示して、範囲の視覚的な目印も追加する
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        
        mapView.delegate = context.coordinator
        
        mapView.showsUserLocation = true
        mapView.userTrackingMode = .follow
        
        let center = centerCoordinate
        let radius = radiusInMeters
        
        let region = MKCoordinateRegion(
            center: center,
            latitudinalMeters: radius * 0.8,
            longitudinalMeters: radius * 1.0
        )
        mapView.setRegion(region, animated: false)
        
        // パン(移動)制限
        let boundary = MKMapView.CameraBoundary(coordinateRegion: region)
        mapView.setCameraBoundary(boundary, animated: false)
        
        // ズームアウト制限
        let zoomRange = MKMapView.CameraZoomRange(
            maxCenterCoordinateDistance: radius * 5
        )
        mapView.setCameraZoomRange(zoomRange, animated: false)
        
        // カスタムピン
        let annotations = pins.map { CustomPinAnnotation(pin: $0)}
        mapView.addAnnotations(annotations)
        
        // ★ 空白タップ検知用のジェスチャー追加
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleMapTap(_:))
        )
        tapGesture.delegate = context.coordinator
        mapView.addGestureRecognizer(tapGesture)
        
        return mapView
    }
    
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // 状態に変更があった時の機能の追加場所
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        private var pinLastTapTimes: [String: Date] = [:]
        private let tapDebounceInterval: TimeInterval = 0.3
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // 現在地の青い点はデフォルト表示を使う
            if annotation is MKUserLocation {
                return nil
            }
            
            // CustomPinAnnotation の場合だけカスタムビューを使う
            if let customAnnotation = annotation as? CustomPinAnnotation {
                let identifier = CustomPinAnnotationView.reuseIdentifier
                
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? CustomPinAnnotationView
                
                if annotationView == nil {
                    annotationView = CustomPinAnnotationView(annotation: customAnnotation, reuseIdentifier: identifier)
                } else {
                    // annotation の再代入を避けることで willSet 発火を回避
                    // 更新タイミングが不要なら何もしない
                }
                
                return annotationView
            }
            
            return nil
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let customAnnotation = view.annotation as? CustomPinAnnotation else { return }
            
            let pinId = customAnnotation.customPin.id.uuidString
            let currentTime = Date()
            
            // デバウンス処理: 0.3秒以内のタップは無視
            if let lastTap = pinLastTapTimes[pinId],
               currentTime.timeIntervalSince(lastTap) < tapDebounceInterval {
                print("デバウンス: \(customAnnotation.title ?? "No title") のタップが早すぎます - 無視します")
                // 選択を解除して次回のタップに備える
                mapView.deselectAnnotation(view.annotation, animated: false)
                return
            }
            
            // 有効なタップとして処理
            pinLastTapTimes[pinId] = currentTime
            
            print("\(customAnnotation.title ?? "No title") selected")
            
            // 通知処理
            NotificationCenter.default.post(
                name: Notification.Name.customPinTapped,
                object: customAnnotation.customPin
            )
            
            // 選択を解除して連続タップを可能にする
            mapView.deselectAnnotation(view.annotation, animated: false)
        }
        
        // ★ マップの空白タップを検知するハンドラー
        @objc func handleMapTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            
            // タップ位置にアノテーションがあるか確認
            let mapRect = MKMapRect(
                origin: MKMapPoint(coordinate),
                size: MKMapSize(width: 0.1, height: 0.1)
            )
            
            let annotations = mapView.annotations(in: mapRect)
            let hasCustomPin = annotations.contains { annotation in
                annotation is CustomPinAnnotation
            }
            
            // アノテーションがない場所をタップした場合のみ通知
            if !hasCustomPin {
                print("マップの空白部分がタップされました")
                NotificationCenter.default.post(
                    name: Notification.Name.customPinDeselected,
                    object: nil
                )
            }
        }
        
        // ★ ジェスチャーとマップのタッチを共存させる
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            return true
        }
    }
}
