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
                    // ここではまだ、LikesViewModelを使用しない
                    Text("Initial Tab View")
                        .font(.system(size: 18))
                }
            }
            .padding(.horizontal)
        }
    }
}

#Preview {
    GenreTabBarView(LikesViewModel: LikesViewModel(stores: MockData.stores), isGenreActive: true)
}
