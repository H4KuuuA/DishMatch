//
//  FriendAvatarView.swift
//  DishMatch
//
//  Created by Claude on 2026/08/08.
//

import SwiftUI

/// 友達のアイコンを丸型で表示する共通ビュー。
/// 設定済みのアイコン画像（base64をデコードしたData）があればそれを、なければ絵文字を表示する。
struct FriendAvatarView: View {
    let imageData: Data?
    let emoji: String
    var size: CGFloat = 40

    var body: some View {
        Group {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(emoji)
                    .font(.system(size: size * 0.55))
            }
        }
        .frame(width: size, height: size)
        .background(Color.orange.opacity(0.15))
        .clipShape(Circle())
    }
}
