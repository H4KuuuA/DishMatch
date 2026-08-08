//
//  FriendRequest.swift
//  DishMatch
//
//  Created by Claude on 2026/08/08.
//

import Foundation

/// 友達申請1件分の情報。Firestore の `friendRequests/{fromUid}__{toUid}` に保存する。
/// LINE のように「申請 → 承認」で双方向の友達関係を成立させるための中間データ。
struct FriendRequest: Identifiable, Codable, Equatable {
    /// ドキュメントID（"{fromUid}__{toUid}"）
    var id: String
    /// 申請を送った人のuid
    let fromUid: String
    /// 申請を受け取る人のuid
    let toUid: String
    /// 一覧表示用に申請者のニックネームを複製しておく（受信側が publicProfiles を読む前に表示できる）
    var fromNickname: String
    /// 申請の状態
    var status: Status
    /// 送信時刻（timeIntervalSince1970）。並び順に使う
    var createdAt: Double

    enum Status: String, Codable {
        case pending
        case accepted
    }

    /// fromUid と toUid から決まる安定したドキュメントID。
    static func makeID(from fromUid: String, to toUid: String) -> String {
        "\(fromUid)__\(toUid)"
    }
}
