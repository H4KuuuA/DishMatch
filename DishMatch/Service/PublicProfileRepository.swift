//
//  PublicProfileRepository.swift
//  DishMatch
//
//  Created by Claude on 2026/08/08.
//

import Foundation
import FirebaseFirestore

/// 友達に公開するプロフィール。`publicProfiles/{uid}` に保存し、ログイン中の他ユーザーが
/// 友達検索・申請時に参照できる。個人情報は最小限（ニックネーム・アイコン・好きなジャンル）に留める。
struct PublicProfile: Codable, Equatable {
    var uid: String
    var nickname: String
    var friendCode: String
    var avatarBase64: String?
    var likedGenreCodes: [String]
    /// この人がLikeしたお店のID一覧。マッチ判定に使う。
    /// 既存ドキュメントには無い場合があるためデコードに失敗しないよう optional にしている。
    var likedShopIDs: [String]?
    var updatedAt: Double?
}

/// 公開プロフィールと友達コード対応表（`friendCodes/{code}` → uid）を扱うリポジトリ。
/// 自分の公開プロフィールの書き込みと、友達検索のための読み取りの両方を提供する。
final class PublicProfileRepository: @unchecked Sendable {
    private let db = Firestore.firestore()

    // MARK: - 読み取り（友達検索）

    /// 友達コードから相手のuidを解決する。存在しなければ nil。
    func resolveFriendCode(_ code: String) async throws -> String? {
        let snapshot = try await db.collection("friendCodes").document(code).getDocument()
        return snapshot.data()?["uid"] as? String
    }

    /// 指定uidの公開プロフィールを取得する。
    /// - Parameter source: 取得元。マッチ判定など最新値が必要な場面では `.server` を指定してサーバーから取得する。
    func fetchProfile(uid: String, source: FirestoreSource = .default) async throws -> PublicProfile? {
        let snapshot = try await db.collection("publicProfiles").document(uid).getDocument(source: source)
        return try? snapshot.data(as: PublicProfile.self)
    }

    // MARK: - 書き込み（自分の公開情報）

    /// 自分の公開プロフィールを部分更新（merge）する。
    func upsert(uid: String, fields: [String: Any]) {
        var payload = fields
        payload["uid"] = uid
        payload["updatedAt"] = Date().timeIntervalSince1970
        db.collection("publicProfiles").document(uid).setData(payload, merge: true) { error in
            if let error {
                print("DEBUG: 公開プロフィール同期エラー \(error.localizedDescription)")
            }
        }
    }

    /// 友達コード → uid の対応表を登録する。
    func registerFriendCode(_ code: String, uid: String) {
        guard !code.isEmpty else { return }
        db.collection("friendCodes").document(code).setData(["uid": uid], merge: true) { error in
            if let error {
                print("DEBUG: 友達コード登録エラー \(error.localizedDescription)")
            }
        }
    }
}
