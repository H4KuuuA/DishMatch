//
//  GooglePlaceInfoViewModel.swift
//  DishMatch
//
//  Created by Claude on 2026/08/07.
//

import Foundation

/// 店舗詳細画面で、HotPepperには無い電話番号・評価をGoogle Places APIから取得する。
/// APIコストを抑えるため、この検索は記事詳細画面を開いた時に1回だけ行う
/// （カード一覧のスワイプ中には呼ばない）。
@MainActor
final class GooglePlaceInfoViewModel: ObservableObject {
    @Published private(set) var phoneNumber: String?
    @Published private(set) var rating: Double?
    @Published private(set) var userRatingCount: Int?
    @Published private(set) var isLoading = false
    @Published private(set) var lookupFailed = false

    private let client = GooglePlacesClient()
    private var hasStartedLookup = false

    func lookup(shopName: String, address: String) {
        guard !hasStartedLookup else { return }
        hasStartedLookup = true
        isLoading = true
        lookupFailed = false
        Task {
            do {
                let info = try await client.fetchPlaceInfo(shopName: shopName, address: address)
                phoneNumber = info?.phoneNumber
                rating = info?.rating
                userRatingCount = info?.userRatingCount
                lookupFailed = info == nil
            } catch {
                print("DEBUG: Google Places情報取得エラー \(error.localizedDescription)")
                lookupFailed = true
            }
            isLoading = false
        }
    }
}
