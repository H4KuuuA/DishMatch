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
                        AsyncImage(url: URL(string: shop.photo.pc.l)) { phase in
                            switch phase {
                            case .empty:
                                // ローディング中のプレースホルダー
                                ProgressView()
                                    .frame(maxWidth: .infinity, maxHeight: 500)
                                    .background(Color.gray.opacity(0.3))
                            case .success(let image):
                                // 正常に画像が取得できた場合
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity, maxHeight: 500)
                                    .clipped()
                            case .failure:
                                // エラー時の代替画像
                                Image(systemName: "photo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                                    .frame(maxWidth: .infinity, maxHeight: 500)
                                    .background(Color.gray.opacity(0.3))
                                    .clipped()
                            @unknown default:
                                EmptyView()
                            }
                        }

                        // 店舗情報
                        VStack(alignment: .leading, spacing: 8) {
                            HStack {
                                Text(shop.name) // 店舗名
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .padding(.top, 15)
                                Spacer()
                                ProfileDismissButtonView()
                                    .padding(.horizontal)
                            }

                            HStack {
                                Image(systemName: "fork.knife")
                                Text("\(shop.genre.name)") // ジャンル名

                                Text("|")
                                Image(systemName: "mappin.and.ellipse")
                                Text("\(shop.mobile_access)") // 最寄り駅名
                            }
                            .foregroundStyle(Color("FC"))
                            .font(.caption)
                            .lineLimit(2)
                            
                            Text("店舗情報  (詳細)")
                                .foregroundStyle(Color("FC"))
                                .fontWeight(.semibold)
                                .padding(.top, 20)
                            Spacer()
                            InfoRow(title: "住所", detail: shop.address)
                            
                            Divider()
                            InfoRow(title: "最寄りの駅", detail: "\(shop.stationName)駅")
                            
                            Divider()
                            InfoRow(title: "営業時間", detail: shop.open)
                                
                            Divider()
                            InfoRow(title: "定休日", detail: shop.close)
                                
                            Divider()
                            InfoRow(title: "予算", detail: shop.budget?.name ?? "不明")
                                
                            Divider()
                            // HPリンク
                            if let url = URL(string: shop.urls.pc) {
                                HStack {
                                    Text("お店のHP")
                                        .foregroundColor(Color("FC"))
                                        .font(.headline)
                                        .frame(width: 80, alignment: .leading)
                                        .padding(.trailing)
                                    Link("リンクはこちら", destination: url)
                                        .foregroundColor(.blue)
                                    Spacer()
                                }
                                .padding(.vertical, 6)
                            }
                            Spacer()
                            Spacer()
                        }
                        .padding()
                        .background(Color("WB"))
                        .cornerRadius(40)
                        .offset(y: -35)

                        
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


