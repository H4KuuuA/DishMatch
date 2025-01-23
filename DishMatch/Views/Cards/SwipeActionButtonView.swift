//
//  SwipeActionButtonView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct SwipeActionButtonView: View {
    
    @ObservedObject var viewModel: CardsViewModel
    
    var body: some View {
        HStack (spacing: 32) {
            Button {
                viewModel.buttonSwipeAction = .like
            } label: {
                Image(systemName: "xmark")
                    .fontWeight(.heavy)
                    .foregroundStyle(.gray)
                    .background {
                        Circle()
                            .fill(.white)
                            .frame(width: 48, height: 48)
                            .shadow(radius: 6)
                    }
                    
            }
            .frame(width: 48, height: 48)
            Button {
                viewModel.buttonSwipeAction = .rejetct
            } label: {
                Image(systemName: "heart.fill")
                    .fontWeight(.heavy)
                    .foregroundStyle(.orange)
                    .background {
                        Circle()
                            .fill(.white)
                            .frame(width: 48, height: 48)
                            .shadow(radius: 6)
                    }
            }
            .frame(width: 48, height: 48)
        }
    }
}

#Preview {
    SwipeActionButtonView(viewModel: CardsViewModel(service: CardService()))
}
