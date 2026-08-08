# DishMatch

> 「行きたいお店を**探す**」のではなく、「思いがけないお店と**出会う**」ためのグルメ発見アプリ。

DishMatch は、Tinder ライクなスワイプ UI で近くの飲食店と直感的に出会い、気に入ったお店を友達と共有できる iOS アプリです。従来の検索型グルメアプリと異なり、まだ知らなかった魅力的なお店との「出会い」を軸に設計しています。

---

## コンセプト

- **探すのではなく出会う** — 条件に合うお店を並べて選ぶのではなく、次々に提示されるお店をスワイプで直感的に判断する体験。
- **出会いを共有する** — 気に入ったお店を友達と共有し、同じジャンルを好きになった時に「マッチ」で教え合う。離れていても外食・旅行の店選びをスムーズにする。

---

## 主な機能

### 🍽 お店発見（Discover）
- Tinder ライクなカード UI とスワイプ操作でお店を選択（Like / None、取り消し可）。
- サムネイル（店名・ジャンル・アクセス・画像）と、詳細（住所・最寄り駅・営業時間・定休日・予算・リンク）の 2 段階表示。
- 検索範囲（300m〜3,000m）・予算・ジャンル・エリアでの絞り込み。
- API のページング対応。残りが少なくなると次ページを自動取得し、途切れずに探し続けられる。

### ❤️ お気に入り（Likes）
- Like したお店の一覧を、店名・ジャンル・最寄り駅で検索。
- お気に入りから自動生成されるジャンルタブで、文字入力なしでも絞り込み可能。
- 検索画面で入力した文字を一覧画面に反映し、「何を検索したか」を分かりやすく表示。

### 👥 友達・ソーシャル（Friends）
- **LINE 式の双方向友達登録** — 友達コード（または QR コード）で申請し、相手の承認で友達成立。
- **公開プロフィール** — ニックネーム・アイコン・好きなジャンルを友達に公開。
- **マッチ通知** — 友達と同じジャンルのお店を Like した時にマッチとして知らせる。
- **1 対 1 チャット（DM）** — 友達とメッセージやお店を共有。

### 👤 プロフィール（Profile）
- 新規登録時にユーザー名とアイコンを設定（公開プロフィールに反映され、友達一覧に表示）。
- ニックネーム・自己紹介・アイコンの編集。
- ダークモード対応（システム / ライト / ダーク）。

### 🔐 認証・データ同期
- Firebase Authentication（メール / パスワード）によるサインアップ・ログイン・パスワード再設定。
- Firestore によるプロフィール・友達・申請・チャットのリアルタイム同期。

---

## 画面構成（タブ）

| タブ | 内容 |
| --- | --- |
| 発見（Discover） | スワイプでお店と出会う。ディスカバリー設定で範囲・予算などを調整 |
| お気に入り（Likes） | Like したお店の一覧・検索・ジャンルタブ |
| 友達（Friends） | 友達一覧・申請の承認 / 拒否・友達追加・チャット |
| プロフィール（Profile） | 登録情報の編集・アプリ設定 |

---

## 技術スタック

- **言語 / UI**: Swift, SwiftUI
- **認証**: Firebase Authentication（メール / パスワード）
- **データベース**: Cloud Firestore（リアルタイム同期・セキュリティルール）
- **画像読み込み**: Kingfisher
- **外部 API**: ホットペッパーグルメサーチ API / Google Places API
- **位置情報**: Core Location

---

## アーキテクチャ

MVVM を基本に、責務ごとに View / Model(ViewModel) / Service を分離しています。

```
DishMatch/
├── Model/          # ドメインモデルと ViewModel（API/Cards/Friends/Likes/Profile ...）
├── Service/        # 外部連携（AuthService, *Repository, GooglePlacesClient, KeyManager ...）
├── Views/          # 画面（Auth/Cards/Likes/Friends/Profile/TabBar ...）
├── Shared/         # 横断ユーティリティ（ErrorHandling, Extension, AvatarImageResizer ...）
└── Utils/          # アプリ起動・ContentView・定数・モックデータ
```

- **エラー表示**: 単発は `.alert`、多重に発生しうる箇所は `ErrorQueue` + `ErrorBannerView` で集約表示。
- **プロフィール共有**: `UserProfile.shared` を単一インスタンスとして持ち、ログイン状態に応じて Firestore 同期を開始 / 停止。

---

## Firestore データモデル

| コレクション | 内容 | アクセス制御（要旨） |
| --- | --- | --- |
| `users/{uid}/**` | 本体データ（プロフィール・favorites・friends 等） | 本人のみ読み書き |
| `friendCodes/{code}` | 友達コード → uid の対応表 | ログインユーザーは読み取り可。作成は自分の uid のみ、上書きは現所有者のみ |
| `publicProfiles/{uid}` | 友達に公開するプロフィール | ログインユーザーは読み取り可、書き込みは本人のみ |
| `friendRequests/{fromUid__toUid}` | 友達申請 | 当事者（送信者・受信者）のみ |
| `chats/{chatId}` / `messages/{messageId}` | 1 対 1 チャット | 参加者のみ。メッセージは自分名義でのみ送信可 |

セキュリティルールは `firestore.rules` で定義しています。

---

## セットアップ

1. リポジトリをクローンし、`DishMatch.xcodeproj` を Xcode で開く（Swift Package の解決を待つ）。
2. **API キー**: `DishMatch/APIKey.plist` を用意し、ホットペッパー / Google Places の API キーを記述（`.gitignore` 済み）。
3. **Firebase**: Firebase コンソールから `GoogleService-Info.plist` をダウンロードし `DishMatch/` に配置（`.gitignore` 済み）。
   - Authentication で「メール / パスワード」を有効化。
   - Cloud Firestore を作成。
4. ビルドしてシミュレータまたは実機で実行。

> ⚠️ `APIKey.plist` と `GoogleService-Info.plist` は機密情報のためリポジトリには含まれません。各自で用意してください。

### Firestore ルールのデプロイ

```bash
firebase deploy --only firestore:rules --project <your-project-id>
```

---

## Firestore セキュリティルールのテスト

`firestore-tests/` に、Firebase Emulator 上でルールを検証する自動テストがあります（正常系・攻撃系を網羅）。

```bash
cd firestore-tests
npm install
npm test   # Firebase Emulator を起動して vitest を実行（Java が必要）
```

---

## 開発環境

- Xcode 16 以降
- Swift / SwiftUI
- 対象 OS: iOS 18 以降

---

## 作者

大江 悠都
