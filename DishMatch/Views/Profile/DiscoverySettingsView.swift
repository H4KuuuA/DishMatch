//
//  DiscoverySettingsView.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/23.
//


import SwiftUI

/// 「今日のお店を探す」シート。
/// 以前は地域・予算に加えてジャンル・こだわりも手動で絞り込んでいたが、それらは「見つける」体験に
/// 寄ってしまうため撤去し、AI（オンデバイス）に任せることにした。ここでユーザーが決めるのは
/// 「制約（地域・予算）」と「今日の気分（プロンプト）」だけ。ジャンル・こだわり・キーワードは
/// いいね履歴と気分からAIが提案する。
struct DiscoverySettingsView: View {
    @Environment(\.dismiss) var dismiss
    // シングルトンインスタンスを @ObservedObject として利用
    @ObservedObject private var settings = DiscoverySettings.shared
    @ObservedObject private var areaCatalog = AreaCatalog.shared
    @StateObject private var errorQueue = ErrorQueue()
    @ObservedObject var restaurantViewModel: RestaurantViewModel
    @Binding var viewID: UUID // ビュー更新用の識別子

    /// 今日の気分・リクエスト（AIへの入力）。任意。
    @State private var moodPrompt: String = ""

    /// 「探す」実行中（AI推論→API取得）。完了までシートに留まりローディングを表示する。
    @State private var isSearching = false

    /// 入力の敷居を下げるためのサジェスト。タップで気分欄に反映する。
    private let moodSuggestions = [
        "安く飲みたい", "デートで静かに", "一人でサッと",
        "がっつり食べたい", "記念日に", "みんなでワイワイ"
    ]

    var body: some View {
        NavigationView {
            Form {
                // 今日の気分（AI対応端末のみ主役として最上部に表示）
                if restaurantViewModel.isRecommendationAvailable {
                    moodSection
                }

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

                    // 選んだ予算「以下」の価格帯もまとめて検索する（初期値オン）
                    Toggle("それ以下の予算も含める", isOn: $settings.includeCheaperBudgets)
                        .disabled(settings.selectedBudget == .noPreference)
                } footer: {
                    Text("オンにすると、選んだ予算以下の価格帯もまとめて検索します（予算未記載のお店も含みます）。")
                }
            }
            .overlay(alignment: .top) {
                // エリア取得が失敗しうるため、.alertではなくキュー表示できるErrorBannerViewを使う
                ErrorBannerView(errorQueue: errorQueue)
                    .padding(.top, 8)
            }
            .overlay {
                // 探す実行中は、AIが推論していることが分かるローディングを重ねる
                if isSearching { searchingOverlay }
            }
            .navigationTitle("今日のお店を探す")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        applyAndSearch()
                    } label: {
                        Text("探す")
                            .fontWeight(.semibold)
                            .foregroundColor(.orange)
                    }
                    .disabled(isSearching)
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Text("キャンセル")
                            .foregroundColor(.gray)
                    }
                }
            }
        }
        .onAppear {
            areaCatalog.loadIfNeeded()
        }
        .onChange(of: areaCatalog.lastError) { _, newValue in
            if let newValue {
                errorQueue.report(newValue)
            }
        }
        .tint(.orange)
    }

    /// 今日の気分入力欄。AIがいいね履歴と合わせて検索条件を提案する。
    private var moodSection: some View {
        Section {
            TextField("どんな気分？（例: デートで静かに飲みたい）", text: $moodPrompt, axis: .vertical)
                .lineLimit(1...3)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(moodSuggestions, id: \.self) { suggestion in
                        Button {
                            moodPrompt = suggestion
                        } label: {
                            Text(suggestion)
                                .font(.caption)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(Color.orange.opacity(0.12))
                                .foregroundStyle(.orange)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 2)
            }
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 0))
        } header: {
            Label("今日の気分", systemImage: "sparkles")
        } footer: {
            Text("入力すると、あなたのいいね傾向と合わせてAIがお店を探します。空欄のままでもOKです。")
        }
    }

    /// 「探す」が押された時の処理。
    /// - エリア指定モードで都道府県が未選択なら、静かに現在地検索へフォールバックして
    ///   「選んだのに反映されない」ように見えるのを避けるため、保存せずエラーを表示する。
    /// - 気分（プロンプト）といいね履歴からAIに検索条件を提案させ、その条件で検索する。
    ///   推論→API取得が終わるまでシートに留まり、AIが考えていることが分かるローディングを見せてから
    ///   シートを閉じてホームへ戻る（結果が揃った状態で戻れるようにする）。
    private func applyAndSearch() {
        if settings.searchLocationMode == .area && settings.selectedServiceAreaCode == nil {
            errorQueue.report(title: "都道府県を選択してください", message: "エリアを指定する場合は、検索する都道府県を選んでください。")
            return
        }
        let trimmed = moodPrompt.trimmingCharacters(in: .whitespacesAndNewlines)
        let promptOrNil = trimmed.isEmpty ? nil : trimmed
        isSearching = true
        Task {
            await restaurantViewModel.applyRecommendation(userPrompt: promptOrNil)
            viewID = UUID() // カードスタックの表示状態をリセット
            isSearching = false
            dismiss()
        }
    }

    /// 探す実行中のローディング表示。AI推論中と検索中で文言を変え、AIが動いていることを伝える。
    private var searchingOverlay: some View {
        ZStack {
            Color(.systemBackground).opacity(0.7).ignoresSafeArea()
            VStack(spacing: 16) {
                ProgressView()
                    .controlSize(.large)
                    .tint(.orange)
                Text(searchingMessage)
                    .font(.subheadline.weight(.medium))
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 8)
            }
            .padding(28)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 20))
        }
    }

    /// ローディングの文言。AI推論中はAIが考えている旨を出す。
    private var searchingMessage: String {
        if restaurantViewModel.isRecommending && restaurantViewModel.isRecommendationAvailable {
            return "✨ AIがあなたの好みからお店を考えています…"
        } else {
            return "お店を探しています…"
        }
    }
}

#Preview {
    DiscoverySettingsView(restaurantViewModel: RestaurantViewModel(friendsViewModel: FriendsViewModel()), viewID: .constant(UUID()))
}
