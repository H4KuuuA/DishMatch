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
    /// HotPepperのジャンルコード集合（primaryが先頭・重複排除・最大3件）。
    /// これが「意図の硬い境界線」で、検索時にこの外へは絶対に広げない。
    /// **空ならジャンルで絞らない**（デート等のシチュエーションテーマ＝こだわりで全ジャンル横断的に出す）。
    var genreCodes: [String]
    /// テーマが広いか（broad）。broadのときだけ複数ジャンルを加重マージする。
    /// specific（コーヒー等の具体テーマ）は先頭1ジャンルに閉じる。
    var isBroad: Bool
    /// 追加の検索キーワード。nilなら付けない。並び順専用（絞り込みには使わない）。
    var keyword: String?
    /// 重視する「こだわり」条件を**優先度の高い順**に並べたもの。
    /// シチュエーションテーマではこれが主役（件数が減ったら末尾から1つずつ緩める）。
    var particulars: [ParticularOption]
    /// この提案を選んだ理由（UI表示用）。
    var reason: String?
}

/// オンデバイスLLM（Apple Foundation Models, iOS 26+）で、ユーザーの好みと今日の気分から
/// HotPepperの検索条件を提案するエンジン。
///
/// 非対応OS（iOS 26未満）・非対応端末（Apple Intelligence非対応）では `recommend` が nil を返し、
/// 呼び出し元はニュートラルな既定（ジャンル無指定の発見）にフォールバックする。
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

    /// モデルへ渡すシステム指示。テーマ種別・優先度・具体度(breadth)の判定基準をここで明示する。
    static let instructions = """
    あなたはレストラン発見アプリのアシスタントです。ユーザーの入力から検索条件を提案します。
    まず themeKind を判定します:
    ・"料理" … コーヒー・焼肉・寿司・がっつり など"食べたい料理や味"が主眼。
    ・"シチュエーション" … デート・記念日・女子会・接待・一人でゆっくり・子連れ など"場面や雰囲気"が主眼で、\
    特定の料理を指していない。
    ルール:
    ・「今日の気分」が入力されている時は、"今日の気分だけ"で決める。いいね履歴には引っ張られない。空の時だけ履歴を使う。
    ・themeKind が "料理" の時: primaryGenre を必ず1つ選ぶ。breadth は、コーヒー・パンケーキ・寿司など\
    "特定の料理"なら "specific"、「がっつり」「軽く飲みたい」など"漠然"なら "broad"。broad の時だけ \
    secondaryGenre を最大2つ足す（specificは「なし」）。keyword は具体的な料理・食材の短い日本語だけ（無ければ空文字）。
    ・themeKind が "シチュエーション" の時: **ジャンルでは絞らない**。primaryGenre は適当でよく、代わりに vibes に\
    その場面に合う"こだわり"を重要な順に最大3つ入れる（例 デート=個室,夜景,コース）。keyword は空文字。
    ・vibes は重要な順に並べる。無ければ空配列。
    例:
    ・「コーヒー飲みたい」→ themeKind=料理 / primary=カフェ・スイーツ / breadth=specific / keyword=コーヒー
    ・「がっつり食べたい」→ themeKind=料理 / primary=焼肉・ホルモン / breadth=broad / secondary=居酒屋,ラーメン
    ・「デート」→ themeKind=シチュエーション / vibes=個室,夜景,コース / keyword=空
    ・「女子会」→ themeKind=シチュエーション / vibes=個室,飲み放題
    ・「接待」→ themeKind=シチュエーション / vibes=個室,コース,座敷
    """

    /// 入力プロンプト文を組み立てる。
    /// **プロンプト最優先**: 今日の気分が入力されている時は、いいね履歴は渡さない（小型モデルが履歴に
    /// 引っ張られてジャンルを誤るのを防ぐ）。気分が空の時だけ履歴を渡して、そこからジャンルを決めさせる。
    static func buildPrompt(userPrompt: String?, likedShops: [Shop]) -> String {
        let mood = userPrompt?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .nonEmptyOrNil

        if let mood {
            return """
            【今日の気分・リクエスト】\(mood)
            今日の気分だけを最優先に、この人に響く検索条件を提案してください。いいね履歴は考慮しなくて構いません。
            """
        }

        var seen = Set<String>()
        let topGenres = likedShops
            .map { $0.genre.name }
            .filter { seen.insert($0).inserted }
            .prefix(6)
        let history = topGenres.isEmpty ? "まだ履歴なし" : topGenres.joined(separator: "、")
        return """
        【いいねしたお店のジャンル傾向】\(history)
        今日の気分は特に指定がないので、いいね履歴の傾向から、この人に響く検索条件を提案してください。
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
            let likedGenres = likedShops.map { $0.genre.name }
            print("🔮[AIおすすめ] いいね件数=\(likedShops.count) ジャンル=\(likedGenres)")
            print("🔮[AIおすすめ] 入力プロンプト:\n\(prompt)")
            print("🔮[AIおすすめ] 生成: genreCodes=\(criteria.genreCodes) broad=\(criteria.isBroad) keyword=\(criteria.keyword ?? "nil") particulars=\(criteria.particulars.map(\.rawValue)) reason=\(criteria.reason ?? "nil")")
            #endif
            return criteria
        } catch {
            print("DEBUG: オンデバイス推薦エラー \(error.localizedDescription)")
            return nil
        }
    }
}

/// モデルに生成させる検索条件。`@Generable` によりこの構造に沿った出力を保証する（ハルシネーション防止）。
/// 小型オンデバイスモデルでも精度が出るよう、判断を小さな離散選択に分解している
/// （主ジャンル1つ＋具体度＋（広い時だけ）追加ジャンル）。
@available(iOS 26.0, *)
@Generable
struct AIRecommendation {
    @Guide(description: "リクエストが料理主眼なら「料理」、デート・記念日・女子会など場面主眼なら「シチュエーション」", .anyOf(["料理", "シチュエーション"]))
    var themeKind: String

    // 列挙型（英語のcase名）だと小型モデルが日本語の意図をうまく対応づけられないため、
    // 日本語のジャンル名を .anyOf で選ばせ、後でコードに変換する。
    @Guide(description: "themeKindが料理のとき、気分に最も合う主役の料理ジャンルを1つ選ぶ", .anyOf(Self.genreNames))
    var primaryGenre: String

    @Guide(description: "リクエストの具体度。特定の料理や飲み物名なら specific、漠然とした気分なら broad", .anyOf(["specific", "broad"]))
    var breadth: String

    @Guide(description: "broadのとき primary と雰囲気の近い追加ジャンル1。specificなら「なし」", .anyOf(Self.genreNamesWithNone))
    var secondaryGenre1: String

    @Guide(description: "broadのとき primary と雰囲気の近い追加ジャンル2。specificや不要なら「なし」", .anyOf(Self.genreNamesWithNone))
    var secondaryGenre2: String

    @Guide(description: "料理名や食材を表す日本語の短い単語。気分やあいまいな語しか無ければ空文字にする。例: コーヒー, 焼肉, パンケーキ")
    var keyword: String

    @Guide(description: "重視する店の雰囲気や設備を重要な順に。最大3つ。無ければ空配列。シチュエーションではここが主役（例 デート=個室,夜景,コース）。")
    var vibes: [RecommendedVibe]

    @Guide(description: "この提案を選んだ理由を、今日の気分やいいね傾向に触れて1文で述べる")
    var reason: String

    /// 選ばせるジャンル名（HotPepperのジャンルマスタに一致）。
    static let genreNames = [
        "居酒屋", "ダイニングバー・バル", "創作料理", "和食", "洋食", "イタリアン・フレンチ",
        "中華", "焼肉・ホルモン", "韓国料理", "アジア・エスニック料理", "各国料理",
        "カラオケ・パーティ", "バー・カクテル", "ラーメン", "お好み焼き・もんじゃ",
        "カフェ・スイーツ", "その他グルメ"
    ]
    /// secondary用（「なし」を選べる）。
    static let genreNamesWithNone = ["なし"] + genreNames

    /// アプリ全体で使うプレーンな型へ変換する。
    func toCriteria() -> RecommendationCriteria {
        let trimmedKeyword = keyword.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasKeyword = !trimmedKeyword.isEmpty
        // 具体語(keyword)があれば「料理」テーマに寄せる二重ガード。
        let isFoodTheme = (themeKind == "料理") || hasKeyword
        let trimmedReason = reason.trimmingCharacters(in: .whitespacesAndNewlines)
        let reasonOrNil = trimmedReason.isEmpty ? nil : trimmedReason

        if !isFoodTheme {
            // シチュエーション: ジャンルでは絞らず（genreCodes空＝全ジャンル）、こだわりで出す。
            return RecommendationCriteria(
                genreCodes: [],
                isBroad: false,
                keyword: nil,
                particulars: Self.orderedParticulars(from: vibes, limit: 3),
                reason: reasonOrNil
            )
        }

        // 具体語(keyword)があれば specific に寄せる二重ガード。狭いテーマが誤って複数ジャンルに広がるのを防ぐ。
        let broad = (breadth == "broad") && !hasKeyword
        var codes: [String] = []
        if let primary = Self.hotpepperCode(forGenreName: primaryGenre) {
            codes.append(primary)
        }
        if broad {
            for name in [secondaryGenre1, secondaryGenre2] {
                if let code = Self.hotpepperCode(forGenreName: name), !codes.contains(code) {
                    codes.append(code)
                }
            }
        }
        codes = Array(codes.prefix(3))

        return RecommendationCriteria(
            genreCodes: codes,
            isBroad: broad && codes.count > 1,
            keyword: hasKeyword ? trimmedKeyword : nil,
            // 料理テーマではこだわりは補助的。最大2つに丸める。
            particulars: Self.orderedParticulars(from: vibes, limit: 2),
            reason: reasonOrNil
        )
    }

    /// vibes を ParticularOption の配列へ（優先順を保ち重複排除、上限つき）。
    static func orderedParticulars(from vibes: [RecommendedVibe], limit: Int) -> [ParticularOption] {
        var seen = Set<ParticularOption>()
        var result: [ParticularOption] = []
        for vibe in vibes {
            let option = vibe.particular
            if seen.insert(option).inserted {
                result.append(option)
                if result.count >= limit { break }
            }
        }
        return result
    }

    /// 日本語のジャンル名 → HotPepperジャンルコード（get_genre実測に一致）。「なし」やその他は nil。
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

/// 気分・シチュエーションから選ばせる「こだわり」条件のサブセット（場面に効くものだけ）。
@available(iOS 26.0, *)
@Generable
enum RecommendedVibe {
    case privateRoom, nightView, course, allYouCanDrink, charter, tatami, childFriendly, nonSmoking, lunch

    /// アプリ内の `ParticularOption` へ対応づける。
    var particular: ParticularOption {
        switch self {
        case .privateRoom: return .privateRoom
        case .nightView: return .nightView
        case .course: return .course
        case .allYouCanDrink: return .freeDrink
        case .charter: return .charter
        case .tatami: return .tatami
        case .childFriendly: return .child
        case .nonSmoking: return .nonSmoking
        case .lunch: return .lunch
        }
    }
}
#endif
