//
//  FriendsListView.swift
//  DishMatch
//
//  Created by Claude on 2026/08/07.
//

import SwiftUI

/// 登録した友達の一覧画面。ここから新規登録もできる。
struct FriendsListView: View {
    @ObservedObject var friendsViewModel: FriendsViewModel
    /// チャットのお店共有ピッカーで自分のいいねしたお店を参照するために持つ
    @ObservedObject var restaurantViewModel: RestaurantViewModel
    @StateObject private var errorQueue = ErrorQueue()
    @State private var isShowAddFriend = false

    var body: some View {
        NavigationStack {
            Group {
                if friendsViewModel.friends.isEmpty && friendsViewModel.incomingRequests.isEmpty {
                    emptyState
                } else {
                    List {
                        if !friendsViewModel.incomingRequests.isEmpty {
                            Section("友達申請") {
                                ForEach(friendsViewModel.incomingRequests) { request in
                                    requestRow(request)
                                }
                            }
                        }
                        Section(friendsViewModel.friends.isEmpty ? "" : "友達") {
                            ForEach(friendsViewModel.friends) { friend in
                                if let myUid = friendsViewModel.currentUid {
                                    NavigationLink {
                                        ChatView(friend: friend, myUid: myUid, restaurantViewModel: restaurantViewModel)
                                    } label: {
                                        friendRow(friend)
                                    }
                                } else {
                                    friendRow(friend)
                                }
                            }
                            .onDelete(perform: delete)
                        }
                    }
                }
            }
            .overlay(alignment: .top) {
                ErrorBannerView(errorQueue: errorQueue)
                    .padding(.top, 8)
            }
            .navigationTitle("友達")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        isShowAddFriend = true
                    } label: {
                        Image(systemName: "person.badge.plus")
                    }
                }
            }
            .sheet(isPresented: $isShowAddFriend) {
                AddFriendView(friendsViewModel: friendsViewModel)
            }
            .onChange(of: friendsViewModel.lastError) { _, newValue in
                if let newValue {
                    errorQueue.report(newValue)
                }
            }
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
            Text("まだ友達が登録されていません")
                .font(.headline)
            Text("友達を登録すると、同じジャンルのお店をLikeした時にマッチを教えてくれます。")
                .font(.subheadline)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Button {
                isShowAddFriend = true
            } label: {
                Text("友達を登録する")
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 24)
                    .padding(.vertical, 10)
                    .background(Color.orange, in: Capsule())
            }
            .padding(.top, 8)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func friendRow(_ friend: Friend) -> some View {
        HStack(spacing: 12) {
            avatar(imageData: friend.avatarImageData, emoji: friend.avatarEmoji)

            VStack(alignment: .leading, spacing: 2) {
                Text(friend.name)
                    .font(.headline)
                Text("好きなジャンル \(friend.likedGenreCodes.count)件")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    /// 受信した友達申請の行。承認/拒否ボタンを持つ。
    private func requestRow(_ request: FriendRequest) -> some View {
        HStack(spacing: 12) {
            avatar(imageData: nil, emoji: "🙂")

            VStack(alignment: .leading, spacing: 2) {
                Text(request.fromNickname)
                    .font(.headline)
                Text("友達申請が届いています")
                    .font(.caption)
                    .foregroundStyle(.gray)
            }
            Spacer()

            Button {
                Task { await friendsViewModel.acceptRequest(request) }
            } label: {
                Text("承認")
                    .font(.footnote.bold())
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Color.orange, in: Capsule())
            }
            .buttonStyle(.plain)

            Button {
                Task { await friendsViewModel.rejectRequest(request) }
            } label: {
                Image(systemName: "xmark")
                    .font(.footnote.bold())
                    .foregroundStyle(.gray)
                    .padding(8)
                    .background(Color.gray.opacity(0.15), in: Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.vertical, 4)
    }

    /// 友達アイコン。画像があれば画像を、なければ絵文字を丸型で表示する。
    @ViewBuilder
    private func avatar(imageData: Data?, emoji: String) -> some View {
        Group {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(emoji)
                    .font(.largeTitle)
            }
        }
        .frame(width: 44, height: 44)
        .background(Color.orange.opacity(0.15))
        .clipShape(Circle())
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let friend = friendsViewModel.friends[index]
            Task { await friendsViewModel.delete(friend) }
        }
    }
}

#Preview {
    let friendsViewModel = FriendsViewModel()
    return FriendsListView(
        friendsViewModel: friendsViewModel,
        restaurantViewModel: RestaurantViewModel(friendsViewModel: friendsViewModel)
    )
}
