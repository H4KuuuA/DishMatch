//
//  FriendFocusModeTests.swift
//  DishMatchTests
//
//  Created by Claude on 2026/08/12.
//

import Testing
import Foundation
@testable import DishMatch

/// フォーカスモードのマッチ抑止ロジックを検証する。
/// フォーカス設定中は対象の1人としかマッチが成立しないこと（他の友達は候補から除外されること）を確認する。
@MainActor
struct FriendFocusModeTests {

    /// 隔離した UserDefaults を使い、同じお店をLike済みの2人の友達を持つ ViewModel を用意する。
    private func makeViewModel() async -> (vm: FriendsViewModel, uid: String) {
        let uid = "test-\(UUID().uuidString)"
        let suiteName = "FriendFocusModeTests.\(uid)"
        let suite = UserDefaults(suiteName: suiteName)!
        suite.removePersistentDomain(forName: suiteName)

        let repo = LocalFriendRepository(userDefaults: suite)
        let shopID = MockShop.mockShop.id
        try? await repo.save(Friend(id: "f1", name: "たろう", likedGenreCodes: [], likedShopIDs: [shopID]))
        try? await repo.save(Friend(id: "f2", name: "はなこ", likedGenreCodes: [], likedShopIDs: [shopID]))

        let vm = FriendsViewModel(repository: repo, myUid: uid)
        await vm.loadFriends()
        return (vm, uid)
    }

    /// フォーカス未設定なら、同じお店をLikeした友達全員がマッチ候補になる。
    @Test func matchesAllFriendsWhenFocusOff() async throws {
        let (vm, uid) = await makeViewModel()
        defer { UserDefaults.standard.removeObject(forKey: "focusedFriendID_\(uid)") }

        let matched = vm.friendsMatching(shop: MockShop.mockShop)
        #expect(matched.count == 2)
    }

    /// フォーカス設定中は、対象の1人だけがマッチし、他の友達は候補から除外される。
    @Test func matchesOnlyFocusedFriendWhenFocusOn() async throws {
        let (vm, uid) = await makeViewModel()
        defer { UserDefaults.standard.removeObject(forKey: "focusedFriendID_\(uid)") }

        let target = vm.friends.first { $0.id == "f1" }!
        vm.setFocus(target)

        let matched = vm.friendsMatching(shop: MockShop.mockShop)
        #expect(matched.count == 1)
        #expect(matched.first?.id == "f1")
    }

    /// フォーカスを解除すると再び全員がマッチ候補に戻る。
    @Test func clearingFocusRestoresAllFriends() async throws {
        let (vm, uid) = await makeViewModel()
        defer { UserDefaults.standard.removeObject(forKey: "focusedFriendID_\(uid)") }

        let target = vm.friends.first { $0.id == "f2" }!
        vm.setFocus(target)
        #expect(vm.friendsMatching(shop: MockShop.mockShop).count == 1)

        vm.clearFocus()
        #expect(vm.friendsMatching(shop: MockShop.mockShop).count == 2)
    }

    /// 公開プロフィール未設定（nil）の環境では friendsMatchingLive はキャッシュ判定へフォールバックし、
    /// その際もフォーカスの絞り込みが効く。
    @Test func liveMatchingRespectsFocus() async throws {
        let (vm, uid) = await makeViewModel()
        defer { UserDefaults.standard.removeObject(forKey: "focusedFriendID_\(uid)") }

        let target = vm.friends.first { $0.id == "f1" }!
        vm.setFocus(target)

        let matched = await vm.friendsMatchingLive(shop: MockShop.mockShop)
        #expect(matched.count == 1)
        #expect(matched.first?.id == "f1")
    }

    /// フォーカス対象の友達を削除すると、フォーカスモードは自動的に解除される。
    @Test func deletingFocusedFriendClearsFocus() async throws {
        let (vm, uid) = await makeViewModel()
        defer { UserDefaults.standard.removeObject(forKey: "focusedFriendID_\(uid)") }

        let target = vm.friends.first { $0.id == "f1" }!
        vm.setFocus(target)
        #expect(vm.focusedFriendID == "f1")

        await vm.delete(target)
        #expect(vm.focusedFriendID == nil)
    }
}
