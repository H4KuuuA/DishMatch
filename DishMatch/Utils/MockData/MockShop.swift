//
//  MockShop.swift
//  DishMatch
//
//  Created by 大江悠都 on 2025/01/25.
//

import Foundation

struct MockShop {
    static let mockShop = Shop(
        id : "12345",
        name: "鮨処 まぐろ亭",
        genre: Genre(code: "G001", name: "和食", genreCatch: "本格江戸前寿司"),
        photo: Photo(pc: Pc(l: "https://example.com/image1.jpg")),
        address: "東京都新宿区西新宿1-2-3",
        close: "日曜・祝日",
        open: "11:00〜23:00（L.O.22:30）",
        shopCatch: "新鮮なネタを職人が握る、こだわりの江戸前寿司",
        urls: Urls(pc: "https://example.com/sushi"),
        stationName: "新宿",
        budget: Budget(code: "B002", name: "2001〜3000円", average: "3000円"),
        mobile_access: "新宿駅から徒歩1分",
        access: "JR新宿駅 南口より徒歩1分／都営新宿線 新宿駅 A1出口すぐ",
        subGenre: SubGenre(code: "G001-1", name: "寿司"),
        capacity: 42,
        budgetMemo: "コース料理は4000円〜。飲み放題付きプランもあり。",
        otherMemo: "カウンター席あり。おひとり様も歓迎です。",
        shopDetailMemo: nil,
        freeDrink: "あり",
        freeFood: "なし",
        course: "あり",
        privateRoom: "あり",
        horigotatsu: "あり",
        tatami: "なし",
        card: "利用可",
        nonSmoking: "全面禁煙",
        charter: "貸切不可",
        ktai: "利用可",
        parking: "なし（近隣にコインパーキングあり）",
        barrierFree: "なし",
        wifi: "あり",
        lunch: "あり",
        midnight: "なし",
        child: "お子様連れOK",
        pet: "不可",
        english: "英語メニューあり",
        wedding: "なし",
        show: "なし",
        karaoke: "なし",
        band: "なし",
        tv: "なし"
    )
}
