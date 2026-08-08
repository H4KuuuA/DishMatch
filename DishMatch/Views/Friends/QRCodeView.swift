//
//  QRCodeView.swift
//  DishMatch
//
//  Created by Claude on 2026/08/08.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

/// 文字列（友達コード）を QR コードとして表示するビュー。
/// 相手はこの QR を読み取る／表示されたコードを入力することで友達申請を送れる。
struct QRCodeView: View {
    let text: String

    var body: some View {
        Group {
            if let image = Self.generate(from: text) {
                Image(uiImage: image)
                    .interpolation(.none) // QRは補間せずくっきり表示する
                    .resizable()
                    .scaledToFit()
            } else {
                Image(systemName: "qrcode")
                    .resizable()
                    .scaledToFit()
                    .foregroundStyle(.secondary)
            }
        }
    }

    /// CoreImage で QR 画像を生成する。
    static func generate(from text: String) -> UIImage? {
        guard !text.isEmpty else { return nil }
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(text.utf8)
        filter.correctionLevel = "M"
        guard let output = filter.outputImage else { return nil }
        // 拡大してから CGImage 化することで、粗くならずに大きく表示できる
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        guard let cgImage = context.createCGImage(scaled, from: scaled.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}

#Preview {
    QRCodeView(text: "ABC12345")
        .frame(width: 200, height: 200)
        .padding()
}
