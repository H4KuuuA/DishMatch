//
//  RecommendationEvalView.swift
//  DishMatch
//
//  Created by Claude on 2026/08/10.
//

#if DEBUG
import SwiftUI

/// AIおすすめ精度の回帰チェック用（DEBUG専用）評価画面。
///
/// - 「決定的解釈」（`RecommendationEngine.interpret`）は純粋な文字列処理なので**シミュレータでも検証可能**。
///   代表プロンプト集の dish/situation/明示こだわり/否定 を一覧でき、辞書や否定検出の回帰を目視できる。
/// - 「モデル実行」はオンデバイスLLMを使うため**実機（iOS26/Apple Intelligence）でのみ**動く。
struct RecommendationEvalView: View {
    @StateObject private var engine = RecommendationEngine()
    @State private var runningModel = false
    @State private var modelResults: [String: String] = [:]

    /// 代表的なテストプロンプト（誤爆・否定・混在・チェーン・作業などの観点を含む）。
    private let prompts = [
        "コーヒー飲みたい", "焼きそば", "パスタ", "スタバ", "ビール飲みたい",
        "焼肉以外がいい", "コーヒーは苦手", "駅のそばのお店",
        "デート", "記念日に", "個室でデートで焼きそば食べたい",
        "女子会", "接待", "一人でゆっくり", "子連れでランチ",
        "がっつり食べたい", "軽く一杯", "作業できるところ", "テラスでランチ", "深夜まで飲みたい"
    ]

    var body: some View {
        List {
            Section("決定的解釈（シミュレータでも検証可）") {
                ForEach(prompts, id: \.self) { prompt in
                    row(for: prompt)
                }
            }
        }
        .navigationTitle("推薦の評価")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(runningModel ? "実行中…" : "モデル実行") {
                    Task { await runModel() }
                }
                .disabled(runningModel || !engine.isAvailable)
            }
        }
    }

    @ViewBuilder
    private func row(for prompt: String) -> some View {
        let signals = RecommendationEngine.interpret(prompt)
        VStack(alignment: .leading, spacing: 3) {
            Text(prompt).font(.subheadline.weight(.semibold))
            Text("dish=\(signals.dishGenreCode ?? "-")  状況=\(listText(signals.situationParticulars))  明示=\(listText(signals.explicitParticulars))  否定=\(signals.hasNegation ? "有" : "無")")
                .font(.caption)
                .foregroundStyle(.secondary)
            if let model = modelResults[prompt] {
                Text("model: \(model)")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .padding(.vertical, 2)
    }

    private func listText(_ options: [ParticularOption]?) -> String {
        guard let options else { return "-" }
        return options.isEmpty ? "(なし)" : options.map(\.rawValue).joined(separator: ",")
    }

    private func runModel() async {
        runningModel = true
        for prompt in prompts {
            if let criteria = await engine.recommend(userPrompt: prompt, likedShops: []) {
                modelResults[prompt] = "genre=\(criteria.genreCodes) part=\(criteria.particulars.map(\.rawValue)) kw=\(criteria.keyword ?? "-")"
            } else {
                modelResults[prompt] = "nil（この端末では利用不可）"
            }
        }
        runningModel = false
    }
}

#Preview {
    NavigationStack { RecommendationEvalView() }
}
#endif
