//
//  BackCardButtonView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct ResetCardButtonView: View {
    @ObservedObject var restaurantViewModel: RestaurantViewModel
    @Binding var viewID: UUID // ビュー更新用の識別子

    var body: some View {
        Button {
            viewID = UUID() // カードスタックの表示状態をリセット
            // `.onChange(of: viewID)`という間接的なトリガーだけに頼ると、`.id()`による
            // View再構築のタイミングと絡んで確実に発火しないことがあるため、直接呼び出す
            restaurantViewModel.fetchShops(startIndex: 1)
        } label: {
            Image(systemName: "arrow.counterclockwise")
                .fontWeight(.heavy)
                .foregroundStyle(.yellow)
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

#Preview {
    ResetCardButtonView(restaurantViewModel: RestaurantViewModel(friendsViewModel: FriendsViewModel()), viewID: .constant(UUID()))
}

