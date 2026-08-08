//
//  ErrorBannerView.swift
//  DishMatch
//
//  Created by Claude on 2026/08/08.
//

import SwiftUI

/// `ErrorQueue`の先頭エラーを画面上部にバナーとして表示する。
/// タップまたは閉じるボタンで消すと、キューに残っている次のエラーが続けて表示される。
/// `.overlay(alignment: .top)`などで画面に重ねて使う想定。単発の確認ダイアログ（削除確認など）は
/// 引き続き`.alert`を使い、同時多発しうるエラーだけをこちらで扱う。
struct ErrorBannerView: View {
    @ObservedObject var errorQueue: ErrorQueue

    var body: some View {
        if let current = errorQueue.errors.first {
            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .foregroundStyle(.white)
                        .padding(.top, 1)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(current.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        Text(current.message)
                            .font(.caption)
                    }

                    Spacer()

                    Button {
                        withAnimation(.easeOut(duration: 0.2)) {
                            errorQueue.dismissCurrent()
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                }

                // キューに他のエラーも溜まっている場合はそれが伝わるようにする（多重エラー対応）
                if errorQueue.errors.count > 1 {
                    Text("ほかに\(errorQueue.errors.count - 1)件のエラーがあります")
                        .font(.caption2)
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            .padding(12)
            .background(Color.red.opacity(0.9), in: RoundedRectangle(cornerRadius: 12))
            .foregroundStyle(.white)
            .padding(.horizontal)
            .shadow(color: .black.opacity(0.15), radius: 8, y: 4)
            .contentShape(Rectangle())
            .onTapGesture {
                withAnimation(.easeOut(duration: 0.2)) {
                    errorQueue.dismissCurrent()
                }
            }
            .transition(.move(edge: .top).combined(with: .opacity))
            .animation(.easeOut(duration: 0.2), value: errorQueue.errors)
        }
    }
}

#Preview {
    let queue = ErrorQueue()
    queue.report(title: "お店を読み込めませんでした", message: "通信環境を確認して、もう一度お試しください。")
    queue.report(title: "ジャンルを取得できませんでした", message: "通信環境を確認してください。")

    return ZStack(alignment: .top) {
        Color("BG").ignoresSafeArea()
        ErrorBannerView(errorQueue: queue)
            .padding(.top, 8)
    }
}
