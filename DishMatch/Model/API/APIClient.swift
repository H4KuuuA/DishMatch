
//
//  APIClient.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/24.
//

import Foundation

final class APIClient {
    private let pageSize = 20
    
    func fetchRestaurantData(keyword: String?, range: String, genre: String?, startIndex: Int) async throws -> StoreDataModel {
        guard let url = createAPIRequestURL(keyword: keyword, range: range, genre: genre, startIndex: startIndex) else {
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
    
    private func createAPIRequestURL(keyword: String?, range: String, genre: String?, startIndex: Int) -> URL? {
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

        urlComponents?.queryItems = queryItems
        return urlComponents?.url
    }
    
    private func decodeAPIResponse(responseData: Data) throws -> StoreDataModel {
        let decoder = JSONDecoder()
        return try decoder.decode(StoreDataModel.self, from: responseData)
    }
}
