//
//  DiscoverSettingsButtonView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//

import SwiftUI

/// ディスカバリー設定を開く独自ボタン。
/// 以前はツールバーに置いていたが、iOS26のLiquid Glassがツールバー内のボタンを
/// 自動でピル状に拡大し、カードと詰まってしまうため撤去した。カプセル型（上辺・下辺は
/// まっすぐ、左右は円状）の独自スタイルにして、通常のレイアウトフローに配置する。
struct DiscoverSettingsButtonView: View {
    @Binding var isShowDiscoverSettings: Bool

    var body: some View {
        Button {
            isShowDiscoverSettings.toggle()
        } label: {
            Image(systemName: "slider.horizontal.3")
                .font(.title3.weight(.semibold))
                // アイコンはオレンジ。背景は透明感のあるガラス＋オレンジtint
                .foregroundStyle(.orange)
                .padding(12)
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
