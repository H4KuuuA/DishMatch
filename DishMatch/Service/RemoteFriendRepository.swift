//
//  RemoteFriendRepository.swift
//  DishMatch
//
//  Created by Claude on 2026/08/08.
//

import Foundation
import FirebaseFirestore

/// 友達データを Firestore（`users/{uid}/friends`）に保存・購読する実装。
/// `FriendRepository` に準拠しているため、`FriendsViewModel` へそのまま差し替えられる。
final class RemoteFriendRepository: FriendRepository, @unchecked Sendable {
    private let store: UserStore

    init(uid: String) {
        self.store = UserStore(uid: uid)
    }

    func fetchFriends() async throws -> [Friend] {
        let snapshot = try await store.friends.getDocuments()
        return snapshot.documents.compactMap { try? $0.data(as: Friend.self) }
    }

    func save(_ friend: Friend) async throws {
        // 友達コードをドキュメントIDに使い、同じ相手の重複登録を防ぐ
        try store.friends.document(friend.id).setData(from: friend, merge: true)
    }

    func delete(friendID: String) async throws {
        try await store.friends.document(friendID).delete()
    }

    func observe(onChange: @escaping @Sendable ([Friend]) -> Void) -> RepositoryToken? {
        let registration = store.friends.addSnapshotListener { snapshot, _ in
            guard let documents = snapshot?.documents else { return }
            let friends = documents.compactMap { try? $0.data(as: Friend.self) }
            onChange(friends)
        }
        return FirestoreListenerToken(registration: registration)
    }
}
