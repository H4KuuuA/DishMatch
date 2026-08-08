//
//  FriendsViewModel.swift
//  DishMatch
//
//  Created by Claude on 2026/08/07.
//

import Foundation

@MainActor
final class FriendsViewModel: ObservableObject {
    @Published private(set) var friends: [Friend] = []
    @Published private(set) var isLoading = false
    /// 直近の読み込み・保存エラー。ジャンル取得の失敗と同時に起こりうるため、
    /// 呼び出し元でErrorQueueに積んで多重エラーとして扱えるようにしている
    @Published private(set) var lastError: AppError?

    private let repository: FriendRepository
    /// リアルタイム購読の解除トークン。リアルタイム対応リポジトリのときのみ非nil。
    /// deinit（nonisolated）から解除するため nonisolated(unsafe) で宣言する。cancel は Firestore 側でスレッド安全。
    nonisolated(unsafe) private var observationToken: RepositoryToken?
    /// リアルタイム購読中かどうか。購読中は書き込み結果をリスナー経由で反映するため、
    /// add/update/delete での手動配列操作を行わない。
    private var isObserving = false

    /// - Parameter repository: 友達データの取得・保存先。ログイン中は`RemoteFriendRepository`を渡す。
    init(repository: FriendRepository = LocalFriendRepository()) {
        self.repository = repository
        startObserving()
    }

    deinit {
        observationToken?.cancel()
    }

    /// リアルタイム購読を開始する。非対応リポジトリなら一度だけ取得する。
    private func startObserving() {
        let token = repository.observe { [weak self] friends in
            Task { @MainActor in self?.friends = friends }
        }
        if let token {
            observationToken = token
            isObserving = true
        } else {
            Task { await loadFriends() }
        }
    }

    func loadFriends() async {
        isLoading = true
        do {
            friends = try await repository.fetchFriends()
        } catch {
            print("DEBUG: 友達一覧の取得エラー \(error.localizedDescription)")
            lastError = AppError.from(error, fallbackTitle: "友達一覧を読み込めませんでした")
        }
        isLoading = false
    }

    /// 友達を新規登録する
    /// - Parameter id: 相手が共有してくれた友達コード
    func addFriend(id: String, name: String, avatarEmoji: String, likedGenreCodes: Set<String>) async {
        let friend = Friend(id: id, name: name, avatarEmoji: avatarEmoji, likedGenreCodes: likedGenreCodes)
        // リアルタイム購読中はリスナーが反映するため、手動追加はしない
        if !isObserving {
            friends.append(friend)
        }
        do {
            try await repository.save(friend)
        } catch {
            print("DEBUG: 友達の保存エラー \(error.localizedDescription)")
            lastError = AppError.from(error, fallbackTitle: "友達を保存できませんでした")
        }
    }

    /// 既存の友達情報（好みジャンルの変更など）を更新する
    func update(_ friend: Friend) async {
        if !isObserving {
            guard let index = friends.firstIndex(where: { $0.id == friend.id }) else { return }
            friends[index] = friend
        }
        do {
            try await repository.save(friend)
        } catch {
            print("DEBUG: 友達の更新エラー \(error.localizedDescription)")
            lastError = AppError.from(error, fallbackTitle: "友達の情報を更新できませんでした")
        }
    }

    func delete(_ friend: Friend) async {
        if !isObserving {
            friends.removeAll { $0.id == friend.id }
        }
        do {
            try await repository.delete(friendID: friend.id)
        } catch {
            print("DEBUG: 友達の削除エラー \(error.localizedDescription)")
            lastError = AppError.from(error, fallbackTitle: "友達を削除できませんでした")
        }
    }

    /// 指定したお店のジャンルを好みとして登録している友達を返す（複数いれば全員）。
    /// Likeした瞬間の「友達とのマッチ」判定に使う
    func friendsMatching(shop: Shop) -> [Friend] {
        friends.filter { $0.likedGenreCodes.contains(shop.genre.code) }
    }
}
