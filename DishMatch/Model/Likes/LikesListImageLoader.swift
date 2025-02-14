//
//  LikesListImageLoader.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/02/14.
//
import SwiftUI

@MainActor
class ImageLoader: ObservableObject {
    @Published var image: UIImage? = nil
    @Published var isLoading = false
    private var retryCount = 0
    private let maxRetryCount = 3

    /// 指定されたURLから画像を非同期取得するメソッド
    /// - Parameter urlString: 画像のURL（文字列）
    func loadImage(from urlString: String) {
        guard let url = URL(string: urlString), !isLoading else { return }
        isLoading = true

        Task {
            do {
                let (data, response) = try await URLSession.shared.data(from: url)
                
                if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200,
                   let image = UIImage(data: data) {
                    self.image = image
                } else {
                    throw URLError(.badServerResponse)
                }
            } catch {
                print("⚠️ 画像取得失敗: \(error.localizedDescription)")
                if retryCount < maxRetryCount {
                    retryCount += 1
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.loadImage(from: urlString)
                    }
                } else {
                    print("❌ 画像取得に失敗しました")
                }
            }
            isLoading = false
        }
    }
}
