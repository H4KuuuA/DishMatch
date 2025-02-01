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
    @ObservedObject var restaurantViewModel: RestaurantViewModel
    
    let isGenreActive: Bool

    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    // LikesTabViewModelに基づいてuniqueShopsを表示
                    ForEach(likesTabViewModel.uniqueShops.indices, id: \.self) { index in
                        let shop = likesTabViewModel.uniqueShops[index]
                        
                        VStack(alignment: .leading) {
                            Text(shop.genre.name)
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
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    GenreTabBarView(likesTabViewModel: LikesTabViewModel(restaurantViewModel: RestaurantViewModel()), restaurantViewModel: RestaurantViewModel(), isGenreActive: true)
}
