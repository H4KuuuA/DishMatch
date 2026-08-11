//
//  TutorialView.swift
//  DishMatch
//
//  初めて使う人向けのチュートリアル。スワイプ操作とAIサジェスト（今日のお店を探す）を主役に、
//  フルスクリーンのページ送りで基本の使い方を説明する。
//  表示制御（初回のみ自動表示・再表示）は呼び出し側が担い、本ビューは閉じる意思だけ `onFinish` で伝える。
//

import SwiftUI

struct TutorialView: View {
    /// 「はじめる」/「スキップ」で閉じたいときに呼ばれる。永続化やdismissは呼び出し側の責務。
    var onFinish: () -> Void

    @State private var page = 0

    /// スライドの総数。最終ページの判定に使う。
    private let pageCount = 5

    var body: some View {
        ZStack {
            Color("WB").ignoresSafeArea()

            VStack(spacing: 0) {
                // 右上のスキップ（最終ページでは非表示にして「はじめる」に集約する）
                HStack {
                    Spacer()
                    if page < pageCount - 1 {
                        Button("スキップ") { onFinish() }
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                    } else {
                        // レイアウトを揃えるための透明プレースホルダ
                        Text("スキップ")
                            .font(.subheadline.weight(.semibold))
                            .opacity(0)
                            .padding(.horizontal, 20)
                            .padding(.top, 12)
                    }
                }

                TabView(selection: $page) {
                    welcomePage.tag(0)
                    swipePage.tag(1)
                    cardContentPage.tag(2)
                    aiPage.tag(3)
                    startPage.tag(4)
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.easeInOut, value: page)

                // ページインジケータ（現在位置）
                pageIndicator
                    .padding(.bottom, 16)

                // 進む/はじめるボタン
                bottomButton
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
            }
        }
    }

    // MARK: - スライド

    /// 1. ようこそ（世界観：見つけるではなく“出会う”）
    private var welcomePage: some View {
        TutorialPage(
            title: "DishMatch へようこそ",
            message: "探すのではなく、気になるお店と“出会う”アプリ。\nまずは基本の使い方を見てみましょう。"
        ) {
            Image(systemName: "sparkles")
                .font(.system(size: 88, weight: .regular))
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
        }
    }

    /// 2. スワイプの使い方（右＝いいね／左＝スキップ／取り消し）
    private var swipePage: some View {
        TutorialPage(
            title: "スワイプで選ぶ",
            message: "右スワイプ（♥）で「いいね」、左スワイプ（✕）で「スキップ」。\n間違えても取り消しボタンで1つ前に戻せます。"
        ) {
            SwipeDiagram()
        }
    }

    /// 3. カードの中身（写真スクロール・タップで詳細）
    private var cardContentPage: some View {
        TutorialPage(
            title: "お店をよく見る",
            message: "カードの写真を横にスワイプすると別の写真が見られます。\nカードをタップすると、お店の詳しい情報を確認できます。"
        ) {
            Image(systemName: "photo.on.rectangle.angled")
                .font(.system(size: 84, weight: .regular))
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
        }
    }

    /// 4. AIサジェスト（今日のお店を探す）
    private var aiPage: some View {
        TutorialPage(
            title: "AIにおまかせで探す",
            message: "右上の「探す」から、地域・予算と“今日の気分”を入れるだけ。\nジャンルやこだわりは、あなたのいいね履歴と気分からAIが提案します。"
        ) {
            AISuggestDiagram()
        }
    }

    /// 5. はじめよう
    private var startPage: some View {
        TutorialPage(
            title: "さっそく始めよう",
            message: "気になったお店に、どんどん「いいね」してみましょう。\nあなた好みのお店との出会いが待っています。"
        ) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.system(size: 88, weight: .regular))
                .foregroundStyle(.orange)
                .accessibilityHidden(true)
        }
    }

    // MARK: - 下部パーツ

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(0..<pageCount, id: \.self) { index in
                Capsule()
                    .fill(index == page ? Color.orange : Color.secondary.opacity(0.3))
                    .frame(width: index == page ? 20 : 8, height: 8)
                    .animation(.easeInOut, value: page)
            }
        }
    }

    private var bottomButton: some View {
        Button {
            if page < pageCount - 1 {
                withAnimation { page += 1 }
            } else {
                onFinish()
            }
        } label: {
            Text(page < pageCount - 1 ? "次へ" : "はじめる")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(Color.orange, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - スライド1枚分の共通レイアウト

/// 図（上）・見出し・本文を縦に並べる、チュートリアル1ページ分の枠。
private struct TutorialPage<Illustration: View>: View {
    let title: String
    let message: String
    @ViewBuilder var illustration: () -> Illustration

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 0)

            illustration()
                .frame(height: 200)

            VStack(spacing: 14) {
                Text(title)
                    .font(.title.bold())
                    .foregroundStyle(Color("FC"))
                    .multilineTextAlignment(.center)

                Text(message)
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 32)

            Spacer(minLength: 0)
        }
    }
}

// MARK: - 図解

/// スワイプ操作の図。中央のカードから、左に「✕スキップ」・右に「♥いいね」が伸びる。
private struct SwipeDiagram: View {
    var body: some View {
        HStack(spacing: 20) {
            swipeSide(icon: "xmark", label: "スキップ", tint: .gray, arrow: "arrow.left")

            RoundedRectangle(cornerRadius: 16)
                .fill(Color("BG"))
                .frame(width: 96, height: 132)
                .shadow(radius: 6)
                .overlay(
                    Image(systemName: "fork.knife")
                        .font(.system(size: 34, weight: .semibold))
                        .foregroundStyle(.orange)
                )

            swipeSide(icon: "heart.fill", label: "いいね", tint: .orange, arrow: "arrow.right")
        }
        .accessibilityElement()
        .accessibilityLabel("右スワイプでいいね、左スワイプでスキップ")
    }

    private func swipeSide(icon: String, label: String, tint: Color, arrow: String) -> some View {
        VStack(spacing: 10) {
            Image(systemName: arrow)
                .font(.headline.weight(.bold))
                .foregroundStyle(.secondary)
            Image(systemName: icon)
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(tint)
                .frame(width: 48, height: 48)
                .background(Circle().fill(Color("BG")).shadow(radius: 4))
            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
        }
    }
}

/// AIサジェストの図。「気分・地域・予算」→ AI → 「おすすめ」の流れを簡潔に示す。
private struct AISuggestDiagram: View {
    var body: some View {
        VStack(spacing: 16) {
            // 入力チップ
            HStack(spacing: 8) {
                inputChip("気分")
                inputChip("地域")
                inputChip("予算")
            }

            Image(systemName: "arrow.down")
                .font(.headline.weight(.bold))
                .foregroundStyle(.secondary)

            // AI
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                Text("AIがおすすめを提案")
            }
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.orange)
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(Color("BG"), in: Capsule())
            .shadow(radius: 4)
        }
        .accessibilityElement()
        .accessibilityLabel("気分・地域・予算を入れると、AIがおすすめのお店を提案します")
    }

    private func inputChip(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .foregroundStyle(Color("FC"))
            .padding(.vertical, 8)
            .padding(.horizontal, 14)
            .background(Color("BG"), in: Capsule())
            .shadow(radius: 3)
    }
}

#Preview {
    TutorialView(onFinish: {})
}
