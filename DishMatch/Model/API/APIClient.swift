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
        
        let (data, _) = try await URLSession.shared.data(from: url)
        return try decodeAPIResponse(responseData: data)
    }
    
    private func createAPIRequestURL(keyword: String?, range: String, genre: String?) -> URL? {
        let locationManager = LocationManager()
        let keyManager = KeyManager()
        let baseURL: URL? = URL(string: "https://webservice.recruit.co.jp/hotpepper/gourmet/v1")
        let apiKey = keyManager.getValue(forKey: "apiKey")
        let format = "json"
        var urlComponents = URLComponents(url: baseURL!, resolvingAgainstBaseURL: true)
        
        var queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "lat", value: locationManager.latitude.description),
            URLQueryItem(name: "lng", value: locationManager.longitude.description),
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
