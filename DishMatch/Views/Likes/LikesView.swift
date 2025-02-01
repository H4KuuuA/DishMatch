//
//  LikesView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct LikesView: View {
    @StateObject var searchViewModel = SearchViewModel()
    @StateObject private var likesTabViewModel: LikesTabViewModel
    @ObservedObject var restaurantViewModel: RestaurantViewModel 

    @State private var searchText: String = ""
    @State private var isSearchPresented = false

    init(restaurantViewModel: RestaurantViewModel) {
        _restaurantViewModel = ObservedObject(wrappedValue: restaurantViewModel)
        _likesTabViewModel = StateObject(wrappedValue: LikesTabViewModel(restaurantViewModel: restaurantViewModel))
    }

    var body: some View {
        VStack {
            TextFieldLikeView(isSearchPresented: $isSearchPresented, searchText: $searchText)
            GenreTabBarView(likesTabViewModel: likesTabViewModel, restaurantViewModel: restaurantViewModel, isGenreActive: true)
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
