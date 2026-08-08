//
//  ComingSoonView.swift
//  DishMatch
//
//  Created by Claude on 2026/08/06.
//

import SwiftUI

/// まだ実データを持たない機能向けの共通プレースホルダー画面。
/// UserProfileView上のダミーボタンを、遷移だけは成立する状態にするために使う。
struct ComingSoonView: View {
    let title: String
    let systemImage: String
    let message: String

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                Image(systemName: systemImage)
                    .font(.system(size: 48))
                    .foregroundStyle(.orange)
                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(.gray)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

#Preview {
    ComingSoonView(title: "予約履歴", systemImage: "calendar.badge.checkmark", message: "近日対応予定です")
}
