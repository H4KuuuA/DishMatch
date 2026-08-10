//
//  LegalDocumentView.swift
//  DishMatch
//
//  Created by Claude on 2026/08/10.
//

import SwiftUI

/// 利用規約・プライバシーポリシー・FAQなど、静的な文章コンテンツを共通レイアウトで表示する画面。
/// セクション（見出し＋本文）の配列を受け取り、スクロール可能な読み物として描画する。
struct LegalDocumentView: View {
    let title: String
    /// 文書冒頭の補足（施行日・最終更新日など）。空なら非表示。
    let subtitle: String
    let sections: [LegalSection]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if !subtitle.isEmpty {
                        Text(subtitle)
                            .font(.footnote)
                            .foregroundStyle(.gray)
                    }

                    ForEach(sections) { section in
                        VStack(alignment: .leading, spacing: 8) {
                            if !section.heading.isEmpty {
                                Text(section.heading)
                                    .font(.headline)
                                    .foregroundStyle(Color("FC"))
                            }
                            Text(section.body)
                                .font(.subheadline)
                                .foregroundStyle(Color("FC").opacity(0.85))
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(4)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(20)
                .padding(.bottom, 32)
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

/// 文書内の1セクション。見出し（heading）が空の場合は本文のみ表示する。
struct LegalSection: Identifiable {
    let id = UUID()
    let heading: String
    let body: String

    init(_ heading: String, _ body: String) {
        self.heading = heading
        self.body = body
    }
}

#Preview {
    LegalDocumentView(
        title: "サービス利用規約",
        subtitle: "最終更新日：2026年8月10日",
        sections: LegalContent.termsOfService
    )
}
