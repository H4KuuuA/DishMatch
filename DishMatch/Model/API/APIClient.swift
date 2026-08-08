
//
//  APIClient.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/24.
//

import Foundation

final class APIClient: Sendable {
    private let pageSize = 20

    /// レストランデータを取得
    /// - Parameters:
    ///   - range: 現在地からの検索範囲（1〜5）。`serviceAreaCode`を指定する場合は使われないのでnilでよい
    ///   - particulars: 飲み放題・食べ放題・個室・座敷・駐車場などの「こだわり」条件
    ///   - serviceAreaCode: 都道府県相当のエリアコード。指定すると現在地の代わりにこのエリアで検索する
    func fetchRestaurantData(keyword: String?, range: String?, genre: String?, budget: String?, particulars: DiscoveryParticulars = .none, serviceAreaCode: String? = nil, startIndex: Int) async throws -> RestaurantDataModel {
        guard let url = await createAPIRequestURL(keyword: keyword, range: range, genre: genre, budget: budget, particulars: particulars, serviceAreaCode: serviceAreaCode, startIndex: startIndex) else {
            throw APIError.failCreateURL
        }
        print("DEBUG: APIリクエストURL: \(url.absoluteString)")

        let (data, response) = try await URLSession.shared.data(from: url)

        if let httpResponse = response as? HTTPURLResponse {
            print("HTTPステータスコード: \(httpResponse.statusCode)")
        }

        if let jsonString = String(data: data, encoding: .utf8) {
            print("APIレスポンスのJSON:\n\(jsonString)")
        }

        return try decodeAPIResponse(responseData: data)
    }

    /// APIリクエストURLを作成
    @MainActor
    private func createAPIRequestURL(keyword: String?, range: String?, genre: String?, budget: String?, particulars: DiscoveryParticulars, serviceAreaCode: String?, startIndex: Int) -> URL? {
        let keyManager = KeyManager()
        let baseURL = URL(string: "https://webservice.recruit.co.jp/hotpepper/gourmet/v1")
        let apiKey = keyManager.getValue(forKey: "apiKey")
        let format = "json"

        var urlComponents = URLComponents(url: baseURL!, resolvingAgainstBaseURL: true)

        var queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "format", value: format),
            URLQueryItem(name: "count", value: "\(pageSize)"),
            URLQueryItem(name: "start", value: "\(startIndex)")
        ]

        if let serviceAreaCode {
            // エリア指定検索：現在地は使わず、都道府県相当のエリアコードで絞り込む
            queryItems.append(URLQueryItem(name: "service_area", value: serviceAreaCode))
        } else {
            // 現在地検索：位置情報と検索範囲を使う
            let locationManager = LocationManager.shared
            let latitude = String(format: "%.6f", locationManager.latitude)
            let longitude = String(format: "%.6f", locationManager.longitude)
            queryItems.append(URLQueryItem(name: "lat", value: latitude))
            queryItems.append(URLQueryItem(name: "lng", value: longitude))
            if let range {
                queryItems.append(URLQueryItem(name: "range", value: range))
            }
        }

        if let keyword {
            queryItems.append(URLQueryItem(name: "keyword", value: keyword))
        }

        if let genre {
            queryItems.append(URLQueryItem(name: "genre", value: genre))
        }

        if let budget, !budget.isEmpty {
            queryItems.append(URLQueryItem(name: "budget", value: budget))
        }

        queryItems.append(contentsOf: particulars.queryItems)

        urlComponents?.queryItems = queryItems
        return urlComponents?.url
    }

    /// APIレスポンスをデコード
    private func decodeAPIResponse(responseData: Data) throws -> RestaurantDataModel {
        let decoder = JSONDecoder()
        return try decoder.decode(RestaurantDataModel.self, from: responseData)
    }

    /// ジャンルマスタ（選択可能なジャンル一覧）を取得する
    func fetchGenres() async throws -> [GenreOption] {
        let keyManager = KeyManager()
        guard let baseURL = URL(string: "https://webservice.recruit.co.jp/hotpepper/genre/v1/") else {
            throw APIError.failCreateURL
        }
        var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        urlComponents?.queryItems = [
            URLQueryItem(name: "key", value: keyManager.getValue(forKey: "apiKey")),
            URLQueryItem(name: "format", value: "json")
        ]
        guard let url = urlComponents?.url else {
            throw APIError.failCreateURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(GenreMasterDataModel.self, from: data)
        return decoded.results.genre
    }

    /// サービスエリアマスタ（都道府県相当の選択肢一覧）を取得する
    func fetchServiceAreas() async throws -> [ServiceAreaOption] {
        let keyManager = KeyManager()
        guard let baseURL = URL(string: "https://webservice.recruit.co.jp/hotpepper/service_area/v1/") else {
            throw APIError.failCreateURL
        }
        var urlComponents = URLComponents(url: baseURL, resolvingAgainstBaseURL: true)
        urlComponents?.queryItems = [
            URLQueryItem(name: "key", value: keyManager.getValue(forKey: "apiKey")),
            URLQueryItem(name: "format", value: "json")
        ]
        guard let url = urlComponents?.url else {
            throw APIError.failCreateURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)
        let decoded = try JSONDecoder().decode(ServiceAreaMasterDataModel.self, from: data)
        return decoded.results.serviceArea
    }
}
