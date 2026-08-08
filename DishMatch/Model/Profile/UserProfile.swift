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

    private init() {}

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
        // 友達コードの設定が didSet 経由で persist() を呼び、既定値とともに書き込まれる。
        guard snapshot.exists, let data = snapshot.data() else {
            myFriendCode = Self.generateFriendCode()
            return
        }

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

        // 既存ドキュメントに友達コードが無ければ発行する（didSet が書き込む）
        if myFriendCode.isEmpty {
            myFriendCode = Self.generateFriendCode()
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
