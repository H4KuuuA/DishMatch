//
//  LikesView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct LikesView: View {
    @StateObject var searchViewModel = SearchViewModel()
    @ObservedObject var restaurantViewModel: RestaurantViewModel
    @State private var searchText: String = ""
    
    @State private var isSearchPresented = false
    var body: some View {
        VStack {
            TextFieldLikeView(isSearchPresented: $isSearchPresented, searchText: $searchText)
            GenreTabBarView(LikesViewModel: LikesViewModel(stores: MockData.stores), isGenreActive: true)
            LikeShopsListView(restaurantViewModel: restaurantViewModel)
        }
        .fullScreenCover(isPresented: $isSearchPresented) {
            LikesSearchView(searchViewModel: searchViewModel, isPresented: $isSearchPresented, searchText: $searchText)
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
