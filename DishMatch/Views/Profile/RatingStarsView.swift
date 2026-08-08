//
//  RatingStarsView.swift
//  DishMatch
//
//  Created by Claude on 2026/08/07.
//

import SwiftUI

/// Google Placesから取得した5点満点の評価を星アイコンで表示する。
/// HotPepperのレスポンスには無い情報のため、値が無い場合は呼び出し側で表示を出し分ける。
struct RatingStarsView: View {
    let rating: Double
    let userRatingCount: Int?

    var body: some View {
        HStack(spacing: 4) {
            HStack(spacing: 1) {
                ForEach(0..<5, id: \.self) { index in
                    Image(systemName: starImageName(for: index))
                        .foregroundStyle(.yellow)
                        .font(.caption)
                }
            }
            Text(String(format: "%.1f", rating))
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundStyle(Color("FC"))
            if let userRatingCount {
                Text("(\(userRatingCount)件)")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
        }
    }

    private func starImageName(for index: Int) -> String {
        let threshold = Double(index) + 1
        if rating >= threshold {
            return "star.fill"
        } else if rating >= threshold - 0.5 {
            return "star.leadinghalf.filled"
        } else {
            return "star"
        }
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 12) {
        RatingStarsView(rating: 4.2, userRatingCount: 128)
        RatingStarsView(rating: 3.5, userRatingCount: nil)
        RatingStarsView(rating: 5.0, userRatingCount: 3)
    }
    .padding()
}
