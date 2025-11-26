//
//  StampStatusBadge.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/11/19.
//

import SwiftUI

struct StampStatusBadge: View {
    let isAcquired: Bool
    
    var body: some View {
        if isAcquired {
            HStack(spacing: 4) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.blue)
                Text("取得済み")
                    .font(.caption.bold())
                    .foregroundColor(.blue)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.2))
            .cornerRadius(8)
        } else {
            HStack(spacing: 4) {
                Image(systemName: "lock.fill")
                    .foregroundColor(.gray)
                Text("未取得")
                    .font(.caption.bold())
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.2))
            .cornerRadius(8)
        }
    }
}

#Preview {
    StampStatusBadge(isAcquired: false)
}
