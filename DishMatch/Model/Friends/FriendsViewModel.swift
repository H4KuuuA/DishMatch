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
    /// 自分宛の保留中の友達申請一覧
    @Published private(set) var incomingRequests: [FriendRequest] = []
    @Published private(set) var isLoading = false
    /// 直近の読み込み・保存エラー。ジャンル取得の失敗と同時に起こりうるため、
    /// 呼び出し元でErrorQueueに積んで多重エラーとして扱えるようにしている
    @Published private(set) var lastError: AppError?

    private let repository: FriendRepository
    /// 友達申請の送受信先。ログイン中のみ非nil。
    private let friendRequestRepository: FriendRequestRepository?
    /// 相手の公開プロフィール取得・友達コード解決に使う。ログイン中のみ非nil。
    private let publicProfileRepository: PublicProfileRepository?
    /// 自分のuid。ログイン中のみ非nil。
    private let myUid: String?

    /// 自分のuid（チャット画面など外部からの参照用）。未ログイン時は nil。
    var currentUid: String? { myUid }

    /// 各リアルタイム購読の解除トークン。deinit（nonisolated）から解除するため nonisolated(unsafe)。
    nonisolated(unsafe) private var observationToken: RepositoryToken?
    nonisolated(unsafe) private var incomingToken: RepositoryToken?
    nonisolated(unsafe) private var acceptedOutgoingToken: RepositoryToken?
    private var isObserving = false
    /// refreshFriendProfiles の再入防止（購読更新と重なって多重に走るのを防ぐ）
    private var isRefreshingProfiles = false

    /// - Parameters:
    ///   - repository: 友達データの保存先。ログイン中は`RemoteFriendRepository`。
    ///   - friendRequestRepository: 友達申請の送受信先。ログイン中のみ渡す。
    ///   - publicProfileRepository: 公開プロフィールの参照先。ログイン中のみ渡す。
    ///   - myUid: 自分のuid。ログイン中のみ渡す。
    init(repository: FriendRepository = LocalFriendRepository(),
         friendRequestRepository: FriendRequestRepository? = nil,
         publicProfileRepository: PublicProfileRepository? = nil,
         myUid: String? = nil) {
        self.repository = repository
        self.friendRequestRepository = friendRequestRepository
        self.publicProfileRepository = publicProfileRepository
        self.myUid = myUid
        startObserving()
    }

    deinit {
        observationToken?.cancel()
        incomingToken?.cancel()
        acceptedOutgoingToken?.cancel()
    }

    /// リアルタイム購読を開始する。非対応リポジトリなら一度だけ取得する。
    private func startObserving() {
        let token = repository.observe { [weak self] friends in
            Task { @MainActor in
                self?.friends = friends
                // 友達の最新の「好きなジャンル」を取り込み直し、マッチ判定を最新に保つ
                await self?.refreshFriendProfiles()
            }
        }
        if let token {
            observationToken = token
            isObserving = true
        } else {
            Task { await loadFriends() }
        }

        // 友達申請の購読（ログイン中のみ）
        if let friendRequestRepository, let myUid {
            incomingToken = friendRequestRepository.observeIncoming(myUid: myUid) { [weak self] requests in
                Task { @MainActor in self?.incomingRequests = requests }
            }
            acceptedOutgoingToken = friendRequestRepository.observeAcceptedOutgoing(myUid: myUid) { [weak self] requests in
                Task { @MainActor in await self?.reconcileAccepted(requests) }
            }
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

    /// 各友達の公開プロフィール（好きなジャンル・名前・アイコン）を取り込み直す。
    ///
    /// 友達の likedGenreCodes は承認時のスナップショットのままだと古くなり、相手が後から
    /// お店をLikeしても「マッチ」が成立しない。ここで最新の publicProfiles を反映することで、
    /// マッチ判定（friendsMatching）が相手の現在の好みに追従する。変化があった友達だけ保存する。
    func refreshFriendProfiles() async {
        guard let publicProfileRepository, !isRefreshingProfiles else { return }
        isRefreshingProfiles = true
        defer { isRefreshingProfiles = false }

        for friend in friends {
            do {
                guard let profile = try await publicProfileRepository.fetchProfile(uid: friend.id) else { continue }
                let updated = Friend(
                    id: friend.id,
                    name: profile.nickname,
                    avatarEmoji: friend.avatarEmoji,
                    avatarBase64: profile.avatarBase64,
                    likedGenreCodes: Set(profile.likedGenreCodes),
                    likedShopIDs: Set(profile.likedShopIDs ?? [])
                )
                // 変化があった時だけ保存（購読→保存の無限ループを防ぐ）
                if updated != friend {
                    try await repository.save(updated)
                }
            } catch {
                print("DEBUG: 友達プロフィールの更新エラー \(error.localizedDescription)")
            }
        }
    }

    // MARK: - 友達申請

    /// 友達コードを指定して申請を送る。
    /// - Returns: 申請の送信に成功したら true。
    @discardableResult
    func sendFriendRequest(toCode code: String) async -> Bool {
        let trimmed = code.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        guard !trimmed.isEmpty else { return false }
        guard let friendRequestRepository, let publicProfileRepository, let myUid else {
            lastError = AppError(title: "友達を追加できません", message: "ログイン状態を確認して、もう一度お試しください。")
            return false
        }

        do {
            guard let targetUid = try await publicProfileRepository.resolveFriendCode(trimmed) else {
                lastError = AppError(title: "見つかりませんでした", message: "そのIDのユーザーが見つかりません。IDが正しいか確認してください。")
                return false
            }
            guard targetUid != myUid else {
                lastError = AppError(title: "自分は追加できません", message: "自分自身を友達に追加することはできません。")
                return false
            }
            guard !friends.contains(where: { $0.id == targetUid }) else {
                lastError = AppError(title: "登録済みです", message: "この友達はすでに登録されています。")
                return false
            }
            try await friendRequestRepository.sendRequest(from: myUid, to: targetUid, fromNickname: UserProfile.shared.nickname)
            return true
        } catch {
            print("DEBUG: 友達申請エラー \(error.localizedDescription)")
            lastError = AppError.from(error, fallbackTitle: "友達申請を送れませんでした")
            return false
        }
    }

    /// 受信した申請を承認し、相手を友達に登録する。
    func acceptRequest(_ request: FriendRequest) async {
        guard let friendRequestRepository, let publicProfileRepository else { return }
        do {
            let profile = try await publicProfileRepository.fetchProfile(uid: request.fromUid)
            let friend = makeFriend(fromUid: request.fromUid, fallbackName: request.fromNickname, profile: profile)
            try await repository.save(friend)
            try await friendRequestRepository.markAccepted(requestID: request.id)
        } catch {
            print("DEBUG: 友達申請の承認エラー \(error.localizedDescription)")
            lastError = AppError.from(error, fallbackTitle: "友達申請を承認できませんでした")
        }
    }

    /// 受信した申請を拒否する。
    func rejectRequest(_ request: FriendRequest) async {
        guard let friendRequestRepository else { return }
        do {
            try await friendRequestRepository.delete(requestID: request.id)
        } catch {
            print("DEBUG: 友達申請の拒否エラー \(error.localizedDescription)")
            lastError = AppError.from(error, fallbackTitle: "友達申請を拒否できませんでした")
        }
    }

    /// 自分が送って承認された申請を検知し、自分側の友達一覧にも相手を登録して申請を削除する。
    private func reconcileAccepted(_ requests: [FriendRequest]) async {
        guard let friendRequestRepository, let publicProfileRepository else { return }
        for request in requests {
            do {
                if !friends.contains(where: { $0.id == request.toUid }) {
                    let profile = try await publicProfileRepository.fetchProfile(uid: request.toUid)
                    let friend = makeFriend(fromUid: request.toUid, fallbackName: request.toUid, profile: profile)
                    try await repository.save(friend)
                }
                try await friendRequestRepository.delete(requestID: request.id)
            } catch {
                print("DEBUG: 友達関係の同期エラー \(error.localizedDescription)")
            }
        }
    }

    /// 公開プロフィールから Friend を作る。プロフィール取得に失敗した場合は最低限の情報で作る。
    private func makeFriend(fromUid uid: String, fallbackName: String, profile: PublicProfile?) -> Friend {
        Friend(
            id: uid,
            name: profile?.nickname ?? fallbackName,
            avatarBase64: profile?.avatarBase64,
            likedGenreCodes: Set(profile?.likedGenreCodes ?? []),
            likedShopIDs: Set(profile?.likedShopIDs ?? [])
        )
    }

    // MARK: - 友達の更新・削除

    /// 既存の友達情報を更新する
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

    /// 指定したお店を「同じくLikeしている」友達を返す（複数いれば全員）。
    /// Likeした瞬間の「友達とのマッチ」判定に使う。ジャンルではなく同一のお店（shop.id）で判定するため、
    /// 友達が同じお店をLikeしている時だけマッチが成立する。
    func friendsMatching(shop: Shop) -> [Friend] {
        friends.filter { $0.likedShopIDs.contains(shop.id) }
    }

    /// Likeした瞬間に、相手の最新の公開プロフィールをサーバーから取得して「同じお店をLike済みの友達」を返す。
    ///
    /// キャッシュ（`friends`のlikedShopIDs）は友達一覧の更新時にしか取り込まれないため、セッション中に
    /// 相手がLikeしても即座には反映されない。ここで各友達の`publicProfiles`を都度取得することで、
    /// Likeした時点の相手のLike状況でリアルタイムに判定する。取得失敗時はキャッシュにフォールバックする。
    func friendsMatchingLive(shop: Shop) async -> [Friend] {
        guard let publicProfileRepository, !friends.isEmpty else {
            return friendsMatching(shop: shop)
        }
        var matched: [Friend] = []
        for friend in friends {
            do {
                let profile = try await publicProfileRepository.fetchProfile(uid: friend.id, source: .server)
                if Set(profile?.likedShopIDs ?? []).contains(shop.id) {
                    matched.append(friend)
                }
            } catch {
                // ネットワーク不良などで取得できない時は、取り込み済みのキャッシュで判定する
                print("DEBUG: 友達の最新Like取得エラー \(error.localizedDescription)")
                if friend.likedShopIDs.contains(shop.id) {
                    matched.append(friend)
                }
            }
        }
        return matched
    }
}
