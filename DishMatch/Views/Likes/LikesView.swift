//
//  LikesView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct LikesView: View {
    @StateObject var viewModel = CardsViewModel()
    
    var body: some View {
        VStack {
            TextFieldLikeView()
            GenreTabBarView(LikesViewModel: LikesViewModel(stores: MockData.stores), isGenreActive: true)
            LikeShopsListView(viewModel: viewModel)
        }
    }
}

#Preview {
    LikesView()
}
