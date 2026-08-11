//
//  GooglePlacesDataModel.swift
//  DishMatch
//
//  Created by Claude on 2026/08/07.
//

import Foundation

/// Places API (New) の Text Search へのリクエストボディ
struct GooglePlacesTextSearchRequest: Encodable {
    let textQuery: String
}

/// Places API (New) の Text Search レスポンス
struct GooglePlacesTextSearchResponse: Decodable {
    let places: [GooglePlace]?
}

struct GooglePlace: Decodable {
    let nationalPhoneNumber: String?
    let internationalPhoneNumber: String?
    /// 5点満点の評価
    let rating: Double?
    /// 評価の件数
    let userRatingCount: Int?
    /// お店の写真メタデータ（雰囲気写真のギャラリー用）
    let photos: [GooglePlacePhoto]?
}

/// Places API (New) の写真メタデータ。
/// `name` は "places/{placeId}/photos/{photoRef}" 形式のリソース名で、
/// これを Photo media エンドポイントに渡して実画像URLを組み立てる。
struct GooglePlacePhoto: Decodable {
    let name: String
}

/// Google Placesから取得した、HotPepperのレスポンスには無い補足情報
struct GooglePlaceInfo {
    let phoneNumber: String?
    let rating: Double?
    let userRatingCount: Int?
    /// お店の雰囲気写真URL（実画像を返す Photo media エンドポイントのURL）。多い順・最大数は取得側で制限する。
    let photoURLs: [String]
}
