//
//  AvatarImageResizer.swift
//  DishMatch
//
//  Created by Claude on 2026/08/08.
//

import UIKit

/// アイコン画像を保存前にリサイズ・圧縮する共通ユーティリティ。
/// 公開プロフィール（Firestore）や UserDefaults には base64 文字列として載せるため、容量を絞る。
enum AvatarImageResizer {
    /// 長辺を `maxDimension` に抑えた JPEG にリサイズする。デコードできなければ nil。
    static func resizedJPEGData(from data: Data,
                                maxDimension: CGFloat = 480,
                                compressionQuality: CGFloat = 0.75) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let scale = min(maxDimension / image.size.width, maxDimension / image.size.height, 1)
        let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resizedImage = renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
        return resizedImage.jpegData(compressionQuality: compressionQuality)
    }
}
