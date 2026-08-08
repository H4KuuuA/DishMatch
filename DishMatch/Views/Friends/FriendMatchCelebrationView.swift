//
//  FriendMatchCelebrationView.swift
//  DishMatch
//
//  Created by Claude on 2026/08/07.
//

import SwiftUI

/// 自分がLikeしたお店が、登録済み友達の好みと一致した時だけ表示する「マッチ」演出。
/// 単なるLike（[[CardView]]の軽いハート演出）とは意図的に区別し、本当に二人の意思が
/// 重なった瞬間だけこの画面を見せる。
struct FriendMatchCelebrationView: View {
    let match: FriendMatch
    var onKeepSearching: () -> Void
    var onViewDetail: () -> Void

    @State private var isContentVisible = false
    /// 自分のアイコンを表示するために参照する
    @ObservedObject private var userProfile = UserProfile.shared

    private var friend: Friend { match.friends[0] }

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.orange, Color.orange.opacity(0.75)],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()

            VStack(spacing: 18) {
                Spacer()

                Text("\(friend.name)さんと\nマッチしました！")
                    .font(.system(size: 28, weight: .heavy))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.white)

                if match.friends.count > 1 {
                    Text("他\(match.friends.count - 1)人の友達も気になっています")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }

                matchVisual
                    .padding(.top, 8)

                VStack(spacing: 4) {
                    Text(match.shop.name)
                        .font(.title3)
                        .fontWeight(.bold)
                    Text("お互いにこのお店が気になっています")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.85))
                }
                .foregroundStyle(.white)

                Spacer()

                actionButtons
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 40)
        }
        .onAppear {
            withAnimation(.spring(response: 0.55, dampingFraction: 0.62).delay(0.1)) {
                isContentVisible = true
            }
        }
    }

    /// 自分と友達のアバターでお店の写真を挟み、二人の意思が重なったことを示す。
    /// アイコンは設定済みの画像があればそれを表示する（自分＝UserProfile、相手＝Friend）。
    private var matchVisual: some View {
        HStack(spacing: -18) {
            avatarCircle(imageData: userProfile.avatarImageData, emoji: "🙂")
                .zIndex(0)
            shopPhoto
                .zIndex(1)
            avatarCircle(imageData: friend.avatarImageData, emoji: friend.avatarEmoji)
                .zIndex(0)
        }
        .scaleEffect(isContentVisible ? 1 : 0.6)
        .opacity(isContentVisible ? 1 : 0)
    }

    private func avatarCircle(imageData: Data?, emoji: String) -> some View {
        Group {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(emoji)
                    .font(.system(size: 30))
            }
        }
        .frame(width: 60, height: 60)
        .background(.white, in: Circle())
        .clipShape(Circle())
        .overlay(Circle().stroke(.white, lineWidth: 3))
        .shadow(color: .black.opacity(0.2), radius: 8)
    }

    private var shopPhoto: some View {
        CachedShopImage(urlString: match.shop.photo.pc.l)
            .scaledToFill()
            .frame(width: 120, height: 120)
            .clipShape(Circle())
        .overlay(Circle().stroke(.white, lineWidth: 4))
        .shadow(color: .black.opacity(0.25), radius: 12, y: 6)
    }

    private var actionButtons: some View {
        VStack(spacing: 14) {
            Button(action: onViewDetail) {
                Text("お店を見てみる")
                    .font(.headline)
                    .foregroundStyle(.orange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(.white, in: Capsule())
            }

            Button(action: onKeepSearching) {
                Text("閉じる")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
            }
        }
    }
}

#Preview {
    FriendMatchCelebrationView(
        match: FriendMatch(
            shop: MockShop.mockShop,
            friends: [Friend(id: "1", name: "みなみ", avatarEmoji: "😊", likedGenreCodes: [MockShop.mockShop.genre.code])]
        ),
        onKeepSearching: {},
        onViewDetail: {}
    )
}
