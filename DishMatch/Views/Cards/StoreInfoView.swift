//
//  StoreInfoView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/22.
//

import SwiftUI

struct StoreInfoView: View {
    @Binding var isShowProfileModal: Bool

    let shop: Shop 

    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text(shop.name) // 店舗名
                    .font(.title)
                    .fontWeight(.heavy)

                Spacer()

                // プロフィール表示ボタン
                Button {
                    isShowProfileModal.toggle()
                } label: {
                    Image(systemName: "arrow.up.circle")
                        .fontWeight(.bold)
                        .imageScale(.large)
                }
            }
            HStack {
                Image(systemName: "fork.knife")
                Text("\(shop.genre.name)") // ジャンル名

                Text("|")
                Image(systemName: "mappin.and.ellipse")
                Text("\(shop.mobile_access)") // 最寄り駅名
            }
            .font(.subheadline)
            .lineLimit(2)
        }
        .padding()
        .background(
            LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
        )
        .foregroundStyle(.white)
    }
}

#Preview {
    StoreInfoView(isShowProfileModal: .constant(false), shop: MockShop.mockShop)
}

