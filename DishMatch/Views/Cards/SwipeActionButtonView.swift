//
//  SwipeActionButtonView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct SwipeActionButtonView: View {
    @ObservedObject var restaurantViewModel: RestaurantViewModel
    
    var body: some View {
        HStack (spacing: 32) {
            Button {
                restaurantViewModel.buttonSwipeAction = .rejetct
                
            } label: {
                Image(systemName: "xmark")
                    .fontWeight(.heavy)
                    .foregroundStyle(.gray)
                    .background {
                        Circle()
                            .fill(Color("BG"))
                            .frame(width: 48, height: 48)
                            .shadow(radius: 6)
                    }
                    
            }
            .frame(width: 48, height: 48)
            Button {
                restaurantViewModel.buttonSwipeAction = .like
            } label: {
                Image(systemName: "heart.fill")
                    .fontWeight(.heavy)
                    .foregroundStyle(.orange)
                    .background {
                        Circle()
                            .fill(Color("BG"))
                            .frame(width: 48, height: 48)
                            .shadow(radius: 6)
                    }
            }
            .frame(width: 48, height: 48)
        }
    }
}

#Preview {
    let restaurantViewModel = RestaurantViewModel()
    restaurantViewModel.buttonSwipeAction = .like // プレビュー用の初期状態
    return SwipeActionButtonView(restaurantViewModel: restaurantViewModel)
}

