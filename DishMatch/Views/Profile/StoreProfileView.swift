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

    /// ジャンル（サブジャンルがあれば併記）
    private var genreDetail: String {
        if let sub = shop.subGenre, !sub.name.isEmpty {
            return "\(shop.genre.name) / \(sub.name)"
        }
        return shop.genre.name
    }

    /// ギャラリーに表示する画像URLの一覧。
    /// HotPepperのメイン写真を先頭に、Google Placesの雰囲気写真を続ける。重複は除いて順序を保つ。
    private var galleryURLs: [String] {
        var urls: [String] = []
        if !shop.photo.pc.l.isEmpty { urls.append(shop.photo.pc.l) }
        urls.append(contentsOf: placeInfo.photoURLs)
        var seen = Set<String>()
        return urls.filter { seen.insert($0).inserted }
    }

    /// 表示する備考（値があるものだけ）
    private var shopMemos: [(title: String, body: String)] {
        let candidates: [(String, String?)] = [
            ("予算の補足", shop.budgetMemo),
            ("お店より", shop.shopDetailMemo),
            ("その他", shop.otherMemo)
        ]
        return candidates.compactMap { title, value in
            guard let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty else { return nil }
            return (title, value)
        }
    }

    /// 設備・特徴のチップ
    private func featureChip(_ feature: ShopFeature) -> some View {
        HStack(spacing: 4) {
            Image(systemName: feature.systemImage)
                .font(.caption2)
            Text(feature.label)
                .font(.caption)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.orange.opacity(0.12), in: Capsule())
        .foregroundStyle(Color("FC"))
    }

    var body: some View {
        ZStack {
            VStack {
                ScrollView {
                    VStack {
                        ZStack(alignment: .topTrailing) {
                            // TabView はコンテンツ由来の固有高さを持たないため、ScrollView内では
                            // 高さを固定しないと潰れる。ここで明示的に高さを与える。
                            TabView(selection: $currentImageIndex) {
                                ForEach(Array(galleryURLs.enumerated()), id: \.offset) { index, url in
                                    CachedShopImage(urlString: url)
                                        .aspectRatio(contentMode: .fill)
                                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                                        .clipped()
                                        .tag(index)
                                }
                            }
                            .tabViewStyle(.page(indexDisplayMode: .never))

                            // 複数枚あるときだけ、現在位置と総枚数を示すカウンターを表示する。
                            // 画像下部は情報カードと重なって隠れるため、重ならない右上に配置する。
                            if galleryURLs.count > 1 {
                                HStack(spacing: 4) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.caption2)
                                    Text("\(min(currentImageIndex, galleryURLs.count - 1) + 1) / \(galleryURLs.count)")
                                        .font(.caption)
                                        .monospacedDigit()
                                }
                                .foregroundStyle(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.black.opacity(0.35), in: Capsule())
                                .padding(.top, 12)
                                .padding(.trailing, 12)
                            }
                        }
                        .frame(height: 500)
                        .frame(maxWidth: .infinity)
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

                            if !shop.shopCatch.isEmpty {
                                Text(shop.shopCatch)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                            }

                            Text("店舗情報  (詳細)")
                                .foregroundStyle(Color("FC"))
                                .fontWeight(.semibold)
                                .padding(.top, 20)
                            Spacer()
                            InfoRow(title: "住所", detail: shop.address)

                            if let access = shop.access, !access.isEmpty {
                                Divider()
                                InfoRow(title: "アクセス", detail: access)
                            }

                            Divider()
                            InfoRow(title: "最寄りの駅", detail: "\(shop.stationName)駅")

                            Divider()
                            InfoRow(title: "ジャンル", detail: genreDetail)

                            Divider()
                            InfoRow(title: "営業時間", detail: shop.open)

                            Divider()
                            InfoRow(title: "定休日", detail: shop.close)

                            Divider()
                            InfoRow(title: "予算", detail: shop.budget?.name ?? "不明")

                            if let average = shop.budget?.average, !average.isEmpty {
                                Divider()
                                InfoRow(title: "平均予算", detail: average)
                            }

                            if let capacity = shop.capacity, capacity > 0 {
                                Divider()
                                InfoRow(title: "席数", detail: "\(capacity)席")
                            }

                            if let nonSmoking = shop.nonSmoking, !nonSmoking.isEmpty {
                                Divider()
                                InfoRow(title: "禁煙・喫煙", detail: nonSmoking)
                            }

                            if let card = shop.card, !card.isEmpty {
                                Divider()
                                InfoRow(title: "カード", detail: card)
                            }

                            if let parking = shop.parking, !parking.isEmpty {
                                Divider()
                                InfoRow(title: "駐車場", detail: parking)
                            }

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

                            // 設備・特徴（利用可能なこだわり条件をチップで一覧表示）
                            if !shop.features.isEmpty {
                                Text("設備・特徴")
                                    .foregroundStyle(Color("FC"))
                                    .fontWeight(.semibold)
                                    .padding(.top, 20)
                                FlowLayout(spacing: 8) {
                                    ForEach(shop.features) { feature in
                                        featureChip(feature)
                                    }
                                }
                                .padding(.top, 4)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }

                            // 備考（予算補足・その他メモ）
                            let memos = shopMemos
                            if !memos.isEmpty {
                                Text("備考")
                                    .foregroundStyle(Color("FC"))
                                    .fontWeight(.semibold)
                                    .padding(.top, 20)
                                ForEach(memos, id: \.title) { memo in
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(memo.title)
                                            .font(.subheadline.bold())
                                            .foregroundColor(Color("FC"))
                                        Text(memo.body)
                                            .font(.subheadline)
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .padding(.vertical, 4)
                                }
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


