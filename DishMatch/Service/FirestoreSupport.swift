//
//  FirestoreSupport.swift
//  DishMatch
//
//  Created by Claude on 2026/08/08.
//

import Foundation
import FirebaseFirestore

/// Firestore のリアルタイムリスナーを解除するためのトークン。
/// Firebase 依存をリポジトリの外へ漏らさないよう、抽象化して公開する。
protocol RepositoryToken {
    func cancel()
}

/// Firestore の `ListenerRegistration` を `RepositoryToken` としてラップする。
struct FirestoreListenerToken: RepositoryToken {
    let registration: ListenerRegistration
    func cancel() { registration.remove() }
}

/// ログイン中ユーザーの Firestore 上のドキュメント階層への参照をまとめたヘルパー。
/// `users/{uid}` 以下の各コレクションへのアクセス経路を一元化する。
struct UserStore {
    let uid: String
    private let db = Firestore.firestore()

    var userDocument: DocumentReference {
        db.collection("users").document(uid)
    }

    /// いいねしたお店（＋「行った」フラグ）を保存するサブコレクション
    var favorites: CollectionReference {
        userDocument.collection("favorites")
    }

    /// 登録した友達を保存するサブコレクション
    var friends: CollectionReference {
        userDocument.collection("friends")
    }
}
