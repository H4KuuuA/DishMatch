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
    その場面に合う"こだわり"を重要な順に最大3つ入れる。**先頭には個室のように幅広い店にある条件を置く**\
    （夜景など珍しい条件は先頭にしない）。keyword は空文字。
    ・vibes は重要な順に並べる。無ければ空配列。
    ・紛らわしい語に注意: 「焼きそば」は"お好み焼き・もんじゃ"であり焼肉ではない。「そば/うどん」は和食。\
    「パスタ/ピザ」はイタリアン。「ハンバーガー」は洋食。「〜以外」「〜は苦手」など否定は無視する。
    例:
    ・「コーヒー飲みたい」→ themeKind=料理 / primary=カフェ・スイーツ / breadth=specific / keyword=コーヒー
    ・「焼きそば」→ themeKind=料理 / primary=お好み焼き・もんじゃ / breadth=specific / keyword=焼きそば
    ・「がっつり食べたい」→ themeKind=料理 / primary=焼肉・ホルモン / breadth=broad / secondary=居酒屋,ラーメン
    ・「軽く一杯」→ themeKind=料理 / primary=居酒屋 / breadth=broad / secondary=ダイニングバー・バル,バー・カクテル
    ・「デート」→ themeKind=シチュエーション / vibes=個室,コース / keyword=空
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

        // いいね履歴のジャンルを**頻度順**で並べる（よくLikeするジャンルほど前に）。
        var counts: [String: Int] = [:]
        var firstIndex: [String: Int] = [:]
        for (index, shop) in likedShops.enumerated() {
            let name = shop.genre.name
            counts[name, default: 0] += 1
            if firstIndex[name] == nil { firstIndex[name] = index }
        }
        let topGenres = counts.keys
            .sorted { a, b in
                if counts[a]! != counts[b]! { return counts[a]! > counts[b]! }      // 多い順
                return firstIndex[a]! < firstIndex[b]!                                // 同数は先に出た順
            }
            .prefix(6)
        let history = topGenres.isEmpty ? "まだ履歴なし" : topGenres.joined(separator: "、")
        return """
        【いいねしたお店のジャンル傾向（よくLikeする順）】\(history)
        今日の気分は特に指定がないので、いいね履歴の傾向から、この人に響く検索条件を提案してください。
        """
    }

    /// モデルが出した keyword を掃除する。気分語・シチュエーション語・否定を含む文は料理keywordとして使わない。
    static func cleanedKeyword(_ raw: String?) -> String? {
        guard let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty else { return nil }
        // シチュエーション語や明示こだわり語が keyword に紛れていたら料理語ではないので落とす。
        if situationParticulars(for: trimmed) != nil { return nil }
        if !explicitParticulars(for: trimmed).isEmpty { return nil }
        // 気分・曖昧語のストップリスト。
        let stopWords = ["なんでも", "おすすめ", "美味しい", "おいしい", "適当", "普通", "食事", "ごはん", "ご飯", "ランチ", "ディナー"]
        if stopWords.contains(where: { trimmed.contains($0) }) { return nil }
        // 長すぎる（文章）のは料理語ではない。
        if trimmed.count > 12 { return nil }
        return trimmed
    }

    // MARK: - 決定的な入力解釈（モデル非依存・正規化＋否定検出つき）

    /// プロンプトから決定的に読み取れるシグナル（オンデバイスモデルに依存しないので実機以外でも検証可）。
    struct PromptSignals {
        /// 料理語から確定したジャンルコード。無ければ nil。
        var dishGenreCode: String?
        /// シチュエーション語から得た既定こだわり（優先度順）。非nil＝シチュエーション検出（空配列＝絞りなし全ジャンル）。
        var situationParticulars: [ParticularOption]?
        /// プロンプトに明示されたこだわり（個室/夜景/時間帯 等）。優先度順。
        var explicitParticulars: [ParticularOption]
        /// 否定表現（〜以外/苦手 等）を含むか（ログ・保守的判断用）。
        var hasNegation: Bool
    }

    /// 表記ゆれを吸収する正規化: 小文字化・全半角統一・カタカナ→ひらがな。
    static func normalize(_ text: String) -> String {
        let folded = text.folding(options: [.caseInsensitive, .widthInsensitive], locale: Locale(identifier: "ja_JP"))
        return folded.applyingTransform(.hiraganaToKatakana, reverse: true) ?? folded
    }

    /// 否定・除外の目印。マッチ語の直後にこれらが来たら「その語は否定されている」とみなす。
    private static let negationMarkers = ["以外", "抜き", "なし", "いらない", "いらん", "苦手", "じゃない", "ではない", "じゃなく", "ではなく", "飲めない", "食べられない", "避け", "ng"]

    /// 正規化済みテキストで、マッチ末尾の直後に否定語が来るか（近傍10文字）を見る。
    private static func isNegated(afterMatchEnd end: String.Index, in text: String) -> Bool {
        let windowEnd = text.index(end, offsetBy: 10, limitedBy: text.endIndex) ?? text.endIndex
        let window = String(text[end..<windowEnd])
        return negationMarkers.contains { window.contains(normalize($0)) }
    }

    /// いずれかの語が「否定されずに」出現するか。表記ゆれ正規化＋否定検出つき。
    static func mentions(_ words: [String], in rawText: String) -> Bool {
        let hay = normalize(rawText)
        for word in words {
            let needle = normalize(word)
            guard !needle.isEmpty else { continue }
            var start = hay.startIndex
            while let range = hay.range(of: needle, range: start..<hay.endIndex) {
                if !isNegated(afterMatchEnd: range.upperBound, in: hay) { return true }
                start = range.upperBound
            }
        }
        return false
    }

    /// プロンプトを決定的に解釈して、料理ジャンル・シチュエーション・明示こだわりをまとめて返す。
    static func interpret(_ userPrompt: String?) -> PromptSignals {
        guard let text = userPrompt?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty else {
            return PromptSignals(dishGenreCode: nil, situationParticulars: nil, explicitParticulars: [], hasNegation: false)
        }
        let normalized = normalize(text)
        let hasNegation = negationMarkers.contains { normalized.contains(normalize($0)) }
        return PromptSignals(
            dishGenreCode: dishGenreCode(for: text),
            situationParticulars: situationParticulars(for: text),
            explicitParticulars: explicitParticulars(for: text),
            hasNegation: hasNegation
        )
    }

    /// プロンプトが既知の「シチュエーション語」を含むなら、その場面向けの既定こだわり（優先度順）を返す。無ければ nil。
    static func situationParticulars(for userPrompt: String?) -> [ParticularOption]? {
        guard let text = userPrompt, !text.isEmpty else { return nil }
        func has(_ words: [String]) -> Bool { mentions(words, in: text) }

        // 先頭＝ハード絞り込みに使う最重要こだわり。広く使える「個室」等を先頭に置く。残りは並び順で効く。
        if has(["デート", "date"]) { return [.privateRoom, .course] }
        if has(["記念日", "誕生日", "お祝い", "アニバーサリー", "anniversary"]) { return [.privateRoom, .course] }
        if has(["接待", "会食", "商談", "打ち合わせ", "打合せ"]) { return [.privateRoom, .course, .tatami] }
        if has(["女子会"]) { return [.privateRoom, .freeDrink] }
        if has(["合コン", "飲み会", "宴会", "二次会", "送別会", "歓迎会", "歓送迎会", "打ち上げ", "懇親会", "オフ会"]) { return [.privateRoom, .freeDrink, .course] }
        if has(["子連れ", "子供", "こども", "家族", "ファミリー"]) { return [.child, .tatami] }
        if has(["一人", "ひとり", "おひとりさま", "ソロ"]) { return [] } // 全ジャンル・絞りなしで気ままに
        return nil
    }

    /// プロンプトが既知の「料理語」を含むなら、その料理に対応するHotPepperジャンルコードを返す。無ければ nil。
    /// 「焼きそば」を粉ものとして先に判定するなど、紛らわしい語は並び順に注意している。
    static func dishGenreCode(for userPrompt: String?) -> String? {
        guard let text = userPrompt, !text.isEmpty else { return nil }
        func has(_ words: [String]) -> Bool { mentions(words, in: text) }

        // 粉もの（お好み焼き・もんじゃ G016）※「焼きそば」を「焼肉」より先に確実に拾う
        if has(["焼きそば", "焼そば", "やきそば", "お好み焼き", "おこのみやき", "もんじゃ", "たこ焼き", "たこやき"]) { return "G016" }
        // ラーメン G013（チェーン含む）
        if has(["ラーメン", "らーめん", "拉麺", "つけ麺", "油そば", "家系", "二郎", "一蘭", "一風堂", "天下一品"]) { return "G013" }
        // 焼肉・ホルモン G008
        if has(["焼肉", "焼き肉", "やきにく", "ホルモン", "カルビ", "ジンギスカン"]) { return "G008" }
        // 韓国料理 G017
        if has(["韓国", "サムギョプサル", "チヂミ", "キンパ", "ビビンバ", "スンドゥブ", "トッポギ"]) { return "G017" }
        // 中華 G007
        if has(["中華", "餃子", "ぎょうざ", "麻婆", "点心", "小籠包", "町中華", "四川", "台湾料理"]) { return "G007" }
        // イタリアン・フレンチ G006（チェーン含む）
        if has(["ピザ", "ピッツァ", "パスタ", "イタリアン", "リゾット", "フレンチ", "サイゼ", "サイゼリヤ"]) { return "G006" }
        // 洋食・ファストフード G005（チェーン含む）
        if has(["ハンバーグ", "オムライス", "ステーキ", "洋食", "グラタン", "ハンバーガー", "マック", "マクドナルド", "モスバーガー", "ケンタッキー", "kfc", "ガスト", "ジョナサン"]) { return "G005" }
        // カフェ・スイーツ G014（チェーン・作業/勉強も含む）
        if has(["コーヒー", "珈琲", "カフェ", "パンケーキ", "ケーキ", "パフェ", "スイーツ", "甘味", "抹茶", "タピオカ", "スタバ", "スターバックス", "ドトール", "コメダ", "タリーズ", "ミスド", "作業", "勉強", "ノマド", "リモートワーク"]) { return "G014" }
        // 焼き鳥・串（居酒屋 G001）
        if has(["焼き鳥", "焼鳥", "やきとり", "串カツ", "串揚げ", "もつ煮", "もつ鍋"]) { return "G001" }
        // アジア・エスニック G009
        if has(["タイ料理", "ベトナム", "エスニック", "インドカレー", "ガパオ", "フォー", "ナン", "スパイスカレー"]) { return "G009" }
        // 居酒屋 G001（お酒・飲み系の語）※バー系より広く受けたいので先に
        if has(["居酒屋", "ビール", "生ビール", "ビアガーデン", "日本酒", "地酒", "焼酎", "ハイボール", "サワー", "酎ハイ", "レモンサワー", "飲み"]) { return "G001" }
        // バー・カクテル G012
        if has(["カクテル", "ウイスキー", "ワインバー", "ワイン", "バル"]) { return "G012" }
        // 寿司・海鮮（和食 G004）
        if has(["寿司", "鮨", "寿し", "刺身", "海鮮", "スシロー", "くら寿司", "回転寿司"]) { return "G004" }
        // 和食 G004 ※「焼きそば/つけ麺」等は上で処理済み。「そば」は"近く"の意味と紛れるので漢字/専門語のみ拾う
        if has(["蕎麦", "そば屋", "天ぷら", "てんぷら", "うなぎ", "鰻", "うどん", "丸亀", "和食", "懐石", "割烹", "牛丼", "吉野家", "すき家", "松屋"]) { return "G004" }
        return nil
    }

    /// プロンプトに**明示的に書かれたこだわり語**（個室・夜景・時間帯 等）を優先度順で拾う。否定語は除外。
    static func explicitParticulars(for userPrompt: String?) -> [ParticularOption] {
        guard let text = userPrompt, !text.isEmpty else { return [] }
        var result: [ParticularOption] = []
        func add(_ option: ParticularOption, _ words: [String]) {
            guard !result.contains(option) else { return }
            if mentions(words, in: text) { result.append(option) }
        }
        add(.privateRoom, ["個室"])
        add(.nightView, ["夜景"])
        add(.freeDrink, ["飲み放題", "のみ放題", "飲みほうだい"])
        add(.freeFood, ["食べ放題", "たべ放題", "食べほうだい"])
        add(.course, ["コース"])
        add(.tatami, ["座敷"])
        add(.horigotatsu, ["掘りごたつ", "掘り炬燵", "ほりごたつ"])
        add(.charter, ["貸切", "貸し切り"])
        add(.openAir, ["テラス", "屋外", "オープンエア", "オープンテラス"])
        add(.wifi, ["電源", "コンセント", "wi-fi", "wifi", "ワイファイ", "作業", "勉強", "ノマド"])
        add(.parking, ["駐車場", "車で", "パーキング"])
        add(.pet, ["ペット", "犬連れ", "ドッグ"])
        add(.nonSmoking, ["禁煙"])
        add(.lunch, ["ランチ", "昼ごはん", "昼飯", "ひるめし"])
        add(.midnight, ["深夜", "朝まで", "夜通し", "夜遅く"])
        add(.child, ["子連れ", "子供", "こども"])
        return result
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
            var criteria = response.content.toCriteria()
            // keyword衛生: 気分語・シチュエーション語が紛れていたら料理keywordとして使わない。
            criteria.keyword = Self.cleanedKeyword(criteria.keyword)

            // 決定的ガード: プロンプトから「料理語→ジャンル」「シチュエーション語→既定こだわり」
            // 「明示のこだわり語」を拾い、料理とこだわりを両立させて上書きする（正規化＋否定検出つき）。
            // 料理とシチュエーションが混在（例「個室でデートで焼きそば」）しても、
            // 料理（焼きそば＝G016）を活かしつつ、明示/場面のこだわり（個室）を重ねる。
            let signals = Self.interpret(userPrompt)
            let dishCode = signals.dishGenreCode
            let situationParts = signals.situationParticulars
            let explicitParticulars = signals.explicitParticulars

            // こだわりは「明示的に書かれた語」を最優先、無ければシチュエーション既定を使う。
            let resolvedParticulars = !explicitParticulars.isEmpty ? explicitParticulars : (situationParts ?? [])

            var overrodeSituation = false
            var overrodeDish = false
            if let dishCode {
                // 料理語あり: ジャンルは辞書で確定（モデルの誤分類を上書き）。こだわりがあれば重ねる。
                overrodeDish = true
                overrodeSituation = !resolvedParticulars.isEmpty
                // keyword は並び順で効くので、モデルのkeywordが空ならプロンプトを流用する。
                let orderingKeyword = (criteria.keyword?.isEmpty == false) ? criteria.keyword : userPrompt?.trimmingCharacters(in: .whitespacesAndNewlines)
                criteria = RecommendationCriteria(genreCodes: [dishCode], isBroad: false, keyword: orderingKeyword, particulars: resolvedParticulars, reason: criteria.reason)
            } else if situationParts != nil {
                // 料理指定なしのシチュエーション: ジャンルで絞らず、こだわりで出す。
                overrodeSituation = true
                if let keyword = criteria.keyword, !keyword.isEmpty {
                    // モデルが料理を拾っている場合は、そのジャンルを残しつつこだわりを重ねる。
                    criteria = RecommendationCriteria(genreCodes: criteria.genreCodes, isBroad: criteria.isBroad, keyword: keyword, particulars: resolvedParticulars, reason: criteria.reason)
                } else {
                    criteria = RecommendationCriteria(genreCodes: [], isBroad: false, keyword: nil, particulars: resolvedParticulars, reason: criteria.reason)
                }
            } else if !explicitParticulars.isEmpty {
                // 料理もシチュエーションも無いが、明示のこだわり（例「個室で」）がある: モデルのジャンルに重ねる。
                criteria = RecommendationCriteria(genreCodes: criteria.genreCodes, isBroad: criteria.isBroad, keyword: criteria.keyword, particulars: explicitParticulars, reason: criteria.reason)
            }

            #if DEBUG
            // 実機のXcodeコンソールで、AIへの入力（いいね傾向を含むプロンプト）と生成物を確認する。
            let likedGenres = likedShops.map { $0.genre.name }
            print("🔮[AIおすすめ] いいね件数=\(likedShops.count) ジャンル=\(likedGenres)")
            print("🔮[AIおすすめ] 入力プロンプト:\n\(prompt)")
            print("🔮[AIおすすめ] モデル生成: themeKind=\(response.content.themeKind) primary=\(response.content.primaryGenre) breadth=\(response.content.breadth) keyword=\(response.content.keyword) vibes=\(response.content.vibes)")
            print("🔮[AIおすすめ] 決定的解釈: dish=\(signals.dishGenreCode ?? "nil") situation=\(signals.situationParticulars?.map(\.rawValue) ?? []) explicit=\(signals.explicitParticulars.map(\.rawValue)) 否定=\(signals.hasNegation)")
            print("🔮[AIおすすめ] 採用条件(状況上書き=\(overrodeSituation) 料理上書き=\(overrodeDish)): genreCodes=\(criteria.genreCodes) broad=\(criteria.isBroad) keyword=\(criteria.keyword ?? "nil") particulars=\(criteria.particulars.map(\.rawValue)) reason=\(criteria.reason ?? "nil")")
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
