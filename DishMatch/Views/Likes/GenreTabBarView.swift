//
//  GenreTabBarView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct GenreTabBarView: View {
    @State private var selectedIndex: Int = 0
    @ObservedObject var likesTabViewModel: LikesTabViewModel
    @ObservedObject var searchViewModel: SearchViewModel
    @ObservedObject var restaurantViewModel: RestaurantViewModel
    @Binding var searchText: String

    let isGenreActive: Bool

    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(likesTabViewModel.uniqueShops.indices, id: \.self) { index in
                        let shop = likesTabViewModel.uniqueShops[index]
                        let genreName = shop.genre.name

                        VStack(alignment: .leading) {
                            Text(genreName)
                                .font(.system(size: 18))
                                .fontWeight(.semibold)
                                .foregroundColor(index == selectedIndex && isGenreActive ? Color(.orange) : Color("FC").opacity(0.6))
                            
                            if index == selectedIndex && isGenreActive {
                                Color(.orange)
                                    .frame(width: 15, height: 2)
                                    .clipShape(Capsule())
                            }
                        }
                        .padding(.trailing)
                        .onTapGesture {
                            selectedIndex = index
                            
                            if genreName == "すべて" {
                                searchText = ""
                                searchViewModel.searchResults = restaurantViewModel.favoriteShops
                            } else {
                                searchText = genreName
                                searchViewModel.performSearch(genreName)
                            }
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    @Previewable @State var searchText = ""  // 🔹 `@Binding` に渡すための `@State` を用意
    let restaurantViewModel = RestaurantViewModel()
    let searchViewModel = SearchViewModel(restaurantViewModel: restaurantViewModel)
    let likesTabViewModel = LikesTabViewModel(restaurantViewModel: restaurantViewModel)
    
    restaurantViewModel.favoriteShops = [MockShop.mockShop]
    
    return GenreTabBarView(
        likesTabViewModel: likesTabViewModel,
        searchViewModel: searchViewModel,
        restaurantViewModel: restaurantViewModel,
        searchText: $searchText,  // 🔹 `@Binding` に渡す
        isGenreActive: true
    )
}


