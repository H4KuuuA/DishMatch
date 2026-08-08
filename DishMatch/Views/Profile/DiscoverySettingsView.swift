//
//  DiscoverySettingsView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//


import SwiftUI

struct DiscoverySettingsView: View {
    @Environment(\.dismiss) var dismiss
    // シングルトンインスタンスを @ObservedObject として利用
    @ObservedObject private var settings = DiscoverySettings.shared
    @ObservedObject private var genreCatalog = GenreCatalog.shared
    @ObservedObject private var areaCatalog = AreaCatalog.shared
    @StateObject private var errorQueue = ErrorQueue()
    @ObservedObject var restaurantViewModel: RestaurantViewModel
    @Binding var viewID: UUID // ビュー更新用の識別子

    var body: some View {
        NavigationView {
            Form {
                // 検索方法（現在地 or エリア指定）
                Section {
                    Picker("検索方法", selection: $settings.searchLocationMode) {
                        Text("現在地から探す").tag(SearchLocationMode.currentLocation)
                        Text("エリアを指定する").tag(SearchLocationMode.area)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                } footer: {
                    if settings.searchLocationMode == .area {
                        Text("現在地の代わりに、選んだ都道府県で出会えるお店を探します。")
                    }
                }

                if settings.searchLocationMode == .currentLocation {
                    // 距離設定
                    Section {
                        HStack {
                            Text("距離")
                            Spacer()
                            Text(settings.selectedRange.range)
                                .foregroundColor(.gray)
                        }
                        Picker("距離", selection: $settings.selectedRange) {
                            ForEach(MenuRangeType.allCases, id: \.self) { rangeOption in
                                Text(rangeOption.range).tag(rangeOption)
                            }
                        }
                        .pickerStyle(SegmentedPickerStyle())
                    }
                } else {
                    // エリア設定
                    Section {
                        if areaCatalog.isLoading && areaCatalog.serviceAreas.isEmpty {
                            HStack {
                                Text("都道府県")
                                Spacer()
                                ProgressView()
                            }
                        } else {
                            Picker("都道府県", selection: $settings.selectedServiceAreaCode) {
                                Text("選択してください").tag(String?.none)
                                ForEach(areaCatalog.serviceAreas) { area in
                                    Text(area.name).tag(String?.some(area.code))
                                }
                            }
                            .pickerStyle(MenuPickerStyle())
                        }
                    }
                }

                // 予算設定
                Section {
                    Picker("予算", selection: $settings.selectedBudget) {
                        ForEach(BudgetType.allCases, id: \.self) { budget in
                            Text(budget.rawValue).tag(budget)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                }

                // ジャンル設定
                Section {
                    if genreCatalog.isLoading && genreCatalog.genres.isEmpty {
                        HStack {
                            Text("ジャンル")
                            Spacer()
                            ProgressView()
                        }
                    } else {
                        Picker("ジャンル", selection: $settings.selectedGenreCode) {
                            Text("こだわらない").tag(String?.none)
                            ForEach(genreCatalog.genres) { genre in
                                Text(genre.name).tag(String?.some(genre.code))
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                    }
                }

                // こだわり設定（最大5個までという制約が伝わるよう、チップ形式でカウンター付き表示にする）
                Section {
                    ForEach(ParticularCategory.allCases) { category in
                        VStack(alignment: .leading, spacing: 8) {
                            Text(category.rawValue)
                                .font(.caption)
                                .foregroundStyle(.gray)
                            particularChipsGrid(for: category)
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    particularsHeader
                } footer: {
                    Text("こだわりは最大\(DiscoverySettings.maxParticularsCount)個まで選べます。絞り込みすぎず、思いがけない出会いの余地を残しましょう。")
                }
            }
            .overlay(alignment: .top) {
                // ジャンル取得とエリア取得は独立した処理で同時に失敗しうるため、
                // .alertではなくキュー表示できるErrorBannerViewを使う
                ErrorBannerView(errorQueue: errorQueue)
                    .padding(.top, 8)
            }
            .navigationTitle("ディスカバリー設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        applyAndDismiss()
                    } label: {
                        Text("完了")
                            .foregroundColor(.blue)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("キャンセル")
                            .foregroundColor(.blue)
                    }
                }
            }
        }
        .onAppear {
            genreCatalog.loadIfNeeded()
            areaCatalog.loadIfNeeded()
        }
        .onChange(of: genreCatalog.lastError) { _, newValue in
            if let newValue {
                errorQueue.report(newValue)
            }
        }
        .onChange(of: areaCatalog.lastError) { _, newValue in
            if let newValue {
                errorQueue.report(newValue)
            }
        }
    }

    /// 「完了」が押された時の処理。
    /// - `.id(viewID)` + `.onChange(of: viewID)`という間接的な仕組みだけに頼ると、
    ///   `.id()`によるView再構築のタイミングと絡んで`onChange`が確実に発火しないことがあるため、
    ///   ここで`fetchShops`を直接呼び出して再検索を確定させる
    /// - エリア指定モードで都道府県が未選択のまま完了すると、静かに現在地検索へ
    ///   フォールバックしてしまい「都道府県を選んだのに反映されない」ように見えるため、
    ///   その場合は保存せずエラーを表示する
    private func applyAndDismiss() {
        if settings.searchLocationMode == .area && settings.selectedServiceAreaCode == nil {
            errorQueue.report(title: "都道府県を選択してください", message: "エリアを指定する場合は、検索する都道府県を選んでください。")
            return
        }
        viewID = UUID() // カードスタックの表示状態をリセット
        restaurantViewModel.fetchShops(startIndex: 1)
        dismiss()
    }

    /// 「こだわり」セクションの見出し。選択数/上限を常に見えるようにする
    private var particularsHeader: some View {
        HStack {
            Text("こだわり")
                .font(.headline)
                .foregroundColor(.primary)
            Spacer()
            Text("\(settings.selectedParticulars.count) / \(DiscoverySettings.maxParticularsCount)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundStyle(settings.isParticularsLimitReached ? Color.orange : Color.gray)
        }
    }

    /// カテゴリごとのこだわり項目をタグ状に折り返して並べる
    private func particularChipsGrid(for category: ParticularCategory) -> some View {
        let options = ParticularOption.allCases.filter { $0.category == category }
        let columns = [GridItem(.adaptive(minimum: 104), spacing: 8)]
        return LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
            ForEach(options) { option in
                particularChip(option)
            }
        }
    }

    /// 選択中はオレンジで塗りつぶし、上限到達時の未選択項目は薄くしてタップ不可にする
    private func particularChip(_ option: ParticularOption) -> some View {
        let isSelected = settings.selectedParticulars.contains(option)
        let isDisabled = !isSelected && settings.isParticularsLimitReached

        return Button {
            settings.toggleParticular(option)
        } label: {
            HStack(spacing: 4) {
                Image(systemName: option.systemImage)
                    .font(.caption2)
                Text(option.label)
                    .font(.caption)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 7)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color.orange : Color.gray.opacity(0.15))
            .foregroundStyle(isSelected ? Color.white : (isDisabled ? Color.gray.opacity(0.4) : Color.primary))
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .animation(.easeOut(duration: 0.15), value: isSelected)
    }
}
#Preview {
    DiscoverySettingsView(restaurantViewModel: RestaurantViewModel(friendsViewModel: FriendsViewModel()), viewID: .constant(UUID()))
}
