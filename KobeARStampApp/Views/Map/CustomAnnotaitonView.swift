//
//  SpotAnnotationViewWrapper.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/07/14.
//

import SwiftUI
import UIKit
import MapKit

/// SwiftUIのSpotAnnotationViewをMKAnnotationに組み込むためのブリッジクラス
class SpotAnnotationViewWrapper: MKAnnotationView {
    static let reuseIdentifier = "SpotAnnotationViewWrapper"
    
    private var hostingController: UIHostingController<SpotAnnotationView>?
    
    override var annotation: MKAnnotation? {
        willSet {
            guard let spotAnnotation = newValue as? SpotAnnotation else { return }
            
            // SwiftUI側と同期するピンの見た目サイズ
            let viewSize: CGFloat = 70
            
            // 座標点にピンの下端（先端）が合うように、ビュー中心を半分だけ上にずらす
            centerOffset = CGPoint(x: 0, y: -viewSize / 2)
            
            let pinColorHex = spotAnnotation.spot.pinColorName ?? "#0000FF"
            let swiftUIView = SpotAnnotationView(
                spot: spotAnnotation.spot,
                size: viewSize,
                pinColorHex: pinColorHex
            )
            
            if hostingController == nil {
                hostingController = UIHostingController(rootView: swiftUIView)
                hostingController?.view.backgroundColor = .clear
                hostingController?.view.translatesAutoresizingMaskIntoConstraints = false
                addSubview(hostingController!.view)
                
                NSLayoutConstraint.activate([
                    hostingController!.view.leadingAnchor.constraint(equalTo: leadingAnchor),
                    hostingController!.view.trailingAnchor.constraint(equalTo: trailingAnchor),
                    hostingController!.view.topAnchor.constraint(equalTo: topAnchor),
                    hostingController!.view.bottomAnchor.constraint(equalTo: bottomAnchor)
                ])
            } else {
                // view構築が重くなるのを防ぐため、差分がなければ更新しない
                if hostingController?.rootView.spot.id != spotAnnotation.spot.id {
                    hostingController?.rootView = swiftUIView
                }
            }
            
            // 表示サイズと位置調整
            frame = CGRect(x: 0, y: 0, width: viewSize, height: viewSize)
        }
    }
}
