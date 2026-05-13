import Foundation

struct PresetDefinition: Identifiable {
    var id: String
    var title: String
    var subtitle: String
    var version: Int
    var expectedCardCount: Int
    var sourceNote: String
    var cards: [PresetCardDefinition]

    var isComplete: Bool {
        cards.count == expectedCardCount
    }
}

struct PresetCardDefinition: Identifiable {
    var presetID: String
    var type: CardType
    var fields: [(name: String, value: String)]

    var id: String { presetID }
}

enum DefaultPresetCatalog {
    static let presets: [PresetDefinition] = [
        jouyouKanjiStarter,
        basicVocabularyStarter,
    ]

    static let jouyouKanjiStarter = PresetDefinition(
        id: "jouyou-kanji-v1",
        title: "상용 한자 2136",
        subtitle: "전체 2136자 import 구조 준비. 현재 번들에는 검증용 시작 세트만 포함.",
        version: 1,
        expectedCardCount: 2136,
        sourceNote: "전체 데이터는 상용 한자표와 읽기/뜻/예문 출처 및 라이선스 확정 후 교체해야 합니다.",
        cards: [
            PresetCardDefinition(
                presetID: "jouyou-kanji-v1-0001",
                type: .kanji,
                fields: [
                    ("kanji", "日"),
                    ("meaning", "날, 해"),
                    ("onyomi", "ニチ, ジツ"),
                    ("kunyomi", "ひ, か"),
                    ("example", "日本 / にほん / 일본"),
                ]
            ),
            PresetCardDefinition(
                presetID: "jouyou-kanji-v1-0002",
                type: .kanji,
                fields: [
                    ("kanji", "本"),
                    ("meaning", "근본, 책"),
                    ("onyomi", "ホン"),
                    ("kunyomi", "もと"),
                    ("example", "本を読みます。 / 책을 읽습니다."),
                ]
            ),
            PresetCardDefinition(
                presetID: "jouyou-kanji-v1-0003",
                type: .kanji,
                fields: [
                    ("kanji", "語"),
                    ("meaning", "말, 언어"),
                    ("onyomi", "ゴ"),
                    ("kunyomi", "かた-る"),
                    ("example", "日本語 / にほんご / 일본어"),
                ]
            ),
            PresetCardDefinition(
                presetID: "jouyou-kanji-v1-0004",
                type: .kanji,
                fields: [
                    ("kanji", "学"),
                    ("meaning", "배우다, 학문"),
                    ("onyomi", "ガク"),
                    ("kunyomi", "まな-ぶ"),
                    ("example", "学校 / がっこう / 학교"),
                ]
            ),
            PresetCardDefinition(
                presetID: "jouyou-kanji-v1-0005",
                type: .kanji,
                fields: [
                    ("kanji", "校"),
                    ("meaning", "학교, 교정하다"),
                    ("onyomi", "コウ"),
                    ("kunyomi", ""),
                    ("example", "学校に行きます。 / 학교에 갑니다."),
                ]
            ),
        ]
    )

    static let basicVocabularyStarter = PresetDefinition(
        id: "basic-vocabulary-v1",
        title: "기본 단어",
        subtitle: "초기 학습용 일본어 기본 단어 세트",
        version: 1,
        expectedCardCount: 10,
        sourceNote: "앱 내 기본 샘플. 확장 시 난이도와 예문 출처를 별도 확정합니다.",
        cards: [
            PresetCardDefinition(
                presetID: "basic-vocabulary-v1-0001",
                type: .word,
                fields: [
                    ("word", "学校"),
                    ("reading", "がっこう"),
                    ("meaning", "학교"),
                    ("example", "学校に行きます。 / 학교에 갑니다."),
                ]
            ),
            PresetCardDefinition(
                presetID: "basic-vocabulary-v1-0002",
                type: .word,
                fields: [
                    ("word", "先生"),
                    ("reading", "せんせい"),
                    ("meaning", "선생님"),
                    ("example", "先生に質問します。 / 선생님께 질문합니다."),
                ]
            ),
            PresetCardDefinition(
                presetID: "basic-vocabulary-v1-0003",
                type: .word,
                fields: [
                    ("word", "勉強"),
                    ("reading", "べんきょう"),
                    ("meaning", "공부"),
                    ("example", "日本語を勉強します。 / 일본어를 공부합니다."),
                ]
            ),
            PresetCardDefinition(
                presetID: "basic-vocabulary-v1-0004",
                type: .word,
                fields: [
                    ("word", "時間"),
                    ("reading", "じかん"),
                    ("meaning", "시간"),
                    ("example", "時間があります。 / 시간이 있습니다."),
                ]
            ),
            PresetCardDefinition(
                presetID: "basic-vocabulary-v1-0005",
                type: .word,
                fields: [
                    ("word", "今日"),
                    ("reading", "きょう"),
                    ("meaning", "오늘"),
                    ("example", "今日は忙しいです。 / 오늘은 바쁩니다."),
                ]
            ),
            PresetCardDefinition(
                presetID: "basic-vocabulary-v1-0006",
                type: .word,
                fields: [
                    ("word", "明日"),
                    ("reading", "あした"),
                    ("meaning", "내일"),
                    ("example", "明日また来ます。 / 내일 다시 옵니다."),
                ]
            ),
            PresetCardDefinition(
                presetID: "basic-vocabulary-v1-0007",
                type: .word,
                fields: [
                    ("word", "友達"),
                    ("reading", "ともだち"),
                    ("meaning", "친구"),
                    ("example", "友達と話します。 / 친구와 이야기합니다."),
                ]
            ),
            PresetCardDefinition(
                presetID: "basic-vocabulary-v1-0008",
                type: .word,
                fields: [
                    ("word", "電車"),
                    ("reading", "でんしゃ"),
                    ("meaning", "전철, 기차"),
                    ("example", "電車に乗ります。 / 전철을 탑니다."),
                ]
            ),
            PresetCardDefinition(
                presetID: "basic-vocabulary-v1-0009",
                type: .word,
                fields: [
                    ("word", "食べる"),
                    ("reading", "たべる"),
                    ("meaning", "먹다"),
                    ("example", "朝ご飯を食べます。 / 아침밥을 먹습니다."),
                ]
            ),
            PresetCardDefinition(
                presetID: "basic-vocabulary-v1-0010",
                type: .word,
                fields: [
                    ("word", "見る"),
                    ("reading", "みる"),
                    ("meaning", "보다"),
                    ("example", "映画を見ます。 / 영화를 봅니다."),
                ]
            ),
        ]
    )
}
