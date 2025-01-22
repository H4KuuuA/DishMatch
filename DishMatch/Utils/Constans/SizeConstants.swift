//
//  SizeConstants.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/22.
//

import SwiftUI

// 画面サイズに基づく定数を保持する構造体
struct SizeConstants {
        /// 画面幅の半分の80%を "screenCutoff" として定義
        static var screenCutoff: CFloat {
            CFloat((UIScreen.main.bounds.width / 2) * 0.8)
        }
        /// カードの幅を画面の幅から 20 ポイントを引いた値に設定
        static var cardWidth: CGFloat {
            UIScreen.main.bounds.width - 20
        }
        /// カードが画面全体にフィットしない程度に収まる高さになる
        static var cardHeight: CGFloat {
            UIScreen.main.bounds.height / 1.45
        }
}
