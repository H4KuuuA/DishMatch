//
//  GenreCatalog.swift
//  DishMatch
//
//  Created by Claude on 2026/08/06.
//

import Foundation

/// ジャンルマスタAPIの結果をアプリ内でキャッシュする。
/// ジャンル一覧はアプリ実行中に変わらない前提で、初回だけAPIを叩く。
@MainActor
final class GenreCatalog: ObservableObject {
    static let shared = GenreCatalog()

    @Published private(set) var genres: [GenreOption] = []
    @Published private(set) var isLoading = false
    /// 直近の取得エラー。同じ画面でエリア取得なども並行して失敗しうるため、
    /// 呼び出し元でErrorQueueに積んで多重エラーとして扱えるようにしている
    @Published private(set) var lastError: AppError?

    private let apiClient = APIClient()

    private init() {}

    /// まだ取得していなければジャンル一覧をAPIから取得する
    func loadIfNeeded() {
        guard genres.isEmpty, !isLoading else { return }
        isLoading = true
        Task {
            do {
                genres = try await apiClient.fetchGenres()
            } catch {
                print("DEBUG: ジャンル取得エラー \(error.localizedDescription)")
                lastError = AppError.from(error, fallbackTitle: "ジャンルを取得できませんでした")
            }
            isLoading = false
        }
    }
}
