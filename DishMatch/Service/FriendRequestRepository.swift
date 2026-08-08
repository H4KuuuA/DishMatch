//
//  FriendRequestRepository.swift
//  DishMatch
//
//  Created by Claude on 2026/08/08.
//

import Foundation
import FirebaseFirestore

/// 友達申請（`friendRequests`）の作成・購読・更新を扱うリポジトリ。
///
/// Cloud Functions を使わずに双方向の友達関係を成立させるため、次の流れで運用する:
/// 1. AがBへ申請を作成（status = pending）
/// 2. Bが承認 → status = accepted にし、Bは自分の `users/{B}/friends/{A}` を書く
/// 3. Aは「自分が送って accepted になった申請」を購読しており、それを検知して
///    自分の `users/{A}/friends/{B}` を書き、申請を削除する（reconcile）
final class FriendRequestRepository: @unchecked Sendable {
    private let db = Firestore.firestore()

    private var collection: CollectionReference {
        db.collection("friendRequests")
    }

    /// 申請を送る。既に同じ相手への申請があれば上書き（冪等）。
    func sendRequest(from fromUid: String, to toUid: String, fromNickname: String) async throws {
        let id = FriendRequest.makeID(from: fromUid, to: toUid)
        let request = FriendRequest(
            id: id,
            fromUid: fromUid,
            toUid: toUid,
            fromNickname: fromNickname,
            status: .pending,
            createdAt: Date().timeIntervalSince1970
        )
        try collection.document(id).setData(from: request, merge: true)
    }

    /// 自分宛の「保留中(pending)」の申請一覧をリアルタイム購読する。
    func observeIncoming(myUid: String, onChange: @escaping @Sendable ([FriendRequest]) -> Void) -> RepositoryToken? {
        let query = collection
            .whereField("toUid", isEqualTo: myUid)
            .whereField("status", isEqualTo: FriendRequest.Status.pending.rawValue)
        let registration = query.addSnapshotListener { snapshot, _ in
            guard let documents = snapshot?.documents else { return }
            let requests = documents.compactMap { try? $0.data(as: FriendRequest.self) }
                .sorted { $0.createdAt > $1.createdAt }
            onChange(requests)
        }
        return FirestoreListenerToken(registration: registration)
    }

    /// 自分が送って「承認済み(accepted)」になった申請一覧をリアルタイム購読する（reconcile用）。
    func observeAcceptedOutgoing(myUid: String, onChange: @escaping @Sendable ([FriendRequest]) -> Void) -> RepositoryToken? {
        let query = collection
            .whereField("fromUid", isEqualTo: myUid)
            .whereField("status", isEqualTo: FriendRequest.Status.accepted.rawValue)
        let registration = query.addSnapshotListener { snapshot, _ in
            guard let documents = snapshot?.documents else { return }
            let requests = documents.compactMap { try? $0.data(as: FriendRequest.self) }
            onChange(requests)
        }
        return FirestoreListenerToken(registration: registration)
    }

    /// 受信した申請を承認済みに更新する。
    func markAccepted(requestID: String) async throws {
        try await collection.document(requestID).updateData([
            "status": FriendRequest.Status.accepted.rawValue
        ])
    }

    /// 申請を削除する（拒否・reconcile完了時）。
    func delete(requestID: String) async throws {
        try await collection.document(requestID).delete()
    }
}
