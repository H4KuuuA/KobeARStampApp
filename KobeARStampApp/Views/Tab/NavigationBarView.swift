//
//  NavigationBarView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/07/29.
//

import SwiftUI

struct CustomNavigationBar: View {
    let onMenuTap: () -> Void
    let onNotificationTap: () -> Void
    @Binding var showMenu: Bool
    var body: some View {
        VStack(spacing:0) {
            HStack {
                MenuButton(action: onMenuTap, showMenu: $showMenu)
                
                Spacer()
                
                // 実際の使用時:
                Image("ar_stamp_rally_logo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 36)
                    .padding(.leading, 32)
                
                Spacer()
                
                NotificationButton(action: onNotificationTap)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(minHeight: 44)
            .background(navigationBarBackground)
        }
    }
    
    private var navigationBarBackground: some View {
        Color(.systemBackground)
            .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
    }
}

// MARK: - Subviews

private struct MenuButton: View {
    let action: () -> Void
    @Binding var showMenu: Bool
    
    var body: some View {
        Button(action: {
            showMenu.toggle()
        }) {
            Image(systemName: showMenu ? "xmark" : "line.3.horizontal")
                .font(.title2)
                .foregroundColor(.primary)
                .frame(width: 44, height: 44)
                .contentTransition(.symbolEffect)
        }
    }
}

private struct NotificationButton: View {
    let action: () -> Void
    @State private var hasNotification = false
    
    var body: some View {
        Button(action: action) {
            ZStack {
                Image(systemName: "bell")
                    .font(.title2)
                    .foregroundColor(.primary)
                
                if hasNotification {
                    notificationBadge
                }
            }
            .frame(width: 44, height: 44)
        }
    }
    
    private var notificationBadge: some View {
        Circle()
            .fill(Color.red)
            .frame(width: 8, height: 8)
            .offset(x: 8, y: -8)
    }
}

// MARK: - Previews

#Preview {
    @Previewable @State var showMenu = false
    
    return CustomNavigationBar(
        onMenuTap: { print("Menu tapped") },
        onNotificationTap: { print("Notification tapped") },
        showMenu: $showMenu
    )
}
