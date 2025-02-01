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
    let isGenreActive: Bool

    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    // LikesViewModelに基づいてuniqueStoresを表示
                    ForEach(likesTabViewModel.uniqueStores.indices, id: \.self) { index in
                        let store = likesTabViewModel.uniqueStores[index]
                        
                        VStack(alignment: .leading) {
                            Text(store.genre)
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
                            // タップされたインデックスを選択
                            selectedIndex = index
                        }
                    }
                }
            }
            .padding(.horizontal)
        }
        .onAppear {
            // 初回表示時にuniqueStoresを設定
            likesTabViewModel.updateStores(likesTabViewModel.uniqueStores)
        }
    }
}

#Preview {
    GenreTabBarView(likesTabViewModel: LikesTabViewModel(stores: MockData.stores), isGenreActive: true)
}
