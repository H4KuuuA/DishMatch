//
//  APIClient.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/24.
//

import Foundation

final class APIClient {
    func fetchRestaurantData(keyword: String?, range: String, genre: String?) async throws -> StoreDataModel {
        guard let url = createAPIRequestURL(keyword: keyword, range: range, genre: genre) else {
            throw APIError.failCreateURL
        }
        
        print("DEBUG: APIリクエストURL: \(url.absoluteString)")
        let locationManager = LocationManager.shared
        print("リクエスト時の緯度: \(locationManager.latitude), 経度: \(locationManager.longitude), 検索範囲: \(range)")
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        if let httpResponse = response as? HTTPURLResponse {
            print("HTTPステータスコード: \(httpResponse.statusCode)") // ステータスコードを確認
        }
        
        if let jsonString = String(data: data, encoding: .utf8) {
            print("APIレスポンスのJSON:\n\(jsonString)") // JSONレスポンスを確認
        }
        
        return try decodeAPIResponse(responseData: data)
    }
    
    
    
    private func createAPIRequestURL(keyword: String?, range: String, genre: String?) -> URL? {
        let locationManager = LocationManager.shared
        let keyManager = KeyManager()
        let baseURL: URL? = URL(string: "https://webservice.recruit.co.jp/hotpepper/gourmet/v1")
        let apiKey = keyManager.getValue(forKey: "apiKey")
        let format = "json"
        var urlComponents = URLComponents(url: baseURL!, resolvingAgainstBaseURL: true)
        
        let latitude = String(format: "%.6f", locationManager.latitude) // 小数点以下6桁に制限
        let longitude = String(format: "%.6f", locationManager.longitude) // 小数点以下6桁に制限
        
        var queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "lat", value: latitude),
            URLQueryItem(name: "lng", value: longitude),
            URLQueryItem(name: "format", value: format),
            URLQueryItem(name: "count", value: "20"),
            URLQueryItem(name: "range", value: range),
        ]
        
        if let keyword {
            queryItems.append(URLQueryItem(name: "keyword", value: keyword))
        }
        
        if let genre {
            queryItems.append(URLQueryItem(name: "genre", value: genre))
        }
        
        urlComponents?.queryItems = queryItems
        return urlComponents?.url
    }
    
    
    
    private func decodeAPIResponse(responseData: Data) throws -> StoreDataModel {
        let decoder = JSONDecoder()
        return try decoder.decode(StoreDataModel.self, from: responseData)
    }
}
