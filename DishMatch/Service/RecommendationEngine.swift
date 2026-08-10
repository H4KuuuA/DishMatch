//
//  RecommendationEngine.swift
//  DishMatch
//
//  Created by Claude on 2026/08/10.
//

import Foundation
#if canImport(FoundationModels)
import FoundationModels
#endif

/// AIが提案した検索条件（アプリ全体で使うプレーンな型）。
/// FoundationModels由来の型はこのファイル下部の `@available(iOS 26.0, *)` 部分に閉じ込め、
/// 他の層（RestaurantViewModelなど）はこの型だけを扱う。
struct RecommendationCriteria {
    /// HotPepperのジャンルコード（例: "G008"）。nilなら絞り込まない。
    var genreCode: String?
    /// 追加の検索キーワード。nilなら付けない。
    var keyword: String?
    /// 重視する「こだわり」条件。
    var particulars: Set<ParticularOption>
    /// この提案を選んだ理由（UI表示用）。
    var reason: String?
}

/// オンデバイスLLM（Apple Foundation Models, iOS 26+）で、ユーザーの好みと今日の気分から
/// HotPepperの検索条件を提案するエンジン。
///
/// 非対応OS（iOS 26未満）・非対応端末（Apple Intelligence非対応）では `recommend` が nil を返し、
/// 呼び出し元はニュートラルな既定（ジャンル無指定の発見）にフォールバックする。iOS 26普及までは
/// このフォールバック経路が主経路になる想定。
@MainActor
final class RecommendationEngine: ObservableObject {
    #if canImport(FoundationModels)
    /// LanguageModelSession を温存し、2回目以降のウォームアップを避ける。
    /// `@available` の型は格納プロパティに直接持てないため Any? で保持し、利用時にキャストする。
    private var warmSession: Any?
    #endif

    /// この端末でオンデバイス推薦が使えるか。
    var isAvailable: Bool {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            if case .available = SystemLanguageModel.default.availability { return true }
        }
        #endif
        return false
    }

    /// 好みと今日の気分から検索条件を提案する。使えない場合・失敗時は nil を返す。
    /// - Parameters:
    ///   - userPrompt: 今日の気分・リクエスト（最優先）。空・nil なら履歴のみで判断する。
    ///   - likedShops: いいねしたお店（履歴）。
    func recommend(userPrompt: String?, likedShops: [Shop]) async -> RecommendationCriteria? {
        #if canImport(FoundationModels)
        if #available(iOS 26.0, *) {
            return await recommendOnDevice(userPrompt: userPrompt, likedShops: likedShops)
        }
        #endif
        return nil
    }

    // MARK: - プロンプト組み立て（OSバージョン非依存）

    /// モデルへ渡すシステム指示。優先度（今日の気分＞履歴）と、無難さ回避をここで明示する。
    static let instructions = """
    あなたはレストラン発見アプリのアシスタントです。ユーザーの「いいね履歴」と「今日の気分」から、\
    その人に響く検索条件を1つだけ提案します。優先順位は必ず「今日の気分」＞「いいね履歴」です。\
    無難な提案ばかりにせず、ときには意外性のある一皿も提案してください。ジャンルは必ず1つ選びます。
    """

    /// 履歴と今日の気分から入力プロンプト文を組み立てる。
    static func buildPrompt(userPrompt: String?, likedShops: [Shop]) -> String {
        var seen = Set<String>()
        let topGenres = likedShops
            .map { $0.genre.name }
            .filter { seen.insert($0).inserted }
            .prefix(6)
        let history = topGenres.isEmpty ? "まだ履歴なし" : topGenres.joined(separator: "、")
        let mood = userPrompt?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nonEmptyOrNil ?? "特に指定なし"
        return """
        【いいねしたお店のジャンル傾向】\(history)
        【今日の気分・リクエスト】\(mood)
        上記をもとに、今のこの人におすすめの検索条件を提案してください。
        """
    }
}

private extension String {
    /// 空文字なら nil を返す（trim済みの文字列に使う）。
    var nonEmptyOrNil: String? { isEmpty ? nil : self }
}

// MARK: - Foundation Models（iOS 26+）

