// DishMatch Firestore セキュリティルール検証テスト
//
// 目的: firestore.rules が「本人・当事者・参加者だけ」にアクセスを限定できているかを
//       エミュレータ上で実際に検証する。正常系は許可されること、攻撃系は拒否されること、
//       そして脆弱性候補は「安全であるべき挙動」を assert しているので、
//       もし通ってしまえばテストが失敗し、脆弱性として顕在化する。

import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";
import { beforeAll, afterAll, beforeEach, describe, it } from "vitest";
import {
  initializeTestEnvironment,
  assertSucceeds,
  assertFails,
} from "@firebase/rules-unit-testing";
import {
  doc,
  getDoc,
  setDoc,
  updateDoc,
  deleteDoc,
  collection,
  getDocs,
} from "firebase/firestore";

const __dirname = dirname(fileURLToPath(import.meta.url));
const RULES_PATH = resolve(__dirname, "..", "firestore.rules");

const ALICE = "alice_uid";
const BOB = "bob_uid";
const MALLORY = "mallory_uid"; // 攻撃者

let testEnv;

beforeAll(async () => {
  testEnv = await initializeTestEnvironment({
    projectId: "dishmatch-security-test",
    firestore: {
      rules: readFileSync(RULES_PATH, "utf8"),
      host: "127.0.0.1",
      port: 8080,
    },
  });
});

afterAll(async () => {
  await testEnv?.cleanup();
});

beforeEach(async () => {
  await testEnv.clearFirestore();
});

// ルールを無効化して初期データを投入するヘルパ。
async function seed(fn) {
  await testEnv.withSecurityRulesDisabled(async (ctx) => {
    await fn(ctx.firestore());
  });
}

const db = (uid) =>
  uid ? testEnv.authenticatedContext(uid).firestore()
      : testEnv.unauthenticatedContext().firestore();

// =====================================================================
// 正常系: 正当な操作は許可されるべき
// =====================================================================
describe("正常系（許可されるべき）", () => {
  it("本人は自分の users/{uid} を読み書きできる", async () => {
    const alice = db(ALICE);
    await assertSucceeds(setDoc(doc(alice, "users", ALICE), { name: "Alice" }));
    await assertSucceeds(getDoc(doc(alice, "users", ALICE)));
  });

  it("本人は自分の users/{uid} 配下のサブコレクションも書ける", async () => {
    const alice = db(ALICE);
    await assertSucceeds(
      setDoc(doc(alice, "users", ALICE, "favorites", "shop1"), { name: "寿司" })
    );
  });

  it("ログインユーザーは friendCodes を読め、自分のコードを書ける", async () => {
    const alice = db(ALICE);
    await assertSucceeds(setDoc(doc(alice, "friendCodes", "ALICE123"), { uid: ALICE }));
    await assertSucceeds(getDoc(doc(alice, "friendCodes", "ALICE123")));
  });

  it("ログインユーザーは publicProfiles を読め、自分のを書ける", async () => {
    const alice = db(ALICE);
    await assertSucceeds(setDoc(doc(alice, "publicProfiles", ALICE), { nickname: "ありす" }));
    await assertSucceeds(getDoc(doc(db(BOB), "publicProfiles", ALICE)));
  });

  it("申請者は自分名義の friendRequest を作成でき、当事者は読める", async () => {
    const id = `${ALICE}__${BOB}`;
    await assertSucceeds(
      setDoc(doc(db(ALICE), "friendRequests", id), {
        fromUid: ALICE, toUid: BOB, fromNickname: "ありす",
        status: "pending", createdAt: 1,
      })
    );
    await assertSucceeds(getDoc(doc(db(BOB), "friendRequests", id)));   // 受信者
    await assertSucceeds(getDoc(doc(db(ALICE), "friendRequests", id))); // 送信者
  });

  it("chat 参加者は自分名義でメッセージを送れて読める", async () => {
    await seed(async (adminDb) => {
      await setDoc(doc(adminDb, "chats", "c1"), { participants: [ALICE, BOB] });
    });
    const alice = db(ALICE);
    await assertSucceeds(
      setDoc(doc(alice, "chats", "c1", "messages", "m1"), { senderUid: ALICE, text: "やあ" })
    );
    await assertSucceeds(getDoc(doc(db(BOB), "chats", "c1", "messages", "m1")));
  });
});

