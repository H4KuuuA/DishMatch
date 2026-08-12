//
//  TutorialView.swift
//  DishMatch
//
//  初めて使う人向けのチュートリアル。スワイプ操作・AIサジェストに加え、本アプリの根幹である
//  友達連携（追加・マッチ・トークでのお店共有）を紹介する。最初に見る画面なので、ワクワクする
//  トーンで基本の使い方を案内する。図はSF Symbolのみで表現し、絵文字は使わない。
//  表示制御は呼び出し側が担い、本ビューは閉じる意思だけ `onFinish` で伝える。
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
                    aiPage.tag(2)
                    socialPage.tag(3)
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
            message: "お店は「探す」より“出会う”もの。\nスワイプで、運命の一軒を見つけにいこう！"
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
            title: "ピンときたら右にスワイプ！",
            message: "気になったら右へ、ちがうなと思ったら左へスワイプ。\n間違えても、取り消しボタンですぐ戻せます。"
        ) {
            SwipeDiagram()
        }
    }

    /// 3. AIサジェスト（今日のお店を探す）
    private var aiPage: some View {
        TutorialPage(
            title: "迷ったらAIにおまかせ",
            message: "地域・予算と“今日の気分”を入れるだけ。\nあなたの好みから、AIがぴったりの一軒を提案！"
        ) {
            AISuggestDiagram()
        }
    }

    /// 4. 友達連携（追加・マッチ・トークでの共有をまとめて紹介。本アプリの根幹）
    private var socialPage: some View {
        TutorialPage(
            title: "友達と一緒だともっと楽しい",
            message: "友達を追加して、同じお店を好きになったら“マッチ”！\n気になるお店は、トークでどんどんシェアしよう。"
        ) {
            SocialDiagram()
        }
    }

    /// 5. はじめよう
    private var startPage: some View {
        TutorialPage(
            title: "さあ、始めよう！",
            message: "お気に入りの一軒との出会いが待ってる。\nまずは気になるお店に、気軽に「いいね」してみよう！"
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
                .frame(height: 210)

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

// MARK: - 図解（SF Symbolのみ。何の機能か一目で分かる具体的な構図にする）

/// お店カードの見た目（中央に fork.knife）。各図で共通して使う。
private struct ShopCard: View {
    var width: CGFloat = 96
    var height: CGFloat = 128

    var body: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color("BG"))
            .frame(width: width, height: height)
            .shadow(radius: 6)
            .overlay(
                Image(systemName: "fork.knife")
                    .font(.system(size: width * 0.34, weight: .semibold))
                    .foregroundStyle(.orange)
            )
    }
}

/// スワイプ操作の図。中央のお店カードを、左（✕）／右（♥）へスワイプする様子を矢印で示す。
private struct SwipeDiagram: View {
    var body: some View {
        HStack(spacing: 14) {
            judge(icon: "xmark", tint: .gray, arrow: "arrow.left")
            ShopCard()
                .rotationEffect(.degrees(-6))
            judge(icon: "heart.fill", tint: .orange, arrow: "arrow.right")
        }
        .accessibilityElement()
        .accessibilityLabel("右スワイプでいいね、左スワイプでスキップ")
    }

    /// 矢印＋丸アイコンで、スワイプ方向の判定（スキップ／いいね）を示す。
    private func judge(icon: String, tint: Color, arrow: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: arrow)
                .font(.headline.weight(.bold))
                .foregroundStyle(.secondary)
            Image(systemName: icon)
                .font(.system(size: 22, weight: .heavy))
                .foregroundStyle(tint)
                .frame(width: 50, height: 50)
                .background(Circle().fill(Color("BG")).shadow(radius: 4))
        }
    }
}

/// AIサジェストの図。✨（AI）から矢印で「おすすめのお店カード」が出る様子で、AIが店を提案することを示す。
private struct AISuggestDiagram: View {
    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: "sparkles")
                .font(.system(size: 36, weight: .semibold))
                .foregroundStyle(.orange)
                .frame(width: 74, height: 74)
                .background(Circle().fill(Color("BG")).shadow(radius: 4))

            Image(systemName: "arrow.right")
                .font(.title3.weight(.bold))
                .foregroundStyle(.secondary)

            ShopCard(width: 84, height: 112)
        }
        .accessibilityElement()
        .accessibilityLabel("AIがあなたにぴったりのお店を提案します")
    }
}

/// 友達連携の図。二人（person.crop.circle）が同じお店カード（♥付き）を囲む様子で「同じお店でマッチ」を示す。
private struct SocialDiagram: View {
    var body: some View {
        HStack(spacing: 8) {
            personIcon
            ZStack(alignment: .topTrailing) {
                ShopCard(width: 92, height: 116)
                Image(systemName: "heart.fill")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.orange)
                    .padding(6)
                    .background(Circle().fill(Color("WB")).shadow(radius: 3))
                    .offset(x: 8, y: -8)
            }
            personIcon
        }
        .accessibilityElement()
        .accessibilityLabel("友達と同じお店をいいねするとマッチします")
    }

    private var personIcon: some View {
        Image(systemName: "person.crop.circle")
            .font(.system(size: 54))
            .foregroundStyle(.gray.opacity(0.6))
    }
}

#Preview {
    TutorialView(onFinish: {})
}
