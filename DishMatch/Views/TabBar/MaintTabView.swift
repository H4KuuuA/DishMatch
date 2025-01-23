//
//  TabBarView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/22.
//

import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView{
            CardStackView()
                .tabItem { Image (systemName: "fork.knife")}
                .tag(0)
            
            LikesView()
                .tabItem { Image (systemName: "heart.fill")}
                .tag(1)
            
            UserProfileView()
                .tabItem{ Image (systemName: "person")}
                .tag(2)
        }
        .tint(.primary)
    }
}

#Preview {
    MainTabView()
}
