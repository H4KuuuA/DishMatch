//
//  StoreProfileView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//


import SwiftUI

struct StoreProfileView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var currentImageIndex: Int = 0
    @State private var dragOffset: CGFloat = 0
    // 電話番号と評価をまとめて1回のGoogle Places APIリクエストで取得し、
    // 下部の予約ボタン・評価表示の両方で共有する
    @StateObject private var placeInfo = GooglePlaceInfoViewModel()

    /// この値を超えて下にドラッグした状態で指を離すとdismissする
    private let dismissThreshold: CGFloat = 140

    let shop: Shop // `Shop` を直接使用

    var body: some View {
        ZStack {
            VStack {
                ScrollView {
                    VStack {
                        CachedShopImage(urlString: shop.photo.pc.l)
                            .aspectRatio(contentMode: .fill)
                            .frame(maxWidth: .infinity, maxHeight: 500)
                            .background(Color.gray.opacity(0.3))
                            .clipped()

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

                            // 評価（Google Placesから取得。見つからない場合は表示しない）
                            if let rating = placeInfo.rating {
                                RatingStarsView(rating: rating, userRatingCount: placeInfo.userRatingCount)
                            } else if placeInfo.isLoading {
                                HStack(spacing: 4) {
                                    ProgressView()
                                        .controlSize(.mini)
                                    Text("評価を確認中…")
                                        .font(.caption2)
                                        .foregroundStyle(.gray)
                                }
                            }

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
                ReserveButtonView(shop: shop, placeInfo: placeInfo)
                    .edgesIgnoringSafeArea(.bottom)
            }
        }
        .background(Color("WB"))
        .onAppear {
            placeInfo.lookup(shopName: shop.name, address: shop.address)
        }
        // 上から下にスワイプした分だけViewを追従させ、指を離した時点で
        // 一定距離を超えていればdismissする（fullScreenCoverは標準では
        // 下スワイプで閉じられないため、独自にジェスチャーを実装している）
        .offset(y: dragOffset)
        // ScrollViewの内蔵ジェスチャーと共存させるためsimultaneousGestureを使う
        .simultaneousGesture(
            DragGesture(minimumDistance: 20)
                .onChanged { value in
                    guard value.translation.height > 0 else { return }
                    dragOffset = value.translation.height
                }
                .onEnded { value in
                    let isFastFlick = value.predictedEndTranslation.height > dismissThreshold * 2
                    if value.translation.height > dismissThreshold || isFastFlick {
                        dismiss()
                    } else {
                        withAnimation(.interactiveSpring()) {
                            dragOffset = 0
                        }
                    }
                }
        )
    }
}

#Preview {
    // MockShop を使用してプレビュー
    StoreProfileView(shop: MockShop.mockShop)
}


