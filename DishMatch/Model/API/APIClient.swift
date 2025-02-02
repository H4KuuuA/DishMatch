
//
//  APIClient.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/24.
//

import Foundation

final class APIClient {
    private let pageSize = 20
    
    /// レストランデータを取得
    func fetchRestaurantData(keyword: String?, range: String, genre: String?, budget: String?, startIndex: Int) async throws -> RestaurantDataModel {
        guard let url = createAPIRequestURL(keyword: keyword, range: range, genre: genre, budget: budget, startIndex: startIndex) else {
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
    private func createAPIRequestURL(keyword: String?, range: String, genre: String?, budget: String?, startIndex: Int) -> URL? {
        let locationManager = LocationManager.shared
        let keyManager = KeyManager()
        let baseURL = URL(string: "https://webservice.recruit.co.jp/hotpepper/gourmet/v1")
        let apiKey = keyManager.getValue(forKey: "apiKey")
        let format = "json"
        
        var urlComponents = URLComponents(url: baseURL!, resolvingAgainstBaseURL: true)
        
        let latitude = String(format: "%.6f", locationManager.latitude)
        let longitude = String(format: "%.6f", locationManager.longitude)

        var queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "lat", value: latitude),
            URLQueryItem(name: "lng", value: longitude),
            URLQueryItem(name: "format", value: format),
            URLQueryItem(name: "count", value: "\(pageSize)"),
            URLQueryItem(name: "range", value: range),
            URLQueryItem(name: "start", value: "\(startIndex)")
        ]

        if let keyword {
            queryItems.append(URLQueryItem(name: "keyword", value: keyword))
        }
        
        if let genre {
            queryItems.append(URLQueryItem(name: "genre", value: genre))
        }
        
        if let budget, !budget.isEmpty {
            queryItems.append(URLQueryItem(name: "budget", value: budget))
        }

        urlComponents?.queryItems = queryItems
        return urlComponents?.url
    }
    
    /// APIレスポンスをデコード
    private func decodeAPIResponse(responseData: Data) throws -> RestaurantDataModel {
        let decoder = JSONDecoder()
        return try decoder.decode(RestaurantDataModel.self, from: responseData)
    }
}
