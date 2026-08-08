//
//  LiquidGlassBackground.swift
//  DishMatch
//
//  Created by Claude on 2026/08/05.
//

import SwiftUI

extension View {
    /// iOS 26 以降は本物の Liquid Glass(`glassEffect`)を、それ未満は `.ultraThinMaterial` による
    /// 疑似ガラス表現にフォールバックする背景を付与する。
    /// - Parameters:
    ///   - shape: ガラスをくり抜く形状（Capsule など）
    ///   - tint: ガラスにうっすら乗せる色味
    @ViewBuilder
    func liquidGlassBackground<S: InsettableShape>(in shape: S, tint: Color = .clear) -> some View {
        if #available(iOS 26.0, *) {
            self.glassEffect(
                tint == .clear ? .regular.interactive() : .regular.tint(tint).interactive(),
                in: shape
            )
        } else {
            self
                .background(.ultraThinMaterial, in: shape)
                .background(tint.opacity(0.12), in: shape)
                .overlay(
                    shape.strokeBorder(Color.white.opacity(0.25), lineWidth: 0.6)
                )
                .shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
        }
    }
}
