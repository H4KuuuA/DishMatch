//
//  UserProfile.swift
//  DishMatch
//
//  Created by Claude on 2026/08/06.
//

import Foundation
import FirebaseFirestore

/// ユーザー自身のプロフィール情報。ニックネームや自己紹介を Firestore(`users/{uid}`) にリアルタイム同期する。
/// アプリ全体で共有する単一インスタンスのため、ログイン状態に応じて`bind(uid:)`/`unbind()`で
/// 同期の開始・停止を切り替える（呼び出しは ContentView が担当）。
@MainActor
final class UserProfile: ObservableObject {
    static let shared = UserProfile()

    @Published var nickname: String = UserProfile.defaultNickname { didSet { persist() } }
    @Published var bio: String = "" { didSet { persist() } }
    /// 写真から設定したアイコン画像（リサイズ済みJPEG）。未設定ならデフォルト画像を使う。
    /// Firestore には base64 文字列として保存する。
    @Published var avatarImageData: Data? { didSet { persist() } }
    /// 友達に共有して自分を追加してもらうためのID。ドキュメント初回作成時に自動生成する。
    @Published private(set) var myFriendCode: String = "" { didSet { persist() } }

    private static let defaultNickname = "ご飯探検隊"

    /// 同期対象のユーザーID。未ログイン時は nil で、この間は書き込みを行わない。
    private var uid: String?
    private var listener: ListenerRegistration?
    /// リモートからの反映中は didSet の書き戻しを止め、無限ループを防ぐためのフラグ
    private var isApplyingRemote = false
    /// 新規登録画面で入力された初期プロフィール。サインアップ直後の初回ドキュメント作成時に反映する。
    /// bind() が呼ぶ unbind() では消さず、apply() で使い切ったら nil に戻す。
    private var pendingRegistration: (nickname: String, avatarImageData: Data?)?

    /// 友達に公開するプロフィール（publicProfiles/friendCodes）の書き込み先
    private let publicProfileRepository = PublicProfileRepository()
    /// 公開プロフィールに載せる「自分の好きなジャンル」。RestaurantViewModelが
    /// お気に入りの変化に応じて`syncLikedGenres`で更新する
    private var likedGenreCodesCache: [String] = []
    /// 公開プロフィールに載せる「自分がLikeしたお店のID」。マッチ判定に使う。
    /// RestaurantViewModelが`syncLikedShopIDs`で更新する
    private var likedShopIDsCache: [String] = []

    private init() {}

    /// 新規登録画面で入力した名前・アイコンを、サインアップ直後の初回同期で反映させるために事前登録する。
    /// `bind`（＝Firestore同期開始）より前に呼ぶ想定。空名は既定値にフォールバックする。
    func stageRegistration(nickname: String, avatarImageData: Data?) {
        let trimmed = nickname.trimmingCharacters(in: .whitespacesAndNewlines)
        pendingRegistration = (trimmed.isEmpty ? Self.defaultNickname : trimmed, avatarImageData)
    }

    /// 事前登録した初期プロフィールを破棄する（サインアップ失敗時などに使う）。
    func clearStagedRegistration() {
        pendingRegistration = nil
    }

    /// 指定ユーザーの Firestore ドキュメントとの同期を開始する。
    func bind(uid: String) {
        guard self.uid != uid else { return }
        unbind()
        self.uid = uid

        listener = document(for: uid).addSnapshotListener { [weak self] snapshot, _ in
            guard let self else { return }
            Task { @MainActor in self.apply(snapshot: snapshot) }
        }
    }

    /// 同期を停止し、前のユーザーの情報が残らないよう初期値へ戻す。
    func unbind() {
        listener?.remove()
        listener = nil
        uid = nil

        isApplyingRemote = true
        nickname = Self.defaultNickname
        bio = ""
        avatarImageData = nil
        myFriendCode = ""
        isApplyingRemote = false
    }

