//
//  GooglePlacesClient.swift
//  DishMatch
//
//  Created by Claude on 2026/08/07.
//

import Foundation

enum GooglePlacesError: Error {
    /// APIKey.plistの`googlePlacesApiKey`が未設定（空文字列）の場合
    case missingAPIKey
    case invalidURL
    case notFound
}

/// HotPepperのレスポンスには電話番号や評価が含まれていないため、店名・住所をもとに
/// Google Places API (New) のText Searchで補完取得するクライアント。
/// 一般的な飲食店検索アプリが自社DB以外の情報源から情報を補っているのと同じ役割。
///
/// APIコストを抑えるため、電話番号と評価は必ずこの1回のリクエストでまとめて取得する
/// （記事詳細画面を開いた時だけ呼び出し、カード一覧のスワイプ中には呼ばない）。
final class GooglePlacesClient: Sendable {
    private static let searchURL = URL(string: "https://places.googleapis.com/v1/places:searchText")!

    /// 店名と住所からお店の補足情報（電話番号・評価）を検索する。見つからない場合はnilを返す
    func fetchPlaceInfo(shopName: String, address: String) async throws -> GooglePlaceInfo? {
        let keyManager = KeyManager()
        guard let apiKey = keyManager.getValue(forKey: "googlePlacesApiKey"), !apiKey.isEmpty else {
            throw GooglePlacesError.missingAPIKey
        }

        var request = URLRequest(url: Self.searchURL)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue(apiKey, forHTTPHeaderField: "X-Goog-Api-Key")
        // フィールドマスクを絞ることで課金対象の項目を必要最小限にする
        request.setValue(
            "places.nationalPhoneNumber,places.internationalPhoneNumber,places.rating,places.userRatingCount",
            forHTTPHeaderField: "X-Goog-FieldMask"
        )

        let body = GooglePlacesTextSearchRequest(textQuery: "\(shopName) \(address)")
        request.httpBody = try JSONEncoder().encode(body)

        let (data, response) = try await URLSession.shared.data(for: request)
        if let httpResponse = response as? HTTPURLResponse {
            print("DEBUG: Google Places APIステータスコード \(httpResponse.statusCode)")
        }
        if let jsonString = String(data: data, encoding: .utf8) {
            print("DEBUG: Google Places APIレスポンス本文: \(jsonString)")
        }

        let decoded = try JSONDecoder().decode(GooglePlacesTextSearchResponse.self, from: data)
        guard let place = decoded.places?.first else {
            print("DEBUG: Google Places 該当店舗なし（textQuery: \"\(shopName) \(address)\"）")
            return nil
        }

        let phoneNumber = place.nationalPhoneNumber ?? place.internationalPhoneNumber
        let ratingDescription = place.rating.map { String(format: "%.1f", $0) } ?? "なし"
        print("DEBUG: Google Places 取得結果 - 電話番号: \(phoneNumber ?? "なし"), 評価: \(ratingDescription)")
        return GooglePlaceInfo(phoneNumber: phoneNumber, rating: place.rating, userRatingCount: place.userRatingCount)
    }
}
