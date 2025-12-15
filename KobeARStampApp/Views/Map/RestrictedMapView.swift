import SwiftUI
import MapKit

struct RestrictedMapView: UIViewRepresentable {
    let centerCoordinate: CLLocationCoordinate2D
    let radiusInMeters: CLLocationDistance
    let spots: [Spot]
    @Binding var shouldCenterOnUser: Bool
    @Binding var shouldResetNorth: Bool
    
    /// 中心座標と半径をもとに、表示・移動・ズーム範囲を制限した MKMapView を生成する
    /// 円形オーバーレイを表示して、範囲の視覚的な目印も追加する
    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        
        mapView.delegate = context.coordinator
        
        mapView.showsUserLocation = true
        
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
        
        // スポットアノテーション
        let annotations = spots.map { SpotAnnotation(spot: $0)}
        mapView.addAnnotations(annotations)
        
        // 空白タップ検知用のジェスチャー追加
        let tapGesture = UITapGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handleMapTap(_:))
        )
        tapGesture.delegate = context.coordinator
        mapView.addGestureRecognizer(tapGesture)
        
        // 位置情報の監視を開始
        context.coordinator.setupLocationMonitoring(mapView: mapView, center: center, radius: radius)
        
        return mapView
    }
    
    
    func updateUIView(_ uiView: MKMapView, context: Context) {
        // 現在地に移動
        if shouldCenterOnUser {
            if let userLocation = uiView.userLocation.location {
                let region = MKCoordinateRegion(
                    center: userLocation.coordinate,
                    latitudinalMeters: 500,
                    longitudinalMeters: 500
                )
                uiView.setRegion(region, animated: true)
            }
            // フラグをリセット
            DispatchQueue.main.async {
                shouldCenterOnUser = false
            }
        }
        
        // 北向きにリセット
        if shouldResetNorth {
            var currentCamera = uiView.camera
            currentCamera.heading = 0
            uiView.setCamera(currentCamera, animated: true)
            
            // フラグをリセット
            DispatchQueue.main.async {
                shouldResetNorth = false
            }
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, MKMapViewDelegate, UIGestureRecognizerDelegate {
        private var spotLastTapTimes: [String: Date] = [:]
        private let tapDebounceInterval: TimeInterval = 0.3
        private var isUserInRange = false
        private var hasSetInitialRegion = false
        
        // 位置情報の監視を設定
        func setupLocationMonitoring(mapView: MKMapView, center: CLLocationCoordinate2D, radius: CLLocationDistance) {
            // 初期チェック（位置情報が利用可能か）
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.checkUserLocation(mapView: mapView, center: center, radius: radius)
            }
        }
        
        // ユーザー位置が範囲内かチェック
        private func checkUserLocation(mapView: MKMapView, center: CLLocationCoordinate2D, radius: CLLocationDistance) {
            guard let userLocation = mapView.userLocation.location else {
                // 位置情報が取得できない場合は灘駅を中心に表示
                if !hasSetInitialRegion {
                    setCenterToNadaStation(mapView: mapView)
                    hasSetInitialRegion = true
                }
                return
            }
            
            let centerLocation = CLLocation(latitude: center.latitude, longitude: center.longitude)
            let distance = userLocation.distance(from: centerLocation)
            
            if distance <= radius {
                // 範囲内
                isUserInRange = true
            } else {
                // 範囲外 - 灘駅を中心に表示
                if !isUserInRange && !hasSetInitialRegion {
                    setCenterToNadaStation(mapView: mapView)
                    hasSetInitialRegion = true
                }
                isUserInRange = false
            }
        }
        
        // 灘駅を中心に表示
        private func setCenterToNadaStation(mapView: MKMapView) {
            // 灘駅の座標
            let nadaStationCoordinate = CLLocationCoordinate2D(
                latitude: 34.706033113261704,
                longitude: 135.21622505489043
            )
            
            let region = MKCoordinateRegion(
                center: nadaStationCoordinate,
                latitudinalMeters: 1000,
                longitudinalMeters: 1000
            )
            
            mapView.setRegion(region, animated: true)
            print("📍 ユーザーが範囲外のため、灘駅を中心に表示しました")
        }
        
        // ユーザー位置が更新されたときに呼ばれる
        func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
            guard let location = userLocation.location else { return }
            
            // マップの中心座標と半径を取得（初回のみ必要な情報を保存）
            if let centerAnnotation = mapView.annotations.first(where: { !($0 is MKUserLocation) && !($0 is SpotAnnotation) }) {
                // 実際には制限範囲の中心を使う必要がある
                // ここでは簡略化のため、最初のチェック後は再チェックしない
            }
        }
        
        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            // 現在地の青い点はデフォルト表示を使う
            if annotation is MKUserLocation {
                return nil
            }
            
            // SpotAnnotation の場合だけカスタムビューを使う
            if let spotAnnotation = annotation as? SpotAnnotation {
                let identifier = SpotAnnotationViewWrapper.reuseIdentifier
                
                var annotationView = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? SpotAnnotationViewWrapper
                
                if annotationView == nil {
                    annotationView = SpotAnnotationViewWrapper(annotation: spotAnnotation, reuseIdentifier: identifier)
                } else {
                    // annotation の再代入を避けることで willSet 発火を回避
                    // 更新タイミングが不要なら何もしない
                }
                
                return annotationView
            }
            
            return nil
        }
        
        func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
            guard let spotAnnotation = view.annotation as? SpotAnnotation else { return }
            
            let spotId = spotAnnotation.spot.id
            let currentTime = Date()
            
            // デバウンス処理: 0.3秒以内のタップは無視
            if let lastTap = spotLastTapTimes[spotId],
               currentTime.timeIntervalSince(lastTap) < tapDebounceInterval {
                print("デバウンス: \(spotAnnotation.title ?? "No title") のタップが早すぎます - 無視します")
                // 選択を解除して次回のタップに備える
                mapView.deselectAnnotation(view.annotation, animated: false)
                return
            }
            
            // 有効なタップとして処理
            spotLastTapTimes[spotId] = currentTime
            
            print("\(spotAnnotation.title ?? "No title") selected")
            
            // 通知処理
            NotificationCenter.default.post(
                name: .spotTapped,
                object: spotAnnotation.spot
            )
            
            // 選択を解除して連続タップを可能にする
            mapView.deselectAnnotation(view.annotation, animated: false)
        }
        
        // マップの空白タップを検知するハンドラー
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
            let hasSpotAnnotation = annotations.contains { annotation in
                annotation is SpotAnnotation
            }
            
            // アノテーションがない場所をタップした場合のみ通知
            if !hasSpotAnnotation {
                print("マップの空白部分がタップされました")
                NotificationCenter.default.post(
                    name: .spotDeselected,
                    object: nil
                )
            }
        }
        
        // ジェスチャーとマップのタッチを共存させる
        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            return true
        }
    }
}