    /// Firestore のスナップショットをローカルの @Published プロパティへ反映する。
    private func apply(snapshot: DocumentSnapshot?) {
        guard let snapshot else { return }

        // まだ存在しない（新規ユーザー）ならドキュメントを作成する。
        // 友達コードの設定が didSet 経由で persist() を呼び、（下で反映した名前・アイコンと）
        // ともに書き込まれる。
        guard snapshot.exists, let data = snapshot.data() else {
            // 新規登録画面で名前・アイコンを入力していれば、既定値の代わりに初期値として反映する。
            if let pending = pendingRegistration {
                isApplyingRemote = true
                nickname = pending.nickname
                avatarImageData = pending.avatarImageData
                isApplyingRemote = false
                pendingRegistration = nil
            }
            myFriendCode = Self.generateFriendCode()
            return
        }

        // 既存ドキュメントに同期するので、使われなかった事前登録は破棄する（別アカウントへの混入防止）。
        pendingRegistration = nil

        isApplyingRemote = true
        nickname = data["nickname"] as? String ?? Self.defaultNickname
        bio = data["bio"] as? String ?? ""
        if let base64 = data["avatarBase64"] as? String, let imageData = Data(base64Encoded: base64) {
            avatarImageData = imageData
        } else {
            avatarImageData = nil
        }
        let remoteFriendCode = data["myFriendCode"] as? String ?? ""
        myFriendCode = remoteFriendCode
        isApplyingRemote = false

        // 既存ドキュメントに友達コードが無ければ発行する（didSet が persist→syncPublicProfile を呼ぶ）
        if myFriendCode.isEmpty {
            myFriendCode = Self.generateFriendCode()
        } else if let uid {
            // 友達コードが既にある既存ユーザーは didSet が発火しないため、
            // 友達検索に必要な公開プロフィール（publicProfiles / friendCodes）をここで確実に同期する。
            // これが無いと、この機能導入前から居るユーザーは友達に見つけてもらえない。
            syncPublicProfile(uid: uid)
        }
    }

    /// 現在のプロフィールを Firestore に保存する。未ログイン時・リモート反映中は何もしない。
    private func persist() {
        guard let uid, !isApplyingRemote else { return }

        var payload: [String: Any] = [
            "nickname": nickname,
            "bio": bio,
            "myFriendCode": myFriendCode,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        if let avatarImageData {
            payload["avatarBase64"] = avatarImageData.base64EncodedString()
        } else {
            payload["avatarBase64"] = FieldValue.delete()
        }
        document(for: uid).setData(payload, merge: true) { error in
            if let error {
                print("DEBUG: プロフィール同期エラー \(error.localizedDescription)")
            }
        }

        syncPublicProfile(uid: uid)
    }

    /// 友達に見せる公開プロフィール（publicProfiles/{uid}）と友達コード対応表を更新する。
    private func syncPublicProfile(uid: String) {
        guard !myFriendCode.isEmpty else { return }
        var fields: [String: Any] = [
            "nickname": nickname,
            "friendCode": myFriendCode,
            "likedGenreCodes": likedGenreCodesCache,
            "likedShopIDs": likedShopIDsCache
        ]
        // 公開プロフィールにもアイコンを載せて友達側で表示できるようにする
        fields["avatarBase64"] = avatarImageData?.base64EncodedString() ?? FieldValue.delete()
        publicProfileRepository.upsert(uid: uid, fields: fields)
        publicProfileRepository.registerFriendCode(myFriendCode, uid: uid)
    }

    /// 自分がLikeしたお店のジャンル集合を公開プロフィールへ反映する。
    /// 友達側で「同じジャンルをLikeした時のマッチ判定」に使われる。
    func syncLikedGenres(_ codes: Set<String>) {
        let sorted = codes.sorted()
        guard sorted != likedGenreCodesCache else { return }
        likedGenreCodesCache = sorted
        guard let uid else { return }
        publicProfileRepository.upsert(uid: uid, fields: ["likedGenreCodes": sorted])
    }

    /// 自分がLikeしたお店のID集合を公開プロフィールへ反映する。
    /// 友達側で「同じお店をLikeした時のマッチ判定」に使われる。
    func syncLikedShopIDs(_ ids: Set<String>) {
        let sorted = ids.sorted()
        guard sorted != likedShopIDsCache else { return }
        likedShopIDsCache = sorted
        guard let uid else { return }
        publicProfileRepository.upsert(uid: uid, fields: ["likedShopIDs": sorted])
    }

    private func document(for uid: String) -> DocumentReference {
        Firestore.firestore().collection("users").document(uid)
    }

    /// 紛らわしい文字（0/O、1/I など）を除いた8桁の英数字コードを生成する
    private static func generateFriendCode() -> String {
        let characters = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789"
        return String((0..<8).compactMap { _ in characters.randomElement() })
    }
}
