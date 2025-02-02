//
//  TabBarView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/22.
//

import SwiftUI

struct MainTabView: View {
    @StateObject private var restaurantViewModel = RestaurantViewModel()
    @StateObject private var searchViewModel: SearchViewModel
    @StateObject private var likesTabViewModel: LikesTabViewModel

    init() {
        let restaurantViewModel = RestaurantViewModel()
        _restaurantViewModel = StateObject(wrappedValue: restaurantViewModel)
        _searchViewModel = StateObject(wrappedValue: SearchViewModel(restaurantViewModel: restaurantViewModel))
        _likesTabViewModel = StateObject(wrappedValue: LikesTabViewModel(restaurantViewModel: restaurantViewModel))
    }

    var body: some View {
        TabView {
            CardStackView(restaurantViewModel: restaurantViewModel)
                .tabItem {
                    Image(systemName: "fork.knife")
                }
                .tag(0)

            LikesView(
                searchViewModel: searchViewModel,  
                likesTabViewModel: likesTabViewModel,
                restaurantViewModel: restaurantViewModel
            )
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

