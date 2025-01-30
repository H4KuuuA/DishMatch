//
//  LikesView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct LikesView: View {
    @ObservedObject var restaurantViewModel: RestaurantViewModel
    
    var body: some View {
        VStack {
            TextFieldLikeView()
            GenreTabBarView(LikesViewModel: LikesViewModel(stores: MockData.stores), isGenreActive: true)
            LikeShopsListView(restaurantViewModel: restaurantViewModel)
        }
    }
}

#Preview {
    let restaurantViewModel = RestaurantViewModel()
    restaurantViewModel.favoriteShops = [
        MockShop.mockShop,
        MockShop.mockShop
    ]
    
    return LikesView(restaurantViewModel: restaurantViewModel)
}
