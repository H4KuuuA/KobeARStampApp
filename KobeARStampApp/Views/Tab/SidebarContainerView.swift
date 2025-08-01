//
//  SidebarContainerView.swift
//  KobeARStampApp
//
//  Created by 大江悠都 on 2025/08/01.
//

import SwiftUI

struct SidebarContainerView: View {
    
    @State private var showMenu: Bool = false
    var body: some View {
        AnimationSideBar(
            rotatesWhenExpands: true,
            disablesInteraction: true,
            sideMenuWidth: 200,
            cornerRadius: 25,
            showMenu: $showMenu
        ){ safeArea in
            NavigationStack {
                MapView()
            }
        } menuView: { safeArea in
            
        } background:  {
            
        }
    }
}

#Preview {
    SidebarContainerView()
}
