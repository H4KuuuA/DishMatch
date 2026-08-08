//
//  GenreFilterListView.swift
//  DishMatch
//
//  Created by Claude on 2026/08/07.
//

import SwiftUI

/// ジャンルタブに収まりきらない分も含めた全ジャンルから絞り込むための汎用リスト画面。
/// タブの「もっと見る」から遷移する。ジャンル数が増えても破綻しないよう、
/// タブとは独立したスクロール可能な一覧として実装している。
struct GenreFilterListView: View {
    @Environment(\.dismiss) private var dismiss
    let genreNames: [String]
    let selectedGenre: String
    var onSelect: (String) -> Void

    var body: some View {
        NavigationStack {
            List {
                row(for: "すべて")
                ForEach(genreNames, id: \.self) { genreName in
                    row(for: genreName)
                }
            }
            .navigationTitle("ジャンルで絞り込み")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("閉じる") { dismiss() }
                }
            }
        }
    }

    private func row(for genreName: String) -> some View {
        Button {
            onSelect(genreName)
            dismiss()
        } label: {
            HStack {
                Text(genreName)
                    .foregroundStyle(Color("FC"))
                Spacer()
                if genreName == selectedGenre {
                    Image(systemName: "checkmark")
                        .foregroundStyle(.orange)
                }
            }
        }
    }
}

#Preview {
    GenreFilterListView(genreNames: ["居酒屋", "イタリアン", "焼肉・ホルモン", "ラーメン", "カフェ・スイーツ"], selectedGenre: "すべて") { _ in }
}
