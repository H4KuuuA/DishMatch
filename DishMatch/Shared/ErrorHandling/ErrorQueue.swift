//
//  ErrorQueue.swift
//  DishMatch
//
//  Created by Claude on 2026/08/08.
//

import Foundation

/// 複数のエラーが同時に発生しうる画面向けに、エラーをキューで保持するストア。
/// `.alert`は一度に1件しか表現できず、後から届いたエラーが前のエラーを上書きしてしまうため、
/// 「ジャンル取得」「エリア取得」のように独立した処理が同時に失敗しうる画面ではこちらを使う。
/// 先頭のエラーだけを`ErrorBannerView`が表示し、閉じると次のエラーに進む。
@MainActor
final class ErrorQueue: ObservableObject {
    @Published private(set) var errors: [AppError] = []

    func report(_ error: AppError) {
        // 表示中も含め、まったく同じ内容のエラーは積み上げない
        guard !errors.contains(error) else { return }
        errors.append(error)
    }

    func report(title: String, message: String) {
        report(AppError(title: title, message: message))
    }

    /// 先頭（表示中）のエラーを消して次に進む
    func dismissCurrent() {
        guard !errors.isEmpty else { return }
        errors.removeFirst()
    }

    func dismissAll() {
        errors.removeAll()
    }
}
