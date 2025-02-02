//
//  LikesView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

//
//  LikesView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct LikesView: View {
    @ObservedObject var searchViewModel: SearchViewModel
    @ObservedObject var likesTabViewModel: LikesTabViewModel
    @ObservedObject var restaurantViewModel: RestaurantViewModel

    @State private var searchText: String = ""
    @State private var isSearchPresented = false

    var body: some View {
        VStack {
            TextFieldLikeView(isSearchPresented: $isSearchPresented, searchText: $searchText)
            GenreTabBarView(
                likesTabViewModel: likesTabViewModel,
                searchViewModel: searchViewModel,
                restaurantViewModel: restaurantViewModel,
                searchText: $searchText,
                isGenreActive: true
            )
            LikeShopsListView(
                restaurantViewModel: restaurantViewModel,
                searchViewModel: searchViewModel,
                searchText: $searchText
            )
        }
        .fullScreenCover(isPresented: $isSearchPresented) {
            LikesSearchView(searchViewModel: searchViewModel, isPresented: $isSearchPresented, searchText: $searchText)
        }
    }
}

#Preview {
    let restaurantViewModel = RestaurantViewModel()
    let searchViewModel = SearchViewModel(restaurantViewModel: restaurantViewModel)
    let likesTabViewModel = LikesTabViewModel(restaurantViewModel: restaurantViewModel)

    restaurantViewModel.favoriteShops = [MockShop.mockShop]

    return LikesView( 
        searchViewModel: searchViewModel,
        likesTabViewModel: likesTabViewModel,
        restaurantViewModel: restaurantViewModel
    )
}


