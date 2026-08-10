//
//  SwipeActionIndicatorView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

/// スワイプ中にカード上へ表示する LIKE / NONE のスタンプ。
/// スワイプ量（xOffset）に応じて、透明度に加えて拡大でせり出すことで派手に強調する。
/// 配色は下部の丸ボタン（LIKE=オレンジ / NONE=グレー）と揃える。
struct SwipeActionIndicatorView: View {
    @Binding var xOffset: CGFloat

    let screenCutOff: CGFloat

    /// LIKE の強さ（右スワイプ量）を 0...1 に正規化
    private var likeProgress: Double {
        guard screenCutOff != 0 else { return 0 }
        return min(max(Double(xOffset / screenCutOff), 0), 1)
    }

    /// NONE の強さ（左スワイプ量）を 0...1 に正規化
    private var noneProgress: Double {
        guard screenCutOff != 0 else { return 0 }
        return min(max(Double(-xOffset / screenCutOff), 0), 1)
    }

    var body: some View {
        HStack(alignment: .top) {
            stamp(text: "LIKE", systemImage: "heart.fill", color: .orange,
                  rotation: -18, progress: likeProgress)

            Spacer()

            stamp(text: "NONE", systemImage: "xmark", color: .gray,
                  rotation: 18, progress: noneProgress)
        }
        .padding(28)
    }

    /// 塗りバッジ風のスタンプ。progress が上がるほど拡大＆不透明になり、しきい値付近で最大に。
    private func stamp(text: String, systemImage: String, color: Color,
                       rotation: Double, progress: Double) -> some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.title2.weight(.black))
            Text(text)
                .font(.system(size: 30, weight: .heavy, design: .rounded))
        }
        .foregroundStyle(.white)
        .padding(.vertical, 10)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(color)
                // 色影で発光させて視認性を上げる
                .shadow(color: color.opacity(0.7), radius: 14, x: 0, y: 0)
                .shadow(color: .black.opacity(0.2), radius: 6, x: 0, y: 3)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(.white.opacity(0.9), lineWidth: 3)
        )
        .rotationEffect(.degrees(rotation))
        // 小さく薄い状態からせり出して大きくはっきり見せる
        .scaleEffect(0.55 + 0.55 * progress)
        .opacity(progress)
        .animation(.snappy(duration: 0.2), value: progress)
    }
}

#Preview {
    ZStack {
        Color.black.opacity(0.5).ignoresSafeArea()
        SwipeActionIndicatorView(xOffset: .constant(300), screenCutOff: 300)
    }
}