#if canImport(FoundationModels)
@available(iOS 26.0, *)
extension RecommendationEngine {
    private func recommendOnDevice(userPrompt: String?, likedShops: [Shop]) async -> RecommendationCriteria? {
        guard case .available = SystemLanguageModel.default.availability else { return nil }

        let session: LanguageModelSession
        if let existing = warmSession as? LanguageModelSession {
            session = existing
        } else {
            let created = LanguageModelSession(instructions: Self.instructions)
            warmSession = created
            session = created
        }

        let prompt = Self.buildPrompt(userPrompt: userPrompt, likedShops: likedShops)
        do {
            let response = try await session.respond(to: prompt, generating: AIRecommendation.self)
            let criteria = response.content.toCriteria()
            #if DEBUG
            // 実機のXcodeコンソールで、AIへの入力（いいね傾向を含むプロンプト）と生成物を確認する。
            // 「いいねを見ているか」を検証するため、いいね件数・ジャンル・実プロンプトも出す。
            let likedGenres = likedShops.map { $0.genre.name }
            print("🔮[AIおすすめ] いいね件数=\(likedShops.count) ジャンル=\(likedGenres)")
            print("🔮[AIおすすめ] 入力プロンプト:\n\(prompt)")
            print("🔮[AIおすすめ] 生成: genreCode=\(criteria.genreCode ?? "nil") keyword=\(criteria.keyword ?? "nil") particulars=\(criteria.particulars.map(\.rawValue)) reason=\(criteria.reason ?? "nil")")
            #endif
            return criteria
        } catch {
            print("DEBUG: オンデバイス推薦エラー \(error.localizedDescription)")
            return nil
        }
    }
}

/// モデルに生成させる検索条件。`@Generable` によりこの構造に沿った出力を保証する（ハルシネーション防止）。
@available(iOS 26.0, *)
@Generable
struct AIRecommendation {
    // 列挙型（英語のcase名）だと小型オンデバイスモデルが日本語の意図をうまく対応づけられず、
    // 「コーヒー」で洋食を選ぶ等の誤りが起きた。日本語のジャンル名を .anyOf で選ばせ、後でコードに変換する。
    @Guide(description: "ユーザーの気分に最も合う料理ジャンルを次から1つ選ぶ", .anyOf([
        "居酒屋", "ダイニングバー・バル", "創作料理", "和食", "洋食", "イタリアン・フレンチ",
        "中華", "焼肉・ホルモン", "韓国料理", "アジア・エスニック料理", "各国料理",
        "カラオケ・パーティ", "バー・カクテル", "ラーメン", "お好み焼き・もんじゃ",
        "カフェ・スイーツ", "その他グルメ"
    ]))
    var genre: String

    @Guide(description: "料理名や食材を表す日本語の短い単語。気分やあいまいな語しか無ければ空文字にする。例: ラーメン, 焼肉, パンケーキ, 寿司")
    var keyword: String

    @Guide(description: "重視する店の雰囲気や設備。最大3つまで。無ければ空配列にする。")
    var vibes: [RecommendedVibe]

    @Guide(description: "この提案を選んだ理由を、ユーザーのいいね傾向や今日の気分に触れて1文で述べる")
    var reason: String

    /// アプリ全体で使うプレーンな型へ変換する。
    func toCriteria() -> RecommendationCriteria {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        return RecommendationCriteria(
            genreCode: Self.hotpepperCode(forGenreName: genre),
            keyword: trimmedKeyword.isEmpty ? nil : trimmedKeyword,
            // 出会いの幅を残すためこだわりは最大3つに丸める
            particulars: Set(vibes.prefix(3).map { $0.particular }),
            reason: trimmedReason.isEmpty ? nil : trimmedReason
        )
    }

    /// 日本語のジャンル名 → HotPepperジャンルコード（get_genre実測に一致）。
    static func hotpepperCode(forGenreName name: String) -> String? {
        switch name {
        case "居酒屋": return "G001"
        case "ダイニングバー・バル": return "G002"
        case "創作料理": return "G003"
        case "和食": return "G004"
        case "洋食": return "G005"
        case "イタリアン・フレンチ": return "G006"
        case "中華": return "G007"
        case "焼肉・ホルモン": return "G008"
        case "韓国料理": return "G017"
        case "アジア・エスニック料理": return "G009"
        case "各国料理": return "G010"
        case "カラオケ・パーティ": return "G011"
        case "バー・カクテル": return "G012"
        case "ラーメン": return "G013"
        case "お好み焼き・もんじゃ": return "G016"
        case "カフェ・スイーツ": return "G014"
        case "その他グルメ": return "G015"
        default: return nil
        }
    }
}

/// 気分から選ばせる「こだわり」条件のサブセット（シチュエーションに効くものだけ）。
@available(iOS 26.0, *)
@Generable
enum RecommendedVibe {
    case privateRoom, allYouCanDrink, course, nightView, openAir, charter
    case childFriendly, tatami, lateNight, karaoke, nonSmoking, lunch

    /// アプリ内の `ParticularOption` へ対応づける。
    var particular: ParticularOption {
        switch self {
        case .privateRoom: return .privateRoom
        case .allYouCanDrink: return .freeDrink
        case .course: return .course
        case .nightView: return .nightView
        case .openAir: return .openAir
        case .charter: return .charter
        case .childFriendly: return .child
        case .tatami: return .tatami
        case .lateNight: return .midnight
        case .karaoke: return .karaoke
        case .nonSmoking: return .nonSmoking
        case .lunch: return .lunch
        }
    }
}
#endif
