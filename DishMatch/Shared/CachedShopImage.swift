//
//  CachedShopImage.swift
//  DishMatch
//
//  Created by Claude on 2026/08/08.
//

import SwiftUI
import Kingfisher

/// Kingfisher で画像をキャッシュしながら表示する共通ビュー。標準の AsyncImage の置き換え。
///
/// AsyncImage は再描画のたびに読み込み直し、同時に多数を読み込むと failure になりやすかった
/// （店舗詳細やマッチ画面で画像が出ない原因）。Kingfisher はメモリ/ディスクにキャッシュするため、
/// 二度目以降は即表示され、画面を行き来しても安定して表示される。
///
/// 呼び出し側は通常の Image と同様に `.scaledToFill()` `.frame(...)` `.clipped()` を付けて使う。
struct CachedShopImage: View {
    let urlString: String

    var body: some View {
        KFImage(URL(string: urlString))
            .placeholder {
                ZStack {
                    Color.gray.opacity(0.2)
                    ProgressView()
                }
            }
            // 取得失敗時のフォールバック画像
            .onFailureImage(UIImage(systemName: "photo"))
            .fade(duration: 0.2)
            .resizable()
    }
}
