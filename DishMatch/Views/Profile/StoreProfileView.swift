//
//  StoreProfileView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

//
//  StoreProfileView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

struct StoreProfileView: View {
    @State private var currentImageIndex: Int = 0

    let shop: Shop // `Shop` を直接使用

    var body: some View {
        ZStack {
            VStack {
                ScrollView {
                    VStack {
                        Image(shop.photo.mobile.l) // `Shop` の画像URLを使用
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: 300) // 画像のサイズ設定

                        // 店舗情報
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(shop.name) // 店舗名
                                    .font(.title)
                                    .fontWeight(.semibold)
                                    .padding(.top, 15)
                                Spacer()
                            }

                            HStack {
                                Image(systemName: "fork.knife")
                                Text("\(shop.genre.name)") // ジャンル名

                                Text("|")
                                Image(systemName: "mappin.and.ellipse")
                                Text("\(shop.stationName)") // 最寄り駅名
                            }
                            .foregroundStyle(Color("FC"))
                            .font(.caption)
                            .lineLimit(2)

                            Text("店舗情報  (詳細)")
                                .foregroundStyle(Color("FC"))
                                .fontWeight(.semibold)
                                .padding(.top, 20)

                            Spacer()
                        }
                        .padding()
                        .background(Color("WB"))
                        .cornerRadius(40)
                        .offset(y: -30)

                        ProfileDismissButtonView()
                            .offset(x: 145, y: -210)
                    }
                }
            }
            // ReserveButtonViewは常に画面下部に固定
            VStack {
                Spacer()
                ReserveButtonView()
                    .edgesIgnoringSafeArea(.bottom)
            }
        }
        .background(Color("WB"))
    }
}

#Preview {
    // MockShop を使用してプレビュー
    StoreProfileView(shop: MockShop.mockShop)
}


