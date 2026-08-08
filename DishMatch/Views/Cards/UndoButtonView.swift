//
//  UndoButtonView.swift
//  DishMatch
//
//  Created by Claude on 2026/08/07.
//

import SwiftUI

/// 直前のスワイプ（Like/None）を取り消し、お店をカードスタックの一番上に戻すボタン。
/// 「間違えてNoneしてしまった」を取り消せるようにする。
struct UndoButtonView: View {
    @ObservedObject var restaurantViewModel: RestaurantViewModel

    var body: some View {
        Button {
            restaurantViewModel.undoLastSwipe()
        } label: {
            Image(systemName: "arrow.uturn.backward")
                .fontWeight(.heavy)
                .foregroundStyle(restaurantViewModel.canUndoLastSwipe ? Color.gray : Color.gray.opacity(0.3))
                .background {
                    Circle()
                        .fill(Color("BG"))
                        .frame(width: 48, height: 48)
                        .shadow(radius: 6)
                }
        }
        .frame(width: 48, height: 48)
        .disabled(!restaurantViewModel.canUndoLastSwipe)
    }
}

#Preview {
    UndoButtonView(restaurantViewModel: RestaurantViewModel(friendsViewModel: FriendsViewModel()))
}
