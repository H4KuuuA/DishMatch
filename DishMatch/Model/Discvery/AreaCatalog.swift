//
//  AreaCatalog.swift
//  DishMatch
//
//  Created by Claude on 2026/08/07.
//

import Foundation

/// サービスエリアマスタAPIの結果をアプリ内でキャッシュする。
/// エリア一覧はアプリ実行中に変わらない前提で、初回だけAPIを叩く。
@MainActor
final class AreaCatalog: ObservableObject {
    static let shared = AreaCatalog()

    @Published private(set) var serviceAreas: [ServiceAreaOption] = []
    @Published private(set) var isLoading = false
    /// 直近の取得エラー。同じ画面でジャンル取得なども並行して失敗しうるため、
    /// 呼び出し元でErrorQueueに積んで多重エラーとして扱えるようにしている
    @Published private(set) var lastError: AppError?

    private let apiClient = APIClient()

    private init() {}

    /// まだ取得していなければサービスエリア一覧をAPIから取得する
    func loadIfNeeded() {
        guard serviceAreas.isEmpty, !isLoading else { return }
        isLoading = true
        Task {
            do {
                serviceAreas = try await apiClient.fetchServiceAreas()
            } catch {
                print("DEBUG: エリア取得エラー \(error.localizedDescription)")
                lastError = AppError.from(error, fallbackTitle: "エリア一覧を取得できませんでした")
            }
            isLoading = false
        }
    }
}
