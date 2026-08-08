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
}

/// Google Placesから取得した、HotPepperのレスポンスには無い補足情報
struct GooglePlaceInfo {
    let phoneNumber: String?
    let rating: Double?
    let userRatingCount: Int?
}
