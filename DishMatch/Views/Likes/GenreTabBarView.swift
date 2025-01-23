//
//  GenreTabBarView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct GenreTabBarView: View {
    @State private var selectedIndex: Int = 0
    @ObservedObject var LikesViewModel: LikesViewModel
    let isGenreActive: Bool

    var body: some View {
        VStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    // LikesViewModelに基づいてuniqueStoresを表示
                    ForEach(LikesViewModel.uniqueStores.indices, id: \.self) { index in
                        let store = LikesViewModel.uniqueStores[index]
                        
                        VStack(alignment: .leading) {
                            Text(store.genre)
                                .font(.system(size: 18))
                                .fontWeight(.semibold)
                                .foregroundColor(index == selectedIndex && isGenreActive ? Color(.orange) : Color.black.opacity(0.5))
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
            LikesViewModel.updateStores(LikesViewModel.uniqueStores)
        }
    }
}

#Preview {
    GenreTabBarView(LikesViewModel: LikesViewModel(stores: MockData.stores), isGenreActive: true)
}
