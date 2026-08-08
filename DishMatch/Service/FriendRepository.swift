//
//  FriendRepository.swift
//  DishMatch
//
//  Created by Claude on 2026/08/07.
//

import Foundation

enum FriendRepositoryError: Error {
    case encodingFailed
    case decodingFailed
}

/// 友達データの取得・保存を抽象化するプロトコル。
///
/// 現在は`LocalFriendRepository`がUserDefaultsにローカル保存するだけだが、
/// 将来サーバーAPIができた際は`RemoteFriendRepository`のような別実装をこのプロトコルに
/// 準拠させて`FriendsViewModel`に渡すだけで移行できるよう、あえて`async throws`にしている。
protocol FriendRepository: Sendable {
    func fetchFriends() async throws -> [Friend]
    func save(_ friend: Friend) async throws
    func delete(friendID: String) async throws
    /// 友達一覧の変更をリアルタイムに購読する。変更があるたび`onChange`が最新の一覧で呼ばれる。
    /// リアルタイムに対応しない実装（ローカル等）は`nil`を返してよい（呼び出し側は`fetchFriends`にフォールバックする）。
    /// - Returns: 購読を解除するためのトークン。不要になったら`cancel()`を呼ぶ。
    func observe(onChange: @escaping @Sendable ([Friend]) -> Void) -> RepositoryToken?
}

extension FriendRepository {
    // デフォルトではリアルタイム購読に対応しない
    func observe(onChange: @escaping @Sendable ([Friend]) -> Void) -> RepositoryToken? { nil }
}

/// UserDefaultsにJSONとして保存するローカル実装。サーバーができるまでの暫定実装。
final class LocalFriendRepository: FriendRepository, @unchecked Sendable {
    private static let userDefaultsKey = "FriendRepository.friends"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
    }

    func fetchFriends() async throws -> [Friend] {
        guard let data = userDefaults.data(forKey: Self.userDefaultsKey) else { return [] }
        guard let friends = try? JSONDecoder().decode([Friend].self, from: data) else {
            throw FriendRepositoryError.decodingFailed
        }
        return friends
    }

    func save(_ friend: Friend) async throws {
        var friends = try await fetchFriends()
        if let index = friends.firstIndex(where: { $0.id == friend.id }) {
            friends[index] = friend
        } else {
            friends.append(friend)
        }
        try persist(friends)
    }

    func delete(friendID: String) async throws {
        var friends = try await fetchFriends()
        friends.removeAll { $0.id == friendID }
        try persist(friends)
    }

    private func persist(_ friends: [Friend]) throws {
        guard let data = try? JSONEncoder().encode(friends) else {
            throw FriendRepositoryError.encodingFailed
        }
        userDefaults.set(data, forKey: Self.userDefaultsKey)
    }
}
