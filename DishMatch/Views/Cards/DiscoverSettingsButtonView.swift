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
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                Text("絞り込み")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.white)
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(Color.orange, in: Capsule())
            .shadow(color: .orange.opacity(0.25), radius: 6, x: 0, y: 3)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    DiscoverSettingsButtonView(isShowDiscoverSettings: .constant(false))
        .padding()
}
