//
//  LikesView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct LikesView: View {
    @StateObject var searchViewModel: SearchViewModel
    @StateObject private var likesTabViewModel: LikesTabViewModel
    @ObservedObject var restaurantViewModel: RestaurantViewModel

    @State private var searchText: String = ""
    @State private var isSearchPresented = false

    init(restaurantViewModel: RestaurantViewModel) {
        _restaurantViewModel = ObservedObject(wrappedValue: restaurantViewModel)
        _searchViewModel = StateObject(wrappedValue: SearchViewModel(restaurantViewModel: restaurantViewModel))
        _likesTabViewModel = StateObject(wrappedValue: LikesTabViewModel(restaurantViewModel: restaurantViewModel))
    }

    var body: some View {
        VStack {
            TextFieldLikeView(isSearchPresented: $isSearchPresented, searchText: $searchText)
            GenreTabBarView(
                likesTabViewModel: likesTabViewModel,
                searchViewModel: searchViewModel,
                restaurantViewModel: restaurantViewModel,
                searchText: $searchText, // 🔹 `searchText` を渡す
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
    @Previewable @State var searchText = ""  // 🔹 `searchText` を `@State` で用意
    let restaurantViewModel = RestaurantViewModel()
    let searchViewModel = SearchViewModel(restaurantViewModel: restaurantViewModel)
    let likesTabViewModel = LikesTabViewModel(restaurantViewModel: restaurantViewModel)
    
    restaurantViewModel.favoriteShops = [MockShop.mockShop]
    
    return LikesView(restaurantViewModel: restaurantViewModel)
}


