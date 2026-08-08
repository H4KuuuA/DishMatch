//
//  DiscoerySettings.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/26.
//

import Foundation

@MainActor
final class DiscoverySettings: ObservableObject {
    static let shared = DiscoverySettings()

    /// 「こだわり」は選び過ぎると出会いの幅が狭くなるため、最大5個までに制限する
    static let maxParticularsCount = 5

    // 設定項目を @Published で宣言。値が変わるたびにUserDefaultsへ自動保存し、
    // アプリを再起動しても前回選んだ検索条件から再開できるようにする
    /// 現在地から探すか、都道府県などのエリアを指定して探すか
    @Published var searchLocationMode: SearchLocationMode = .currentLocation { didSet { persist() } }
    /// エリア指定検索時に使う都道府県相当のサービスエリアコード（例: "SA11"）
    @Published var selectedServiceAreaCode: String? { didSet { persist() } }
    @Published var selectedRange: MenuRangeType = .range5 { didSet { persist() } }
    @Published var selectedBudget: BudgetType = .noPreference { didSet { persist() } }
    /// 選択中のジャンルコード（例: "G001"）。nilなら絞り込まない
    @Published var selectedGenreCode: String? { didSet { persist() } }
    /// 選択中の「こだわり」条件。直接代入させず`toggleParticular(_:)`経由でのみ変更させることで
    /// 上限（5個）を常に守らせる
    @Published private(set) var selectedParticulars: Set<ParticularOption> = [] { didSet { persist() } }

    /// 現在の「こだわり」設定をAPIリクエスト用のパラメータに変換する
    var particulars: DiscoveryParticulars {
        DiscoveryParticulars(selected: selectedParticulars)
    }

    /// こだわりの選択上限に達しているかどうか
    var isParticularsLimitReached: Bool {
        selectedParticulars.count >= Self.maxParticularsCount
    }

    private static let userDefaultsKey = "DiscoverySettings.persisted"

    private init() {
        restore()
    }

    /// こだわり条件のON/OFFを切り替える。上限（5個）に達している状態で
    /// 新しい項目をONにしようとした場合は何もしない
    func toggleParticular(_ option: ParticularOption) {
        if selectedParticulars.contains(option) {
            selectedParticulars.remove(option)
        } else if selectedParticulars.count < Self.maxParticularsCount {
            selectedParticulars.insert(option)
        }
    }

    /// 現在の設定をUserDefaultsに保存する
    private func persist() {
        let snapshot = PersistedSnapshot(
            rangeRawValue: selectedRange.rawValue,
            budgetRawValue: selectedBudget.rawValue,
            genreCode: selectedGenreCode,
            particularRawValues: selectedParticulars.map(\.rawValue),
            searchLocationModeRawValue: searchLocationMode.rawValue,
            serviceAreaCode: selectedServiceAreaCode
        )
        guard let data = try? JSONEncoder().encode(snapshot) else { return }
        UserDefaults.standard.set(data, forKey: Self.userDefaultsKey)
    }

    /// 前回保存された設定をUserDefaultsから復元する
    private func restore() {
        guard let data = UserDefaults.standard.data(forKey: Self.userDefaultsKey),
              let snapshot = try? JSONDecoder().decode(PersistedSnapshot.self, from: data) else { return }

        selectedRange = MenuRangeType(rawValue: snapshot.rangeRawValue) ?? .range5
        selectedBudget = BudgetType(rawValue: snapshot.budgetRawValue) ?? .noPreference
        selectedGenreCode = snapshot.genreCode
        selectedParticulars = Set(snapshot.particularRawValues.compactMap(ParticularOption.init(rawValue:)))
        searchLocationMode = snapshot.searchLocationModeRawValue.flatMap(SearchLocationMode.init(rawValue:)) ?? .currentLocation
        selectedServiceAreaCode = snapshot.serviceAreaCode
    }

    private struct PersistedSnapshot: Codable {
        let rangeRawValue: Int
        let budgetRawValue: String
        var genreCode: String? = nil
        let particularRawValues: [String]
        var searchLocationModeRawValue: String? = nil
        var serviceAreaCode: String? = nil
    }
}

/// 現在地から探すか、都道府県などのエリアを指定して探すか
enum SearchLocationMode: String, Codable {
    case currentLocation
    case area
}

/// ホットペッパーグルメサーチAPIの「こだわり」絞り込み条件をクエリパラメータに変換する。
/// 各項目は `1` で「あり」に絞り込み、選択されていない項目は省略（絞り込まない）。
struct DiscoveryParticulars {
    var selected: Set<ParticularOption> = []

    static let none = DiscoveryParticulars()

    var queryItems: [URLQueryItem] {
        selected.map { URLQueryItem(name: $0.apiParameterName, value: "1") }
    }
}