// =====================================================================
// 攻撃系: 不正な操作は拒否されるべき（通ってしまえば脆弱性）
// =====================================================================
describe("攻撃系（拒否されるべき）", () => {
  it("未認証ユーザーは何も読めない", async () => {
    await seed(async (adminDb) => {
      await setDoc(doc(adminDb, "publicProfiles", ALICE), { nickname: "ありす" });
    });
    const anon = db(null);
    await assertFails(getDoc(doc(anon, "publicProfiles", ALICE)));
    await assertFails(getDoc(doc(anon, "friendCodes", "ALICE123")));
  });

  it("他人の users/{uid} は読めない・書けない", async () => {
    await seed(async (adminDb) => {
      await setDoc(doc(adminDb, "users", ALICE), { name: "Alice", secret: "秘密" });
    });
    const mallory = db(MALLORY);
    await assertFails(getDoc(doc(mallory, "users", ALICE)));
    await assertFails(setDoc(doc(mallory, "users", ALICE), { name: "改ざん" }));
  });

  it("他人になりすました friendRequest（fromUid偽装）は作成できない", async () => {
    // Mallory が「Alice からの申請」に見せかけて作成しようとする
    const id = `${ALICE}__${BOB}`;
    await assertFails(
      setDoc(doc(db(MALLORY), "friendRequests", id), {
        fromUid: ALICE, toUid: BOB, fromNickname: "なりすまし",
        status: "pending", createdAt: 1,
      })
    );
  });

  it("第三者は他人同士の friendRequest を読めない", async () => {
    const id = `${ALICE}__${BOB}`;
    await seed(async (adminDb) => {
      await setDoc(doc(adminDb, "friendRequests", id), {
        fromUid: ALICE, toUid: BOB, fromNickname: "ありす",
        status: "pending", createdAt: 1,
      });
    });
    await assertFails(getDoc(doc(db(MALLORY), "friendRequests", id)));
  });

  it("chat 非参加者はメッセージを読めない", async () => {
    await seed(async (adminDb) => {
      await setDoc(doc(adminDb, "chats", "c1"), { participants: [ALICE, BOB] });
      await setDoc(doc(adminDb, "chats", "c1", "messages", "m1"), { senderUid: ALICE, text: "内緒" });
    });
    await assertFails(getDoc(doc(db(MALLORY), "chats", "c1", "messages", "m1")));
  });

  it("メッセージの senderUid を偽装して送れない", async () => {
    await seed(async (adminDb) => {
      await setDoc(doc(adminDb, "chats", "c1"), { participants: [ALICE, BOB] });
    });
    // Bob が Alice 名義でメッセージを送ろうとする
    await assertFails(
      setDoc(doc(db(BOB), "chats", "c1", "messages", "m2"), { senderUid: ALICE, text: "偽装" })
    );
  });

  it("他人の publicProfiles を書き換えられない", async () => {
    await assertFails(
      setDoc(doc(db(MALLORY), "publicProfiles", ALICE), { nickname: "乗っ取り" })
    );
  });

  it("デフォルト deny: 未定義コレクションには書き込めない", async () => {
    await assertFails(setDoc(doc(db(ALICE), "randomCollection", "x"), { a: 1 }));
  });

  // ---- 脆弱性候補（安全であるべき＝ここが失敗したら脆弱性） ----

  it("[脆弱性候補] 他人が既に所有する friendCode を横取り（上書き）できない", async () => {
    // Alice が自分の friendCode を登録済み
    await seed(async (adminDb) => {
      await setDoc(doc(adminDb, "friendCodes", "ALICE123"), { uid: ALICE });
    });
    // Mallory が Alice のコードを自分の uid で上書きしようとする（＝友達コード乗っ取り）
    await assertFails(
      setDoc(doc(db(MALLORY), "friendCodes", "ALICE123"), { uid: MALLORY })
    );
  });

  it("[脆弱性候補] chat 参加者が無関係の第三者を participants に追加できない", async () => {
    await seed(async (adminDb) => {
      await setDoc(doc(adminDb, "chats", "c1"), { participants: [ALICE, BOB] });
    });
    // Bob（参加者）が赤の他人 Mallory を勝手に会話へ追加 → Mallory が全メッセージを閲覧可能になる
    await assertFails(
      updateDoc(doc(db(BOB), "chats", "c1"), { participants: [ALICE, BOB, MALLORY] })
    );
  });
});
