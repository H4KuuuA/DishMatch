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
    @StateObject private var errorQueue = ErrorQueue()
    @State private var isShowAddFriend = false

    var body: some View {
        NavigationStack {
            Group {
                if friendsViewModel.friends.isEmpty {
                    emptyState
                } else {
                    List {
                        ForEach(friendsViewModel.friends) { friend in
                            friendRow(friend)
                        }
                        .onDelete(perform: delete)
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
            Text(friend.avatarEmoji)
                .font(.largeTitle)
                .frame(width: 44, height: 44)
                .background(Color.orange.opacity(0.15))
                .clipShape(Circle())

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

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let friend = friendsViewModel.friends[index]
            Task { await friendsViewModel.delete(friend) }
        }
    }
}

#Preview {
    FriendsListView(friendsViewModel: FriendsViewModel())
}
