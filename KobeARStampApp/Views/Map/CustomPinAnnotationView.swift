//
//  CustomPinAnnotationView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/07/14.
//

import SwiftUI
import UIKit
import MapKit

/// SwiftUIのCustomAnnotationViewをMKAnnotationの組み込むためのブリッジクラス
class CustomPinAnnotationView: MKAnnotationView {
    static let reuseIdentifier = "CustomPinAnnotationView"
    
    private var hositingController: UIHostingController<CustomAnnotaitonView>?
    
    override var annotation: MKAnnotation? {
        willSet {
            guard let  customAnnotation = newValue as? CustomPinAnnotation else { return }
            
            // SwiftUI側と同期するピンの見た目サイズ
            let viewSize: CGFloat = 50
            let pinColorHex = customAnnotation.customPin.pinColorName ?? "#0000FF"
            let swiftUIView = CustomAnnotaitonView(
                pin: customAnnotation.customPin,
                size: viewSize,
                pinColorHex: pinColorHex
            )
            
            if hositingController == nil {
                hositingController = UIHostingController(rootView: swiftUIView)
                hositingController?.view.backgroundColor = .clear
                hositingController?.view.translatesAutoresizingMaskIntoConstraints = false
                addSubview(hositingController!.view)
                
                NSLayoutConstraint.activate([
                    hositingController!.view.leadingAnchor.constraint(equalTo: leadingAnchor),
                    hositingController!.view.trailingAnchor.constraint(equalTo: trailingAnchor),
                    hositingController!.view.topAnchor.constraint(equalTo: topAnchor),
                    hositingController!.view.bottomAnchor.constraint(equalTo: bottomAnchor)
                ])
            } else {
                // view構築が重くなるのを防ぐため、差分がなければ更新しない
                if hositingController?.rootView.pin.id != customAnnotation.customPin.id {
                    hositingController?.rootView = swiftUIView
                }
            }
            // 表示サイズと位置調整
            frame = CGRect(x: 0, y: 0, width: viewSize, height: viewSize)
            centerOffset = CGPoint(x: 0, y: -viewSize / 2)
            
        }
    }
}
