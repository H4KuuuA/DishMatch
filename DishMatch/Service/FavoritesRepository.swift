//
//  FavoritesRepository.swift
//  DishMatch
//
//  Created by Claude on 2026/08/08.
//

import Foundation
import FirebaseFirestore

/// いいねしたお店と「行った」状態の保存・購読を抽象化するプロトコル。
/// 「行った」お店は「いいねしたお店」の部分集合として、同じドキュメントの`visited`フラグで表現する。
protocol FavoritesRepository: Sendable {
    /// いいね一覧の変更をリアルタイムに購読する。
    /// - Parameter onChange: (いいねしたお店の配列, 「行った」お店IDの集合) が変更のたびに渡される
    /// - Returns: 購読解除トークン
    func observe(onChange: @escaping @Sendable ([Shop], Set<String>) -> Void) -> RepositoryToken?
    func add(_ shop: Shop) async throws
    func remove(shopID: String) async throws
    func setVisited(shopID: String, visited: Bool) async throws
}

/// Firestore（`users/{uid}/favorites`）にいいね・「行った」状態を保存・購読する実装。
final class RemoteFavoritesRepository: FavoritesRepository, @unchecked Sendable {
    private let store: UserStore

    init(uid: String) {
        self.store = UserStore(uid: uid)
    }

    /// Firestore に保存する1件分のドキュメント。Shop 全体を`shop`マップに入れ、
    /// 「行った」フラグと登録日時（並び順の保持用）を併記する。
    private struct FavoriteDocument: Codable {
        let shop: Shop
        var visited: Bool
        /// Like した順序を端末間で保つための登録時刻（timeIntervalSince1970）
        var createdAt: Double
    }

    func observe(onChange: @escaping @Sendable ([Shop], Set<String>) -> Void) -> RepositoryToken? {
        let registration = store.favorites.addSnapshotListener { snapshot, _ in
            guard let documents = snapshot?.documents else { return }
            let favorites = documents.compactMap { try? $0.data(as: FavoriteDocument.self) }
                .sorted { $0.createdAt < $1.createdAt }
            let shops = favorites.map(\.shop)
            let visitedIDs = Set(favorites.filter(\.visited).map(\.shop.id))
            onChange(shops, visitedIDs)
        }
        return FirestoreListenerToken(registration: registration)
    }

    func add(_ shop: Shop) async throws {
        let document = FavoriteDocument(shop: shop, visited: false, createdAt: Date().timeIntervalSince1970)
        try store.favorites.document(shop.id).setData(from: document, merge: true)
    }

    func remove(shopID: String) async throws {
        try await store.favorites.document(shopID).delete()
    }

    func setVisited(shopID: String, visited: Bool) async throws {
        try await store.favorites.document(shopID).updateData(["visited": visited])
    }
}
