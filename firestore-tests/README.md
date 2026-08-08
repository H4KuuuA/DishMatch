# DishMatch Firestore セキュリティルール検証テスト

`firestore.rules` に対する脆弱性検証テスト。Firebase Emulator 上で実際にルールを評価し、
「本人・当事者・参加者だけ」にアクセスが限定できているかを確認する。

## 検証している観点

**正常系（許可されるべき）**
- 本人による `users/{uid}` の読み書き（サブコレクション含む）
- `friendCodes` / `publicProfiles` の読み取りと自分名義の書き込み
- 当事者による `friendRequest` の作成・読み取り
- chat 参加者による自分名義のメッセージ送信・読み取り

**攻撃系（拒否されるべき）**
- 未認証アクセス
- 他人の `users/{uid}` の読み書き
- `fromUid` を偽装した friendRequest 作成（なりすまし）
- 第三者による他人同士の friendRequest 読み取り
- chat 非参加者によるメッセージ読み取り
- `senderUid` を偽装したメッセージ送信
- 他人の `publicProfiles` 書き換え
- 未定義コレクションへの書き込み（デフォルト deny）
- **[脆弱性候補]** 他人が所有する friendCode の横取り（上書き）
- **[脆弱性候補]** chat 参加者による無関係な第三者の participants 追加

## 前提

- Node.js 18+
- Java（Firebase Emulator に必須）

## 実行

```bash
cd firestore-tests
npm install
npm test
```

`npm test` は Firestore エミュレータを起動し、その上で vitest を走らせて終了時に自動で片付ける。
