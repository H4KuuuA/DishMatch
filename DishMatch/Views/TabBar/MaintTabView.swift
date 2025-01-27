//
//  TabBarView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/22.
//

import SwiftUI

struct MainTabView: View {
    @StateObject var cardsViewModel = CardsViewModel() // 一元管理するCardsViewModel

    var body: some View {
        TabView {
            CardStackView(viewModel: cardsViewModel)
                .tabItem {
                    Image(systemName: "fork.knife")
                }
                .tag(0)

            LikesView(viewModel: cardsViewModel)
                .tabItem {
                    Image(systemName: "heart.fill")
                }
                .tag(1)

            UserProfileView()
                .tabItem {
                    Image(systemName: "person")
                }
                .tag(2)
        }
        .tint(.primary)
        .background(Color("BG"))
        .edgesIgnoringSafeArea(.all)
    }
}

#Preview {
    MainTabView()
}
