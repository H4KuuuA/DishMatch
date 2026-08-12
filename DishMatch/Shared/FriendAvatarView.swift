//
//  FriendAvatarView.swift
//  DishMatch
//
//  Created by Claude on 2026/08/08.
//

import SwiftUI

/// 友達のアイコンを丸型で表示する共通ビュー。
/// 設定済みのアイコン画像（base64をデコードしたData）があればそれを、
/// 未登録なら person.crop.circle のプレースホルダを表示する。
struct FriendAvatarView: View {
    let imageData: Data?
    /// 互換のため残すが、未登録時は絵文字ではなく person.crop.circle を表示する。
    var emoji: String = ""
    var size: CGFloat = 40

    var body: some View {
        Group {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Image(systemName: "person.crop.circle")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.gray.opacity(0.6))
            }
        }
        .frame(width: size, height: size)
        .background(Color.orange.opacity(0.15))
        .clipShape(Circle())
    }
}
