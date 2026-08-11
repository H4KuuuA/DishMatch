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
    /// ギャラリーに使う雰囲気写真の最大枚数。多すぎても表示が冗長になるので上限を設ける。
    private static let maxPhotos = 8
    /// Photo media で要求する画像の最大幅（px）。詳細画面の表示サイズに十分な解像度。
    private static let photoMaxWidthPx = 800

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
        // フィールドマスクを絞ることで課金対象の項目を必要最小限にする。
        // 写真メタデータ(places.photos)は既存の評価取得と同じ1リクエストにまとめるため、
        // API呼び出し回数は増えない（＝追加の呼び出し課金は発生しない）。
        request.setValue(
            "places.nationalPhoneNumber,places.internationalPhoneNumber,places.rating,places.userRatingCount,places.photos",
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
        let photoURLs = Self.buildPhotoURLs(from: place.photos, apiKey: apiKey)
        let ratingDescription = place.rating.map { String(format: "%.1f", $0) } ?? "なし"
        print("DEBUG: Google Places 取得結果 - 電話番号: \(phoneNumber ?? "なし"), 評価: \(ratingDescription), 写真: \(photoURLs.count)枚")
        return GooglePlaceInfo(phoneNumber: phoneNumber, rating: place.rating, userRatingCount: place.userRatingCount, photoURLs: photoURLs)
    }

    /// 写真メタデータから Photo media エンドポイントの実画像URLを組み立てる。
    /// 各URLはリダイレクトで実画像を返すため、そのまま画像ビューに渡して表示できる。
    private static func buildPhotoURLs(from photos: [GooglePlacePhoto]?, apiKey: String) -> [String] {
        guard let photos else { return [] }
        return photos.prefix(maxPhotos).map { photo in
            "https://places.googleapis.com/v1/\(photo.name)/media?maxWidthPx=\(photoMaxWidthPx)&key=\(apiKey)"
        }
    }
}
