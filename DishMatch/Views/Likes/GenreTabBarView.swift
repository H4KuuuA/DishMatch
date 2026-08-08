//
//  GenreTabBarView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct GenreTabBarView: View {
    @ObservedObject var likesTabViewModel: LikesTabViewModel
    @ObservedObject var searchViewModel: SearchViewModel
    @ObservedObject var restaurantViewModel: RestaurantViewModel

    @State private var selectedGenre: String = "すべて"
    @State private var isShowAllGenres = false

    @Binding var searchText: String

    let isGenreActive: Bool

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(likesTabViewModel.genreTabs, id: \.self) { genreName in
                    tabItem(genreName)
                        .padding(.trailing)
                        .onTapGesture {
                            select(genreName)
                        }
                }

                // タブに収まらないジャンルがある時だけ、汎用的な一覧画面への入口を出す
                if likesTabViewModel.allGenreNames.count > GenreTabBarView.visibleGenreCount(in: likesTabViewModel) {
                    moreTabItem
                        .onTapGesture {
                            isShowAllGenres = true
                        }
                }
            }
            .padding(.horizontal)
        }
        .sheet(isPresented: $isShowAllGenres) {
            GenreFilterListView(
                genreNames: likesTabViewModel.allGenreNames,
                selectedGenre: selectedGenre
            ) { genreName in
                select(genreName)
            }
        }
    }

    private func tabItem(_ genreName: String) -> some View {
        let isSelected = genreName == selectedGenre && isGenreActive
        return VStack(alignment: .leading) {
            Text(genreName)
                .font(.system(size: 18))
                .fontWeight(.semibold)
                .lineLimit(1)
                .foregroundColor(isSelected ? Color(.orange) : Color("FC").opacity(0.6))

            if isSelected {
                Color(.orange)
                    .frame(width: 15, height: 2)
                    .clipShape(Capsule())
            }
        }
    }

    /// 「もっと見る」タブ。ジャンルの詳細な絞り込みへの汎用的な入口として、
    /// 固定文言ではなく他のタブと同じ見た目のパターンで表現する
    private var moreTabItem: some View {
        VStack(alignment: .leading) {
            HStack(spacing: 2) {
                Text("もっと見る")
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
            }
            .font(.system(size: 18))
            .fontWeight(.semibold)
            .foregroundColor(Color("FC").opacity(0.6))
        }
    }

    private func select(_ genreName: String) {
        selectedGenre = genreName
        if genreName == "すべて" {
            searchText = ""
            searchViewModel.searchResults = restaurantViewModel.favoriteShops
        } else {
            searchText = genreName
            searchViewModel.performSearch(genreName)
        }
    }

    private static func visibleGenreCount(in viewModel: LikesTabViewModel) -> Int {
        viewModel.genreTabs.count - 1 // 「すべて」を除いた実ジャンル数
    }
}

#Preview {
    @Previewable @State var searchText = ""
    let restaurantViewModel = RestaurantViewModel(friendsViewModel: FriendsViewModel())
    let searchViewModel = SearchViewModel(restaurantViewModel: restaurantViewModel)
    let likesTabViewModel = LikesTabViewModel(restaurantViewModel: restaurantViewModel)

    restaurantViewModel.favoriteShops = [MockShop.mockShop]

    return GenreTabBarView(
        likesTabViewModel: likesTabViewModel,
        searchViewModel: searchViewModel,
        restaurantViewModel: restaurantViewModel,
        searchText: $searchText,
        isGenreActive: true
    )
}
