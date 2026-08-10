//
//  DiscoverSettingsButtonView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

/// 「今日のお店を探す」シート（気分プロンプト＋地域・予算）を開く独自ボタン。
/// 以前はツールバーに置いていたが、iOS26のLiquid Glassがツールバー内のボタンを
/// 自動でピル状に拡大し、カードと詰まってしまうため撤去した。カプセル型（上辺・下辺は
/// まっすぐ、左右は円状）の独自スタイルにして、通常のレイアウトフローに配置する。
/// AIで探す主機能の入り口であることが伝わるよう sparkles アイコンを使う。
struct DiscoverSettingsButtonView: View {
    @Binding var isShowDiscoverSettings: Bool

    var body: some View {
        Button {
            isShowDiscoverSettings.toggle()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                Text("探す")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.primary)
            .padding(.vertical, 10)
            .padding(.horizontal, 18)
            // マテリアル（iOS26 では Liquid Glass）によるガラス風の背景。
            .liquidGlassBackground(in: Capsule(), tint: .orange)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    ZStack {
        LinearGradient(colors: [.orange, .pink, .purple],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
            .ignoresSafeArea()
        DiscoverSettingsButtonView(isShowDiscoverSettings: .constant(false))
    }
}
