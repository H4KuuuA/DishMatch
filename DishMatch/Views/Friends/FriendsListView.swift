//
//  FriendsListView.swift
//  DishMatch
//
//  Created by Claude on 2026/08/07.
//

import SwiftUI

/// 登録した友達の一覧画面（インスタDM風）。アイコン＋名前＋最終メッセージ＋時刻で表示し、
/// 行タップでチャットへ。上部に検索、友達申請は先頭にまとめる。ここから新規登録もできる。
struct FriendsListView: View {
    @ObservedObject var friendsViewModel: FriendsViewModel
    /// チャットのお店共有ピッカーで自分のいいねしたお店を参照するために持つ
    @ObservedObject var restaurantViewModel: RestaurantViewModel
    @StateObject private var errorQueue = ErrorQueue()
    /// 各友達の最終メッセージ（会話プレビュー）を購読するストア
    @StateObject private var chatSummaries = ChatSummariesViewModel()
    @State private var isShowAddFriend = false
    @State private var searchText = ""

    /// 検索文字での絞り込み後の友達一覧。
    private var filteredFriends: [Friend] {
        let query = searchText.trimmingCharacters(in: .whitespaces)
        guard !query.isEmpty else { return friendsViewModel.friends }
        return friendsViewModel.friends.filter { $0.name.localizedCaseInsensitiveContains(query) }
    }

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
                        Section {
                            ForEach(filteredFriends) { friend in
                                friendLink(friend)
                            }
                            .onDelete(perform: deleteFiltered)
                        }
                    }
                    .listStyle(.plain)
                    .searchable(text: $searchText,
                                placement: .navigationBarDrawer(displayMode: .always),
                                prompt: "友達を検索")
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
            .onAppear { bindSummaries() }
            .onChange(of: friendsViewModel.currentUid) { _, _ in bindSummaries() }
        }
    }

    /// 会話プレビューの購読を（ログイン中なら）開始する。
    private func bindSummaries() {
        if let myUid = friendsViewModel.currentUid {
            chatSummaries.bind(myUid: myUid)
        }
    }

    /// 友達1行。ログイン中はチャットへ遷移する。
    @ViewBuilder
    private func friendLink(_ friend: Friend) -> some View {
        let summary = friendsViewModel.currentUid.flatMap {
            chatSummaries.summary(forFriendID: friend.id, myUid: $0)
        }
        if let myUid = friendsViewModel.currentUid {
            NavigationLink {
                ChatView(friend: friend, myUid: myUid, restaurantViewModel: restaurantViewModel)
            } label: {
                FriendChatRow(friend: friend, summary: summary)
            }
        } else {
            FriendChatRow(friend: friend, summary: summary)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 44))
                .foregroundStyle(.orange)
            Text("まだ友達が登録されていません")
                .font(.headline)
            Text("友達を登録すると、同じお店をLikeした時にマッチを教えてくれます。")
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

    /// 受信した友達申請の行。承認/拒否ボタンを持つ。
    private func requestRow(_ request: FriendRequest) -> some View {
        HStack(spacing: 12) {
            FriendAvatarCircle(imageData: nil, emoji: "🙂", size: 48)

            VStack(alignment: .leading, spacing: 2) {
                Text(request.fromNickname)
                    .font(.subheadline.weight(.semibold))
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

    /// 検索絞り込み後のインデックスから実際の友達を消す。
    private func deleteFiltered(at offsets: IndexSet) {
        for index in offsets {
            let friend = filteredFriends[index]
            Task { await friendsViewModel.delete(friend) }
        }
    }
}

/// 友達一覧のインスタDM風の行：丸アイコン＋名前＋最終メッセージ＋時刻。
struct FriendChatRow: View {
    let friend: Friend
    let summary: ChatSummary?

    var body: some View {
        HStack(spacing: 12) {
            FriendAvatarCircle(imageData: friend.avatarImageData, emoji: friend.avatarEmoji, size: 56)

            VStack(alignment: .leading, spacing: 3) {
                Text(friend.name)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(previewText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer(minLength: 8)

            if let timestamp = summary?.lastMessageAt {
                Text(Self.relativeTime(timestamp))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 6)
    }

    /// 最終メッセージ。無ければ誘導文。
    private var previewText: String {
        if let text = summary?.lastMessageText, !text.isEmpty { return text }
        return "トークを始めましょう"
    }

    /// 送信時刻を LINE/インスタ風の短い相対表記にする（今日=HH:mm、昨日、1週間以内=曜日、それ以前=M/d）。
    static func relativeTime(_ timestamp: Double) -> String {
        let date = Date(timeIntervalSince1970: timestamp)
        let calendar = Calendar.current
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: date)
        }
        if calendar.isDateInYesterday(date) {
            return "昨日"
        }
        let days = calendar.dateComponents([.day],
                                           from: calendar.startOfDay(for: date),
                                           to: calendar.startOfDay(for: Date())).day ?? 0
        if days < 7 {
            formatter.dateFormat = "EEEE" // 曜日
            return formatter.string(from: date)
        }
        formatter.dateFormat = "M/d"
        return formatter.string(from: date)
    }
}

/// 友達アイコンの丸型表示。画像があれば画像を、なければ絵文字を表示する。
struct FriendAvatarCircle: View {
    let imageData: Data?
    let emoji: String
    var size: CGFloat = 56

    var body: some View {
        Group {
            if let imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            } else {
                Text(emoji)
                    .font(.system(size: size * 0.46))
            }
        }
        .frame(width: size, height: size)
        .background(Color.orange.opacity(0.15))
        .clipShape(Circle())
    }
}

#Preview {
    let friendsViewModel = FriendsViewModel()
    return FriendsListView(
        friendsViewModel: friendsViewModel,
        restaurantViewModel: RestaurantViewModel(friendsViewModel: friendsViewModel)
    )
}
