//
//  CardStackView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct CardStackView: View {
    @StateObject var viewModel = CardsViewModel(service: CardService())
    
    var body: some View {
        NavigationStack {
            VStack (spacing: 16){
                ZStack {
                    ForEach(viewModel.cardModels) { card in
                        CardView(viewModel: viewModel, model: card)
                    }
                }
                
                // カードがなくなった時にボタンの位置が変わるのを防ぐ
                if !viewModel.cardModels.isEmpty {
                    HStack (spacing: 32){
                        BackCardButtonView(viewModel: viewModel)
                        SwipeActionButtonView(viewModel: viewModel)
                        DiscoverSettingsButtonView()
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Text("Dish")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.orange)
                    + Text("Match")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                }
            }
        }
    }
}

#Preview {
    CardStackView()
}
