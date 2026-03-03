import Foundation
import SwiftUI

final class DataStore {
    let radicals: [RadicalEntry]
    let kanjiEntries: [KanjiEntry]
    let visionImpairedExcludedDisplayPositions: Set<RadicalDisplayPosition> = [.enclosing, .topLeft, .leftBottom]

    init() {
        radicals = [
            RadicalEntry(
                id: "tree",
                symbol: "木",
                nameEnglish: "Tree",
                meaningEnglish: ["tree", "wood"],
                searchTags: ["forest", "nature"],
                displayPosition: .standalone
            ),
            RadicalEntry(
                id: "person-left",
                symbol: "亻",
                nameEnglish: "Person Left",
                meaningEnglish: ["person", "human", "person (left)"],
                searchTags: ["left radical", "human"],
                displayPosition: .leftSide
            ),
            RadicalEntry(
                id: "speech",
                symbol: "言",
                nameEnglish: "Speech",
                meaningEnglish: ["speech", "words", "say"],
                searchTags: ["language", "talk"],
                displayPosition: .leftSide
            ),
            RadicalEntry(
                id: "grass-crown",
                symbol: "艹",
                nameEnglish: "Grass Crown",
                meaningEnglish: ["grass", "plant"],
                searchTags: ["top radical", "plants"],
                displayPosition: .top
            ),
            RadicalEntry(
                id: "cover-u",
                symbol: "⺇",
                nameEnglish: "Cover",
                meaningEnglish: ["cover", "frame", "top cover"],
                searchTags: ["u-shape", "wrap"],
                displayPosition: .enclosing
            ),
            RadicalEntry(
                id: "sun",
                symbol: "日",
                nameEnglish: "Sun",
                meaningEnglish: ["sun", "day"],
                searchTags: ["light"],
                displayPosition: .standalone
            ),
            RadicalEntry(
                id: "fire",
                symbol: "火",
                nameEnglish: "Fire",
                meaningEnglish: ["fire", "flame"],
                searchTags: ["burn", "heat"],
                displayPosition: .standalone
            ),
            RadicalEntry(
                id: "gate",
                symbol: "門",
                nameEnglish: "Gate",
                meaningEnglish: ["gate", "door"],
                searchTags: ["entrance", "opening"],
                displayPosition: .enclosing
            ),
            RadicalEntry(
                id: "ear",
                symbol: "耳",
                nameEnglish: "Ear",
                meaningEnglish: ["ear", "hearing"],
                searchTags: ["listen", "sound"],
                displayPosition: .standalone
            ),
            RadicalEntry(
                id: "little-bits",
                symbol: "⺍",
                nameEnglish: "Little Bits",
                meaningEnglish: ["little bits", "small drops", "small"],
                searchTags: ["tiny", "dots", "top component"],
                displayPosition: .top
            ),
            RadicalEntry(
                id: "roof-cover",
                symbol: "冖",
                nameEnglish: "Cover",
                meaningEnglish: ["cover", "roof"],
                searchTags: ["crown", "top cover"],
                displayPosition: .top
            ),
            RadicalEntry(
                id: "roof",
                symbol: "宀",
                nameEnglish: "Roof",
                meaningEnglish: ["roof", "house roof", "shelter"],
                searchTags: ["top radical", "home", "crown"],
                displayPosition: .top
            ),
            RadicalEntry(
                id: "child",
                symbol: "子",
                nameEnglish: "Child",
                meaningEnglish: ["child", "kid"],
                searchTags: ["son", "young"],
                displayPosition: .bottom
            ),
            RadicalEntry(
                id: "step-left",
                symbol: "彳",
                nameEnglish: "Step Left",
                meaningEnglish: ["step", "go", "movement"],
                searchTags: ["left radical", "walk"],
                displayPosition: .leftSide
            ),
            RadicalEntry(
                id: "mountain",
                symbol: "山",
                nameEnglish: "Mountain",
                meaningEnglish: ["mountain", "peak"],
                searchTags: ["hill"],
                displayPosition: .standalone
            ),
            RadicalEntry(
                id: "one",
                symbol: "一",
                nameEnglish: "One",
                meaningEnglish: ["one", "single line"],
                searchTags: ["horizontal line", "stroke"],
                displayPosition: .top
            ),
            RadicalEntry(
                id: "king",
                symbol: "王",
                nameEnglish: "King",
                meaningEnglish: ["king", "jade"],
                searchTags: ["ruler"],
                displayPosition: .standalone
            ),
            RadicalEntry(
                id: "strike",
                symbol: "攵",
                nameEnglish: "Strike",
                meaningEnglish: ["strike", "tap", "action"],
                searchTags: ["right component", "action"],
                displayPosition: .rightSide
            ),
            RadicalEntry(
                id: "heart",
                symbol: "心",
                nameEnglish: "Heart",
                meaningEnglish: ["heart", "mind", "feeling"],
                searchTags: ["emotion"],
                displayPosition: .bottom
            ),
            RadicalEntry(
                id: "shelter",
                symbol: "广",
                nameEnglish: "Shelter",
                meaningEnglish: ["shelter", "house on cliff"],
                searchTags: ["top-left", "roof", "building"],
                displayPosition: .topLeft
            ),
            RadicalEntry(
                id: "walk-left-bottom",
                symbol: "⻌",
                nameEnglish: "Walk",
                meaningEnglish: ["walk", "road", "movement"],
                searchTags: ["left-bottom", "path", "travel"],
                displayPosition: .leftBottom
            ),
            RadicalEntry(
                id: "bird",
                symbol: "隹",
                nameEnglish: "Bird",
                meaningEnglish: ["bird", "short-tailed bird"],
                searchTags: ["advance", "wing", "right component"],
                displayPosition: .rightSide
            ),
            RadicalEntry(
                id: "army",
                symbol: "軍",
                nameEnglish: "Army",
                meaningEnglish: ["army", "troops", "military load"],
                searchTags: ["transport", "carry", "right component"],
                displayPosition: .rightSide
            ),
            RadicalEntry(
                id: "bird-full",
                symbol: "鳥",
                nameEnglish: "Bird",
                meaningEnglish: ["bird", "chirp", "cry"],
                searchTags: ["sound", "call", "right component"],
                displayPosition: .rightSide
            ),
            RadicalEntry(
                id: "gold",
                symbol: "金",
                nameEnglish: "Gold",
                meaningEnglish: ["gold", "metal", "money"],
                searchTags: ["wealth", "prosperity", "metal"],
                displayPosition: .standalone
            ),
            RadicalEntry(
                id: "car",
                symbol: "車",
                nameEnglish: "Car",
                meaningEnglish: ["car", "vehicle", "cart"],
                searchTags: ["wagon", "transport", "wheel"],
                displayPosition: .standalone
            ),
            RadicalEntry(
                id: "mouth",
                symbol: "口",
                nameEnglish: "Mouth",
                meaningEnglish: ["mouth", "opening"],
                searchTags: ["speak", "box", "voice"],
                displayPosition: .standalone
            ),
            RadicalEntry(
                id: "big",
                symbol: "大",
                nameEnglish: "Big",
                meaningEnglish: ["big", "large", "great"],
                searchTags: ["large", "size", "big person"],
                displayPosition: .standalone
            ),
            RadicalEntry(
                id: "moon",
                symbol: "月",
                nameEnglish: "Moon",
                meaningEnglish: ["moon", "month"],
                searchTags: ["night", "right component"],
                displayPosition: .rightSide
            ),
            RadicalEntry(
                id: "stone",
                symbol: "石",
                nameEnglish: "Stone",
                meaningEnglish: ["stone", "rock"],
                searchTags: ["cliff", "boulder"],
                displayPosition: .bottom
            ),
            RadicalEntry(
                id: "white",
                symbol: "白",
                nameEnglish: "White",
                meaningEnglish: ["white", "clear"],
                searchTags: ["bright", "plain"],
                displayPosition: .top
            ),
            RadicalEntry(
                id: "water",
                symbol: "水",
                nameEnglish: "Water",
                meaningEnglish: ["water", "liquid"],
                searchTags: ["flow", "stream"],
                displayPosition: .bottom
            ),
            RadicalEntry(
                id: "water-left",
                symbol: "氵",
                nameEnglish: "Water Left",
                meaningEnglish: ["water", "liquid", "water (left)"],
                searchTags: ["stream", "left radical"],
                displayPosition: .leftSide
            ),
            RadicalEntry(
                id: "person",
                symbol: "人",
                nameEnglish: "Person",
                meaningEnglish: ["person", "human"],
                searchTags: ["standalone person", "human"],
                displayPosition: .standalone
            ),
            RadicalEntry(
                id: "stand",
                symbol: "立",
                nameEnglish: "Stand",
                meaningEnglish: ["stand", "rise"],
                searchTags: ["position", "upright"],
                displayPosition: .rightSide
            ),
            RadicalEntry(
                id: "master",
                symbol: "主",
                nameEnglish: "Master",
                meaningEnglish: ["master", "main", "lord"],
                searchTags: ["main", "chief"],
                displayPosition: .rightSide
            ),
            RadicalEntry(
                id: "past",
                symbol: "昔",
                nameEnglish: "Past",
                meaningEnglish: ["past", "before", "old times"],
                searchTags: ["before", "former"],
                displayPosition: .rightSide
            ),
            RadicalEntry(
                id: "say-cloud",
                symbol: "云",
                nameEnglish: "Say",
                meaningEnglish: ["say", "speak", "cloud"],
                searchTags: ["tell", "words"],
                displayPosition: .rightSide
            ),
            RadicalEntry(
                id: "move",
                symbol: "動",
                nameEnglish: "Move",
                meaningEnglish: ["move", "motion"],
                searchTags: ["work", "action"],
                displayPosition: .rightSide
            ),
            RadicalEntry(
                id: "heavy",
                symbol: "重",
                nameEnglish: "Heavy",
                meaningEnglish: ["heavy", "important", "weight"],
                searchTags: ["weight", "middle component"],
                displayPosition: .rightSide
            ),
            RadicalEntry(
                id: "power",
                symbol: "力",
                nameEnglish: "Power",
                meaningEnglish: ["power", "strength", "force"],
                searchTags: ["strength", "right component"],
                displayPosition: .rightSide
            ),
            RadicalEntry(
                id: "field",
                symbol: "田",
                nameEnglish: "Field",
                meaningEnglish: ["field", "rice field"],
                searchTags: ["farm", "plot"],
                displayPosition: .bottom
            ),
            RadicalEntry(
                id: "comfort",
                symbol: "楽",
                nameEnglish: "Comfort",
                meaningEnglish: ["comfort", "ease", "music"],
                searchTags: ["relief", "easy"],
                displayPosition: .bottom
            ),
            RadicalEntry(
                id: "world",
                symbol: "世",
                nameEnglish: "World",
                meaningEnglish: ["world", "generation"],
                searchTags: ["era", "society"],
                displayPosition: .top
            ),
            RadicalEntry(
                id: "grain-left",
                symbol: "禾",
                nameEnglish: "Grain",
                meaningEnglish: ["grain", "rice plant"],
                searchTags: ["crop", "harvest", "left radical"],
                displayPosition: .leftSide
            ),
            RadicalEntry(
                id: "wine-jar",
                symbol: "酉",
                nameEnglish: "Wine Jar",
                meaningEnglish: ["wine jar", "alcohol vessel"],
                searchTags: ["sake", "ferment"],
                displayPosition: .rightSide
            ),
            RadicalEntry(
                id: "woman",
                symbol: "女",
                nameEnglish: "Woman",
                meaningEnglish: ["woman", "female"],
                searchTags: ["girl", "lady"],
                displayPosition: .bottom
            ),
            RadicalEntry(
                id: "each",
                symbol: "各",
                nameEnglish: "Each",
                meaningEnglish: ["each", "every", "arrival"],
                searchTags: ["guest", "arrive"],
                displayPosition: .bottom
            ),
            RadicalEntry(
                id: "lose",
                symbol: "亡",
                nameEnglish: "Lose",
                meaningEnglish: ["lose", "vanish"],
                searchTags: ["forget", "gone"],
                displayPosition: .top
            ),
            RadicalEntry(
                id: "tongue",
                symbol: "舌",
                nameEnglish: "Tongue",
                meaningEnglish: ["tongue", "speech organ"],
                searchTags: ["mouth", "talk"],
                displayPosition: .rightSide
            ),
            RadicalEntry(
                id: "stop",
                symbol: "止",
                nameEnglish: "Stop",
                meaningEnglish: ["stop", "foot"],
                searchTags: ["walk", "halt"],
                displayPosition: .top
            ),
            RadicalEntry(
                id: "little",
                symbol: "少",
                nameEnglish: "Little",
                meaningEnglish: ["little", "few", "small"],
                searchTags: ["small", "few"],
                displayPosition: .bottom
            ),
            RadicalEntry(
                id: "wind",
                symbol: "風",
                nameEnglish: "Wind",
                meaningEnglish: ["wind", "storm air"],
                searchTags: ["air", "breeze"],
                displayPosition: .bottom
            )
        ]

        /*
         "森(Forest)" = "木(tree)" + "木(tree)" + "木(tree)"
         (A forest is made of many trees. Build the kanji using three 'tree' components.)

         "休(Rest)" = "亻(person)" + "木(tree)"
         (A person leans on a tree to rest.)

         "学(Study)" = "⺍(little bits)" + "冖(cover)" + "子(child)"
         (A child under a cover learns. Place little bits on top, cover in the middle, and child at the bottom.)

         "炎(Blaze)" = "火(fire)" + "火(fire)"
         (Two fires together make a blaze. Place one fire on top and one fire below.)

         "聞(Hear)" = "門(gate)" + "耳(ear)"
         (Ear at the gate means hear. Place gate as the outer frame, then place ear inside it.)

         "器(Vessel)" = "口(mouth)" + "口(mouth)" + "大(big)" + "口(mouth)" + "口(mouth)"
         (Many mouths gather around something big. Build the kanji with four mouth components and one big center piece.)

         "明(Bright)" = "日(sun)" + "月(moon)"
         (Sun and moon together make brightness. Place sun on the left and moon on the right.)

         "林(Woods)" = "木(tree)" + "木(tree)"
         (Two trees together make woods. Place one tree on the left and one on the right.)

         "岩(boulder)" = "山(mountain)" + "石(stone)"
         (A mountain with stone below suggests a rocky cliff. Place mountain on top and stone on the bottom.)

         "品(Goods)" = "口(mouth)" + "口(mouth)" + "口(mouth)"
         (Many mouths or openings suggest a variety of items. Place one mouth on top and two below.)

         "晶(Sparkling)" = "日(sun)" + "日(sun)" + "日(sun)"
         (Three suns together feel extra bright. Place one sun on top and two suns below.)

         "嵐(Storm)" = "山(mountain)" + "風(wind)"
         (Wind on the mountain becomes a storm. Place mountain on top and wind below.)

         "泉(Spring)" = "白(white)" + "水(water)"
         (Clear white water becomes a spring. Place white on top and water below.)

         "信(Trust)" = "亻(person)" + "言(speech)"
         (A person's words suggest trust. Place the person-left component on the left and speech on the right.)

         "位(Rank)" = "亻(person)" + "立(stand)"
         (Where a person stands becomes rank or position. Place the person-left component on the left and stand on the right.)

         "住(Reside)" = "亻(person)" + "主(master)"
         (A person's main place is where they live. Place the person-left component on the left and master on the right.)

         "借(Borrow)" = "亻(person)" + "昔(past)"
         (Taking something that belonged to someone before suggests borrowing. Place the person-left component on the left and past on the right.)

         "伝(Transmit)" = "亻(person)" + "云(say)"
         (A person speaking something onward suggests transmission. Place the person-left component on the left and say on the right.)

         "働(Work)" = "亻(person)" + "重(heavy)" + "力(power)"
         (A person plus something heavy and a forceful push suggests work. Place the person-left component on the left, heavy in the middle, and power on the right.)

         "苗(Seedling)" = "艹(grass)" + "田(field)"
         (Plants in a field make a seedling. Place grass on top and field below.)

         "茶(Tea)" = "艹(grass)" + "人(person)" + "木(tree)"
         (Tea starts with plants, then a person, then tree or wood below. Place grass on top, person in the middle, and tree at the bottom.)

         "薬(Medicine)" = "艹(grass)" + "楽(comfort)"
         (Herbs that bring comfort suggest medicine. Place grass on top and comfort below.)

         "葉(Leaf)" = "艹(grass)" + "世(world)" + "木(tree)"
         (A leaf grows from a plant and wood. Place grass on top, world in the middle, and tree at the bottom.)

         "畑(Cultivated Field)" = "火(fire)" + "田(field)"
         (A field made by burning becomes cultivated land. Place fire on the left and field on the right.)

         "秋(Autumn)" = "禾(grain)" + "火(fire)"
         (Harvest and fire together suggest autumn. Place grain on the left and fire on the right.)

         "酒(Alcohol)" = "氵(water)" + "酉(wine jar)"
         (Liquid in a wine vessel becomes alcohol or sake. Place water on the left and wine jar on the right.)

         "安(Peace)" = "宀(roof)" + "女(woman)"
         (A woman under a roof suggests peace or ease. Place roof on top and woman below.)

         "客(Guest)" = "宀(roof)" + "各(each)"
         (Someone who comes under your roof is a guest. Place roof on top and each below.)

         "忘(Forget)" = "亡(lose)" + "心(heart)"
         (When the heart loses something, you forget. Place lose on top and heart below.)

         "話(Talk)" = "言(speech)" + "舌(tongue)"
         (Words from the tongue become speech. Place speech on the left and tongue on the right.)

         "歩(Walk)" = "止(stop)" + "少(little)"
         (Small steps suggest walking. Place stop on top and little below.)

         "進(Advance)" = "⻌(walk)" + "隹(bird)"
         (A bird moving forward along a path suggests advance. Place the path component on the left and bird on the right.)

         "運(Transport)" = "⻌(walk)" + "軍(army)"
         (Moving an army or load along a path suggests transport. Place the path component on the left and army on the right.)

         "鳴(Chirp)" = "口(mouth)" + "鳥(bird)"
         (A bird's mouth suggests chirping or making a sound. Place mouth on the left and bird on the right.)

         "鑫(Prosperity)" = "金(gold)" + "金(gold)" + "金(gold)"
         (Three gold components together suggest wealth and prosperity. Place one gold on top and two below.)

         "轟(Roar)" = "車(car)" + "車(car)" + "車(car)"
         (Many vehicles rumbling together suggest a roar. Place one car on top and two below.)

         "懲(Discipline)" = "彳(step)" + "山(mountain)" + "王(king)" + "攵(strike)" + "心(heart)"
         (Build "discipline" as "command/sign + heart": place step-left on the upper left, mountain and king in the center, strike on the upper right, and heart across the bottom.)
         */
        kanjiEntries = [
            KanjiEntry(
                id: "forest",
                kanji: "森",
                meaningEnglish: "Forest",
                promptEnglish: "A forest is made of many trees, so seeing three tree parts together helps you picture a dense woodland.",
                requiredComponents: ["tree", "tree", "tree"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "forest-top", expectedRadicalID: "tree", shapeType: .topWide, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 1.0, h: 0.5)),
                        PuzzleSlot(slotID: "forest-left", expectedRadicalID: "tree", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.0, y: 0.5, w: 0.5, h: 0.5)),
                        PuzzleSlot(slotID: "forest-right", expectedRadicalID: "tree", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.5, y: 0.5, w: 0.5, h: 0.5))
                    ]
                ),
                explanationEnglish: "Three tree components combine to express the idea of a dense forest.",
                slotGlyphScaleOverrides: [
                    "forest-top": 1.4,
                    "forest-left": 1.4,
                    "forest-right": 1.4
                ]
            ),
            KanjiEntry(
                id: "rest",
                kanji: "休",
                meaningEnglish: "Rest",
                promptEnglish: "A person can rest by leaning against a tree after getting tired.",
                requiredComponents: ["person-left", "tree"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "rest-left", expectedRadicalID: "person-left", shapeType: .leftTall, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 0.35, h: 1.0)),
                        PuzzleSlot(slotID: "rest-right", expectedRadicalID: "tree", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.35, y: 0.0, w: 0.65, h: 1.0))
                    ]
                ),
                explanationEnglish: "The person radical plus tree conveys taking a break beside a tree.",
                slotGlyphScaleOverrides: [
                    "rest-left": 1.90,
                    "rest-right": 1.2
                ],
                slotGlyphStretchYOverrides: [
                    "rest-left": 1.6,
                    "rest-right": 1.5
                ]
            ),
            KanjiEntry(
                id: "study",
                kanji: "学",
                meaningEnglish: "Study",
                promptEnglish: "A child learns beneath a cover, with little bits of knowledge gathering above.",
                requiredComponents: ["little-bits", "roof-cover", "child"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "study-top", expectedRadicalID: "little-bits", shapeType: .topWide, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 1.0, h: 0.24)),
                        PuzzleSlot(slotID: "study-middle", expectedRadicalID: "roof-cover", shapeType: .topWide, normalizedFrame: NormalizedRect(x: 0.0, y: 0.24, w: 1.0, h: 0.20)),
                        PuzzleSlot(slotID: "study-bottom", expectedRadicalID: "child", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.0, y: 0.44, w: 1.0, h: 0.56))
                    ]
                ),
                explanationEnglish: "This puzzle follows the idea of learning: little marks above, a cover, and a child below.",
                slotGlyphScaleOverrides: [
                    "study-top": 1.38,
                    "study-middle": 1.32,
                    "study-bottom": 1.24
                ],
                slotGlyphStretchXOverrides: [
                    "study-top": 4.0,
                    "study-middle": 5.0,
                ]
            ),
            KanjiEntry(
                id: "blaze",
                kanji: "炎",
                meaningEnglish: "Blaze",
                promptEnglish: "When fire joins with more fire, the flames grow stronger and become a blaze.",
                requiredComponents: ["fire", "fire"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "blaze-top", expectedRadicalID: "fire", shapeType: .topWide, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 1.0, h: 0.50)),
                        PuzzleSlot(slotID: "blaze-bottom", expectedRadicalID: "fire", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.0, y: 0.50, w: 1.0, h: 0.50))
                    ]
                ),
                explanationEnglish: "The kanji 炎 is built by stacking two fire components.",
                slotGlyphScaleOverrides: [
                    "blaze-top": 1.5,
                    "blaze-bottom": 1.5
                ],
                slotGlyphStretchXOverrides: [
                    "blaze-top": 1.6,
                    "blaze-bottom": 1.6
                ]
            ),
            KanjiEntry(
                id: "hear",
                kanji: "聞",
                meaningEnglish: "Hear",
                promptEnglish: "To hear something, you use your ear, especially when listening through a gate or doorway.",
                requiredComponents: ["gate", "ear"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(
                            slotID: "hear-gate",
                            expectedRadicalID: "gate",
                            shapeType: .frameUShape,
                            normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 1.0, h: 1.0),
                            frameUThicknessRatio: 0.20,
                            frameUSideThicknessRatio: 0.22
                        ),
                        PuzzleSlot(slotID: "hear-ear", expectedRadicalID: "ear", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.24, y: 0.40, w: 0.52, h: 0.62))
                    ]
                ),
                explanationEnglish: "聞 combines gate and ear, suggesting hearing something at the gate.",
                slotGlyphScaleOverrides: [
                    "hear-gate": 1.7,
                    "hear-ear": 1.0
                ],
                difficultyOverrides: [
                    .easyMode: .medium
                ]
            ),
            KanjiEntry(
                id: "vessel",
                kanji: "器",
                meaningEnglish: "Vessel",
                promptEnglish: "Many mouth openings surrounding something big can suggest a container, a tool, or a vessel used to hold things.",
                requiredComponents: ["mouth", "mouth", "big", "mouth", "mouth"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "vessel-top-left", expectedRadicalID: "mouth", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 0.5, h: 0.35)),
                        PuzzleSlot(slotID: "vessel-top-right", expectedRadicalID: "mouth", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.5, y: 0.0, w: 0.5, h: 0.35)),
                        PuzzleSlot(slotID: "vessel-center", expectedRadicalID: "big", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.0, y: 0.35, w: 1.0, h: 0.3)),
                        PuzzleSlot(slotID: "vessel-bottom-left", expectedRadicalID: "mouth", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.0, y: 0.65, w: 0.5, h: 0.35)),
                        PuzzleSlot(slotID: "vessel-bottom-right", expectedRadicalID: "mouth", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.5, y: 0.65, w: 0.5, h: 0.35))
                    ]
                ),
                explanationEnglish: "器 combines four mouth shapes around a large center component, giving the sense of a vessel or tool.",
                slotGlyphScaleOverrides: [
                    "vessel-top-left": 1.35,
                    "vessel-top-right": 1.35,
                    "vessel-center": 2.0,
                    "vessel-bottom-left": 1.35,
                    "vessel-bottom-right": 1.35
                ],
                slotGlyphStretchXOverrides: [
                    "vessel-center": 2.0
                ],
                slotGlyphStretchYOverrides: [
                    "vessel-center": 0.5
                ]
            ),
            KanjiEntry(
                id: "bright",
                kanji: "明",
                meaningEnglish: "Bright",
                promptEnglish: "The sun and the moon together create an image of brightness and light.",
                requiredComponents: ["sun", "moon"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "bright-left", expectedRadicalID: "sun", shapeType: .leftTall, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 0.48, h: 1.0)),
                        PuzzleSlot(slotID: "bright-right", expectedRadicalID: "moon", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.48, y: 0.0, w: 0.52, h: 1.0))
                    ]
                ),
                explanationEnglish: "明 joins sun and moon to express brightness.",
                slotGlyphScaleOverrides: [
                    "bright-left": 1.22,
                    "bright-right": 1.22
                ],
                slotGlyphStretchYOverrides: [
                    "bright-left": 1.5,
                    "bright-right": 1.5
                ]
            ),
            KanjiEntry(
                id: "woods",
                kanji: "林",
                meaningEnglish: "Woods",
                promptEnglish: "When two tree parts appear together, they suggest a small woods or grove.",
                requiredComponents: ["tree", "tree"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "woods-left", expectedRadicalID: "tree", shapeType: .leftTall, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 0.5, h: 1.0)),
                        PuzzleSlot(slotID: "woods-right", expectedRadicalID: "tree", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.5, y: 0.0, w: 0.5, h: 1.0))
                    ]
                ),
                explanationEnglish: "林 is formed by placing two tree components side by side.",
                slotGlyphScaleOverrides: [
                    "woods-left": 1.02,
                    "woods-right": 1.02
                ],
                slotGlyphStretchYOverrides: [
                    "woods-left": 1.7,
                    "woods-right": 1.7
                ]
            ),
            KanjiEntry(
                id: "rock",
                kanji: "岩",
                meaningEnglish: "boulder",
                promptEnglish: "A mountain made of stone gives the image of a large rock or boulder.",
                requiredComponents: ["mountain", "stone"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "rock-top", expectedRadicalID: "mountain", shapeType: .topWide, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 1.0, h: 0.34)),
                        PuzzleSlot(slotID: "rock-bottom", expectedRadicalID: "stone", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.0, y: 0.34, w: 1.0, h: 0.66))
                    ]
                ),
                explanationEnglish: "岩 combines mountain and stone to convey a large rock or cliff.",
                slotGlyphScaleOverrides: [
                    "rock-top": 1.2,
                    "rock-bottom": 1.36
                ],
                slotGlyphStretchXOverrides: [
                    "rock-top": 3.5,
                    "rock-bottom": 1.7
                ]
                
            ),
            KanjiEntry(
                id: "goods",
                kanji: "品",
                meaningEnglish: "Goods",
                promptEnglish: "Several mouth openings together can suggest many separate items, like a variety of goods.",
                requiredComponents: ["mouth", "mouth", "mouth"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "goods-top", expectedRadicalID: "mouth", shapeType: .topWide, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 1.0, h: 0.5)),
                        PuzzleSlot(slotID: "goods-bottom-left", expectedRadicalID: "mouth", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.0, y: 0.5, w: 0.5, h: 0.5)),
                        PuzzleSlot(slotID: "goods-bottom-right", expectedRadicalID: "mouth", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.5, y: 0.5, w: 0.5, h: 0.5))
                    ]
                ),
                explanationEnglish: "品 stacks three mouth shapes to suggest many items or varieties.",
                slotGlyphScaleOverrides: [
                    "goods-top": 1.3,
                    "goods-bottom-left": 1.28,
                    "goods-bottom-right": 1.28
                ]
            ),
            KanjiEntry(
                id: "sparkling",
                kanji: "晶",
                meaningEnglish: "Sparkling",
                promptEnglish: "Three sun parts together make the image of something shining, sparkling, and brilliantly bright.",
                requiredComponents: ["sun", "sun", "sun"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "sparkling-top", expectedRadicalID: "sun", shapeType: .topWide, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 1.0, h: 0.5)),
                        PuzzleSlot(slotID: "sparkling-bottom-left", expectedRadicalID: "sun", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.0, y: 0.5, w: 0.5, h: 0.5)),
                        PuzzleSlot(slotID: "sparkling-bottom-right", expectedRadicalID: "sun", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.5, y: 0.5, w: 0.5, h: 0.5))
                    ]
                ),
                explanationEnglish: "晶 uses three sun components to express intense brightness or sparkle.",
                slotGlyphScaleOverrides: [
                    "sparkling-top": 1.22,
                    "sparkling-bottom-left": 1.2,
                    "sparkling-bottom-right": 1.2
                ]
            ),
            KanjiEntry(
                id: "storm",
                kanji: "嵐",
                meaningEnglish: "Storm",
                promptEnglish: "Strong wind around a mountain brings to mind a fierce storm.",
                requiredComponents: ["mountain", "wind"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "storm-top", expectedRadicalID: "mountain", shapeType: .topWide, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 1.0, h: 0.32)),
                        PuzzleSlot(slotID: "storm-bottom", expectedRadicalID: "wind", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.0, y: 0.32, w: 1.0, h: 0.68))
                    ]
                ),
                explanationEnglish: "嵐 combines mountain and wind to suggest a mountain storm.",
                slotGlyphScaleOverrides: [
                    "storm-top": 1.16,
                    "storm-bottom": 1.28
                ],
                slotGlyphStretchXOverrides: [
                    "storm-top": 3.5,
                    "storm-bottom": 1.58
                ]
            ),
            KanjiEntry(
                id: "spring",
                kanji: "泉",
                meaningEnglish: "Spring",
                promptEnglish: "Clear white water flowing out suggests a fresh natural spring.",
                requiredComponents: ["white", "water"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "spring-top", expectedRadicalID: "white", shapeType: .topWide, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 1.0, h: 0.5)),
                        PuzzleSlot(slotID: "spring-bottom", expectedRadicalID: "water", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.0, y: 0.5, w: 1.0, h: 0.5))
                    ]
                ),
                explanationEnglish: "泉 stacks white above water to represent a clear spring or fountain.",
                slotGlyphScaleOverrides: [
                    "spring-top": 1.28,
                    "spring-bottom": 1.5
                ]
            ),
            KanjiEntry(
                id: "trust",
                kanji: "信",
                meaningEnglish: "Trust",
                promptEnglish: "When a person speaks with honest speech, it creates trust.",
                requiredComponents: ["person-left", "speech"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "trust-left", expectedRadicalID: "person-left", shapeType: .leftTall, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 0.30, h: 1.0)),
                        PuzzleSlot(slotID: "trust-right", expectedRadicalID: "speech", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.30, y: 0.0, w: 0.70, h: 1.0))
                    ]
                ),
                explanationEnglish: "信 pairs person with speech to suggest trust or belief in words.",
                slotGlyphScaleOverrides: [
                    "trust-left": 1.86,
                    "trust-right": 1.08
                ],
                slotGlyphStretchYOverrides: [
                    "trust-left": 1.58,
                    "trust-right": 1.2
                ]
            ),
            KanjiEntry(
                id: "rank",
                kanji: "位",
                meaningEnglish: "Rank",
                promptEnglish: "The place where a person stands can represent their rank or position.",
                requiredComponents: ["person-left", "stand"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "rank-left", expectedRadicalID: "person-left", shapeType: .leftTall, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 0.30, h: 1.0)),
                        PuzzleSlot(slotID: "rank-right", expectedRadicalID: "stand", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.30, y: 0.0, w: 0.70, h: 1.0))
                    ]
                ),
                explanationEnglish: "位 combines person and stand to express place, rank, or position.",
                slotGlyphScaleOverrides: [
                    "rank-left": 1.86,
                    "rank-right": 1.12
                ],
                slotGlyphStretchYOverrides: [
                    "rank-left": 1.58,
                    "rank-right": 1.34
                ]
            ),
            KanjiEntry(
                id: "reside",
                kanji: "住",
                meaningEnglish: "Reside",
                promptEnglish: "A person settles in one main place, and that master place becomes where they live.",
                requiredComponents: ["person-left", "master"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "reside-left", expectedRadicalID: "person-left", shapeType: .leftTall, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 0.30, h: 1.0)),
                        PuzzleSlot(slotID: "reside-right", expectedRadicalID: "master", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.30, y: 0.0, w: 0.70, h: 1.0))
                    ]
                ),
                explanationEnglish: "住 uses person and master to suggest a main place where someone lives.",
                slotGlyphScaleOverrides: [
                    "reside-left": 1.86,
                    "reside-right": 1.12
                ],
                slotGlyphStretchYOverrides: [
                    "reside-left": 1.58,
                    "reside-right": 1.3
                ]
            ),
            KanjiEntry(
                id: "borrow",
                kanji: "借",
                meaningEnglish: "Borrow",
                promptEnglish: "A person taking something that existed in the past suggests borrowing it for a while.",
                requiredComponents: ["person-left", "past"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "borrow-left", expectedRadicalID: "person-left", shapeType: .leftTall, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 0.30, h: 1.0)),
                        PuzzleSlot(slotID: "borrow-right", expectedRadicalID: "past", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.30, y: 0.0, w: 0.70, h: 1.0))
                    ]
                ),
                explanationEnglish: "借 joins person with past to suggest borrowing something that belonged to someone before.",
                slotGlyphScaleOverrides: [
                    "borrow-left": 1.86,
                    "borrow-right": 1.05
                ],
                slotGlyphStretchYOverrides: [
                    "borrow-left": 1.58,
                    "borrow-right": 1.18
                ]
            ),
            KanjiEntry(
                id: "transmit",
                kanji: "伝",
                meaningEnglish: "Transmit",
                promptEnglish: "When a person says something and passes it along, that idea is transmitted through speech.",
                requiredComponents: ["person-left", "say-cloud"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "transmit-left", expectedRadicalID: "person-left", shapeType: .leftTall, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 0.30, h: 1.0)),
                        PuzzleSlot(slotID: "transmit-right", expectedRadicalID: "say-cloud", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.30, y: 0.0, w: 0.70, h: 1.0))
                    ]
                ),
                explanationEnglish: "伝 pairs person with say to suggest passing something on.",
                slotGlyphScaleOverrides: [
                    "transmit-left": 1.86,
                    "transmit-right": 1.12
                ],
                slotGlyphStretchYOverrides: [
                    "transmit-left": 1.58,
                    "transmit-right": 1.28
                ]
            ),
            KanjiEntry(
                id: "work",
                kanji: "働",
                meaningEnglish: "Work",
                promptEnglish: "A person using power to handle something heavy captures the feeling of hard work.",
                requiredComponents: ["person-left", "heavy", "power"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "work-left", expectedRadicalID: "person-left", shapeType: .leftTall, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 0.24, h: 1.0)),
                        PuzzleSlot(slotID: "work-middle", expectedRadicalID: "heavy", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.24, y: 0.0, w: 0.56, h: 1.0)),
                        PuzzleSlot(slotID: "work-right", expectedRadicalID: "power", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.80, y: 0.0, w: 0.20, h: 1.0))
                    ]
                ),
                explanationEnglish: "働 can be taught here as person plus heavy plus power, expressing labor and work.",
                slotGlyphScaleOverrides: [
                    "work-left": 1.86,
                    "work-middle": 1.02,
                    "work-right": 1.18
                ],
                slotGlyphStretchYOverrides: [
                    "work-left": 1.58,
                    "work-middle": 1.12,
                    "work-right": 2
                ]
            ),
            KanjiEntry(
                id: "seedling",
                kanji: "苗",
                meaningEnglish: "Seedling",
                promptEnglish: "New grass growing in a field gives the image of a young seedling.",
                requiredComponents: ["grass-crown", "field"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "seedling-top", expectedRadicalID: "grass-crown", shapeType: .topWide, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 1.0, h: 0.24)),
                        PuzzleSlot(slotID: "seedling-bottom", expectedRadicalID: "field", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.0, y: 0.24, w: 1.0, h: 0.76))
                    ]
                ),
                explanationEnglish: "苗 combines grass on top of a field to express a young plant or seedling.",
                slotGlyphScaleOverrides: [
                    "seedling-top": 1.38,
                    "seedling-bottom": 1.6
                ],
                slotGlyphStretchXOverrides: [
                    "seedling-top": 4.6
                ]
            ),
            KanjiEntry(
                id: "tea",
                kanji: "茶",
                meaningEnglish: "Tea",
                promptEnglish: "Grass leaves, a person, and a tree together create the image of tea coming from plants prepared by human hands.",
                requiredComponents: ["grass-crown", "person", "tree"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "tea-top", expectedRadicalID: "grass-crown", shapeType: .topWide, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 1.0, h: 0.22)),
                        PuzzleSlot(slotID: "tea-middle", expectedRadicalID: "person", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.0, y: 0.22, w: 1.0, h: 0.22)),
                        PuzzleSlot(slotID: "tea-bottom", expectedRadicalID: "tree", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.0, y: 0.44, w: 1.0, h: 0.56))
                    ]
                ),
                explanationEnglish: "茶 layers grass, person, and tree to build the kanji for tea.",
                slotGlyphScaleOverrides: [
                    "tea-top": 1.36,
                    "tea-middle": 1.18,
                    "tea-bottom": 1.4
                ],
                slotGlyphStretchXOverrides: [
                    "tea-top": 4.6,
                    "tea-middle": 4,
                    "tea-bottom": 1.22
                ]
            ),
            KanjiEntry(
                id: "medicine",
                kanji: "薬",
                meaningEnglish: "Medicine",
                promptEnglish: "Grass or herbs that bring comfort suggest medicine that helps the body feel better.",
                requiredComponents: ["grass-crown", "comfort"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "medicine-top", expectedRadicalID: "grass-crown", shapeType: .topWide, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 1.0, h: 0.22)),
                        PuzzleSlot(slotID: "medicine-bottom", expectedRadicalID: "comfort", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.0, y: 0.22, w: 1.0, h: 0.78))
                    ]
                ),
                explanationEnglish: "薬 combines grass with comfort to suggest healing herbs and medicine.",
                slotGlyphScaleOverrides: [
                    "medicine-top": 1.36,
                    "medicine-bottom": 1.5
                ],
                slotGlyphStretchXOverrides: [
                    "medicine-top": 4.6
                ]
            ),
            KanjiEntry(
                id: "leaf",
                kanji: "葉",
                meaningEnglish: "Leaf",
                promptEnglish: "A leaf belongs to grass and plant life, connecting the natural world to a tree.",
                requiredComponents: ["grass-crown", "world", "tree"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "leaf-top", expectedRadicalID: "grass-crown", shapeType: .topWide, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 1.0, h: 0.20)),
                        PuzzleSlot(slotID: "leaf-middle", expectedRadicalID: "world", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.0, y: 0.20, w: 1.0, h: 0.24)),
                        PuzzleSlot(slotID: "leaf-bottom", expectedRadicalID: "tree", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.0, y: 0.44, w: 1.0, h: 0.56))
                    ]
                ),
                explanationEnglish: "葉 uses grass above world and tree to form the kanji for leaf.",
                slotGlyphScaleOverrides: [
                    "leaf-top": 1.36,
                    "leaf-middle": 1.18,
                    "leaf-bottom": 1.4
                ],
                slotGlyphStretchXOverrides: [
                    "leaf-top": 4.6,
                    "leaf-middle": 4,
                    "leaf-bottom": 1.22
                ]
            ),
            KanjiEntry(
                id: "cultivated-field",
                kanji: "畑",
                meaningEnglish: "Cultivated Field",
                promptEnglish: "A field cleared by fire becomes farmland ready for growing crops.",
                requiredComponents: ["fire", "field"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "field-fire", expectedRadicalID: "fire", shapeType: .leftTall, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 0.42, h: 1.0)),
                        PuzzleSlot(slotID: "field-plot", expectedRadicalID: "field", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.42, y: 0.0, w: 0.58, h: 1.0))
                    ]
                ),
                explanationEnglish: "畑 joins fire and field to describe cultivated land cleared by burning.",
                slotGlyphScaleOverrides: [
                    "field-fire": 1.1,
                    "field-plot": 1.1
                ],
                slotGlyphStretchYOverrides: [
                    "field-fire": 1.7,
                    "field-plot": 1.5
                ]
            ),
            KanjiEntry(
                id: "autumn",
                kanji: "秋",
                meaningEnglish: "Autumn",
                promptEnglish: "Grain at harvest time and the image of fire together evoke the season of autumn.",
                requiredComponents: ["grain-left", "fire"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "autumn-left", expectedRadicalID: "grain-left", shapeType: .leftTall, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 0.40, h: 1.0)),
                        PuzzleSlot(slotID: "autumn-right", expectedRadicalID: "fire", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.40, y: 0.0, w: 0.60, h: 1.0))
                    ]
                ),
                explanationEnglish: "秋 combines grain and fire to evoke harvest season and autumn.",
                slotGlyphScaleOverrides: [
                    "autumn-left": 1.06,
                    "autumn-right": 1.18
                ],
                slotGlyphStretchYOverrides: [
                    "autumn-left": 1.7,
                    "autumn-right": 1.5
                ]
            ),
            KanjiEntry(
                id: "alcohol",
                kanji: "酒",
                meaningEnglish: "Alcohol",
                promptEnglish: "Water kept in a wine jar suggests alcohol or sake.",
                requiredComponents: ["water-left", "wine-jar"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "alcohol-left", expectedRadicalID: "water-left", shapeType: .leftTall, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 0.28, h: 1.0)),
                        PuzzleSlot(slotID: "alcohol-right", expectedRadicalID: "wine-jar", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.28, y: 0.0, w: 0.72, h: 1.0))
                    ]
                ),
                explanationEnglish: "酒 uses water on the left and a wine jar on the right to mean alcohol or sake.",
                slotGlyphScaleOverrides: [
                    "alcohol-left": 1.94,
                    "alcohol-right": 1.1
                ],
                slotGlyphStretchYOverrides: [
                    "alcohol-left": 1.68,
                    "alcohol-right": 1.22
                ]
            ),
            KanjiEntry(
                id: "peace",
                kanji: "安",
                meaningEnglish: "Peace",
                promptEnglish: "Under a roof, a woman represents calm, safety, and peace in the home.",
                requiredComponents: ["roof", "woman"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "peace-top", expectedRadicalID: "roof", shapeType: .topWide, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 1.0, h: 0.24)),
                        PuzzleSlot(slotID: "peace-bottom", expectedRadicalID: "woman", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.0, y: 0.24, w: 1.0, h: 0.76))
                    ]
                ),
                explanationEnglish: "安 places a roof over woman to express peace, ease, or safety.",
                slotGlyphScaleOverrides: [
                    "peace-top": 1.28,
                    "peace-bottom": 1.18
                ],
                slotGlyphStretchXOverrides: [
                    "peace-top": 4.6
                ]
            ),
            KanjiEntry(
                id: "guest",
                kanji: "客",
                meaningEnglish: "Guest",
                promptEnglish: "Someone who comes beneath your roof as one of many people becomes a guest.",
                requiredComponents: ["roof", "each"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "guest-top", expectedRadicalID: "roof", shapeType: .topWide, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 1.0, h: 0.24)),
                        PuzzleSlot(slotID: "guest-bottom", expectedRadicalID: "each", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.0, y: 0.24, w: 1.0, h: 0.76))
                    ]
                ),
                explanationEnglish: "客 uses roof over each to suggest someone arriving under your roof: a guest.",
                slotGlyphScaleOverrides: [
                    "guest-top": 1.28,
                    "guest-bottom": 1.14
                ],
                slotGlyphStretchXOverrides: [
                    "guest-top": 4.6
                ]
            ),
            KanjiEntry(
                id: "forget",
                kanji: "忘",
                meaningEnglish: "Forget",
                promptEnglish: "When the heart loses something, it slips away and is forgotten.",
                requiredComponents: ["lose", "heart"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "forget-top", expectedRadicalID: "lose", shapeType: .topWide, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 1.0, h: 0.5)),
                        PuzzleSlot(slotID: "forget-bottom", expectedRadicalID: "heart", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.0, y: 0.5, w: 1.0, h: 0.5))
                    ]
                ),
                explanationEnglish: "忘 combines lose above heart to express forgetting.",
                slotGlyphScaleOverrides: [
                    "forget-top": 1.2,
                    "forget-bottom": 1.2
                ],
                slotGlyphStretchXOverrides: [
                    "forget-top": 2.5,
                    "forget-bottom": 2.5
                ]
            ),
            KanjiEntry(
                id: "talk",
                kanji: "話",
                meaningEnglish: "Talk",
                promptEnglish: "When you talk, you use your tongue to deliver speech.",
                requiredComponents: ["speech", "tongue"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "talk-left", expectedRadicalID: "speech", shapeType: .leftTall, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 0.34, h: 1.0)),
                        PuzzleSlot(slotID: "talk-right", expectedRadicalID: "tongue", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.34, y: 0.0, w: 0.66, h: 1.0))
                    ]
                ),
                explanationEnglish: "話 pairs speech with tongue to express talking or spoken words.",
                slotGlyphScaleOverrides: [
                    "talk-left": 1.1,
                    "talk-right": 1.1
                ],
                slotGlyphStretchYOverrides: [
                    "talk-left": 2.4,
                    "talk-right": 1.5
                ]
            ),
            KanjiEntry(
                id: "walk",
                kanji: "歩",
                meaningEnglish: "Walk",
                promptEnglish: "Walking is made of many small little steps, each one stopping and moving again with the foot.",
                requiredComponents: ["stop", "little"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "walk-top", expectedRadicalID: "stop", shapeType: .topWide, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 1.0, h: 0.5)),
                        PuzzleSlot(slotID: "walk-bottom", expectedRadicalID: "little", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.0, y: 0.5, w: 1.0, h: 0.5))
                    ]
                ),
                explanationEnglish: "歩 combines stop and little to suggest small steps and walking.",
                slotGlyphScaleOverrides: [
                    "walk-top": 1.2,
                    "walk-bottom": 1.2
                ],
                slotGlyphStretchXOverrides: [
                    "walk-top": 2.5,
                    "walk-bottom": 2.5
                ]
            ),
            KanjiEntry(
                id: "advance",
                kanji: "進",
                meaningEnglish: "Advance",
                promptEnglish: "A bird moving along a path gives the feeling of going forward and advancing.",
                requiredComponents: ["walk-left-bottom", "bird"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "advance-left", expectedRadicalID: "walk-left-bottom", shapeType: .leftBottom, normalizedFrame: NormalizedRect(x: 0.0, y: 0, w: 1.0, h: 1)),
                        PuzzleSlot(slotID: "advance-right", expectedRadicalID: "bird", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.30, y: 0.0, w: 0.6, h: 0.76))
                    ]
                ),
                explanationEnglish: "進 combines a path component with bird to suggest moving forward or advancing.",
                slotGlyphScaleOverrides: [
                    "advance-left": 0.9,
                    "advance-right": 1.08
                ],
                slotGlyphStretchXOverrides: [
                    "advance-left": 1.2
                ],
                slotGlyphStretchYOverrides: [
                    "advance-left": 1.1,
                    "advance-right": 1.4
                ]
            ),
            KanjiEntry(
                id: "transport",
                kanji: "運",
                meaningEnglish: "Transport",
                promptEnglish: "Moving an army or a heavy load along a path suggests transport.",
                requiredComponents: ["walk-left-bottom", "army"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "transport-left", expectedRadicalID: "walk-left-bottom", shapeType: .leftBottom, normalizedFrame: NormalizedRect(x: 0.0, y: 0, w: 1.0, h: 1)),
                        PuzzleSlot(slotID: "transport-right", expectedRadicalID: "army", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.30, y: 0.0, w: 0.6, h: 0.76))
                    ]
                ),
                explanationEnglish: "運 combines path with army to express carrying, moving, or transporting.",
                slotGlyphScaleOverrides: [
                    "transport-left": 0.9,
                    "transport-right": 1.04
                ],
                slotGlyphStretchXOverrides: [
                    "transport-left": 1.2
                ],
                slotGlyphStretchYOverrides: [
                    "transport-left": 1.1,
                    "transport-right": 1.25
                ]
            ),
            KanjiEntry(
                id: "chirp",
                kanji: "鳴",
                meaningEnglish: "Chirp",
                promptEnglish: "A bird using its mouth makes a chirping sound.",
                requiredComponents: ["mouth", "bird-full"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "chirp-left", expectedRadicalID: "mouth", shapeType: .leftTall, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 0.34, h: 1.0)),
                        PuzzleSlot(slotID: "chirp-right", expectedRadicalID: "bird-full", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.34, y: 0.0, w: 0.66, h: 1.0))
                    ]
                ),
                explanationEnglish: "鳴 combines mouth and bird to express chirping, crying out, or making a sound.",
                slotGlyphScaleOverrides: [
                    "chirp-left": 1.18,
                    "chirp-right": 1.04
                ],
                slotGlyphStretchYOverrides: [
                    "chirp-left": 1.3,
                    "chirp-right": 1.18
                ]
            ),
            KanjiEntry(
                id: "prosperity",
                kanji: "鑫",
                meaningEnglish: "Prosperity",
                promptEnglish: "When gold appears again and again, it creates the image of wealth and prosperity.",
                requiredComponents: ["gold", "gold", "gold"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "prosperity-top", expectedRadicalID: "gold", shapeType: .topWide, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 1.0, h: 0.5)),
                        PuzzleSlot(slotID: "prosperity-bottom-left", expectedRadicalID: "gold", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.0, y: 0.5, w: 0.5, h: 0.5)),
                        PuzzleSlot(slotID: "prosperity-bottom-right", expectedRadicalID: "gold", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.5, y: 0.5, w: 0.5, h: 0.5))
                    ]
                ),
                explanationEnglish: "鑫 stacks three gold components to suggest abundance, prosperity, and wealth.",
                slotGlyphScaleOverrides: [
                    "prosperity-top": 1.22,
                    "prosperity-bottom-left": 1.18,
                    "prosperity-bottom-right": 1.18
                ]
            ),
            KanjiEntry(
                id: "roar",
                kanji: "轟",
                meaningEnglish: "Roar",
                promptEnglish: "Many cars or vehicles rumbling together create a roaring sound.",
                requiredComponents: ["car", "car", "car"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "roar-top", expectedRadicalID: "car", shapeType: .topWide, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 1.0, h: 0.5)),
                        PuzzleSlot(slotID: "roar-bottom-left", expectedRadicalID: "car", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.0, y: 0.5, w: 0.5, h: 0.5)),
                        PuzzleSlot(slotID: "roar-bottom-right", expectedRadicalID: "car", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.5, y: 0.5, w: 0.5, h: 0.5))
                    ]
                ),
                explanationEnglish: "轟 uses three car components to express a deep rumbling roar.",
                slotGlyphScaleOverrides: [
                    "roar-top": 1.14,
                    "roar-bottom-left": 1.12,
                    "roar-bottom-right": 1.12
                ]
            ),
            KanjiEntry(
                id: "discipline",
                kanji: "懲",
                meaningEnglish: "Discipline",
                promptEnglish: "True discipline takes many parts: measured steps, firm authority like a king, the force of a corrective strike, and a steady heart.",
                requiredComponents: ["step-left", "mountain", "king", "strike", "heart"],
                layout: PuzzleLayout(
                    slots: [
                        PuzzleSlot(slotID: "discipline-left", expectedRadicalID: "step-left", shapeType: .leftTall, normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, w: 0.24, h: 0.74)),
                        PuzzleSlot(slotID: "discipline-mountain", expectedRadicalID: "mountain", shapeType: .topWide, normalizedFrame: NormalizedRect(x: 0.24, y: 0.0, w: 0.50, h: 0.26)),
                        PuzzleSlot(slotID: "discipline-king", expectedRadicalID: "king", shapeType: .normalRect, normalizedFrame: NormalizedRect(x: 0.24, y: 0.26, w: 0.50, h: 0.48)),
                        PuzzleSlot(slotID: "discipline-strike", expectedRadicalID: "strike", shapeType: .leftTall, normalizedFrame: NormalizedRect(x: 0.74, y: 0, w: 0.26, h: 0.74)),
                        PuzzleSlot(slotID: "discipline-heart", expectedRadicalID: "heart", shapeType: .topWide, normalizedFrame: NormalizedRect(x: 0.0, y: 0.74, w: 1.0, h: 0.26))
                    ]
                ),
                explanationEnglish: "The structure is command/sign above and heart below. This puzzle uses step-left, mountain, king, and strike on top, then adds heart across the bottom.",
                slotGlyphScaleOverrides: [
                    "discipline-left": 1.42,
                    "discipline-mountain": 1.26,
                    "discipline-king": 1.35,
                    "discipline-strike": 1.36,
                    "discipline-heart": 1.18
                ],
                slotGlyphStretchXOverrides: [
                    "discipline-heart": 5.0,
                    "discipline-mountain": 2.0,
                    "discipline-strike": 0.8,
                ],
                slotGlyphStretchYOverrides: [
                    "discipline-heart": 0.92,
                    "discipline-left": 2.0,
                    "discipline-strike": 2.0,
                ],
                isAvailableInEasyMode: false
            )
        ]
    }

    func radical(for id: String) -> RadicalEntry? {
        radicals.first { $0.id == id }
    }

    func kanjiEntry(for id: String) -> KanjiEntry? {
        kanjiEntries.first { $0.id == id }
    }

    func supportsVisionImpairedMode(_ radical: RadicalEntry) -> Bool {
        !visionImpairedExcludedDisplayPositions.contains(radical.displayPosition)
    }

    func supportsDifficultyProfile(_ profile: KanjiDifficultyProfile, for entry: KanjiEntry) -> Bool {
        switch profile {
        case .standard:
            return true
        case .easyMode:
            return entry.isAvailableInEasyMode
        }
    }

    func supportsVisionImpairedMode(_ entry: KanjiEntry) -> Bool {
        let usesExcludedComponentPosition = entry.requiredComponents.contains { componentID in
            guard let radical = radical(for: componentID) else { return false }
            return !supportsVisionImpairedMode(radical)
        }

        let usesExcludedShape = entry.layout.slots.contains { $0.shapeType == .frameUShape }

        return !usesExcludedComponentPosition && !usesExcludedShape
    }
}

#if DEBUG
private struct DataStoreGridTuningPreview: View {
    @State private var selectedEntryID: String = ""
    private let dataStore = DataStore()

    private var selectedEntry: KanjiEntry? {
        dataStore.kanjiEntries.first { $0.id == selectedEntryID }
    }

    private var selectedEntryTitle: String {
        if let selectedEntry {
            return "\(selectedEntry.kanji) \(selectedEntry.meaningEnglish)"
        }

        return "Select Kanji"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !dataStore.kanjiEntries.isEmpty {
                Menu {
                    ForEach(dataStore.kanjiEntries) { entry in
                        Button {
                            selectedEntryID = entry.id
                        } label: {
                            Label("\(entry.kanji) \(entry.meaningEnglish)", systemImage: entry.id == selectedEntryID ? "checkmark.circle.fill" : "circle")
                        }
                    }
                } label: {
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Preview Kanji")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            Text(selectedEntryTitle)
                                .font(.headline)
                                .foregroundStyle(.primary)
                        }

                        Spacer()

                        Image(systemName: "chevron.up.chevron.down")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .padding(10)
                            .background(.regularMaterial, in: Circle())
                    }
                    .padding(14)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                    )
                }
                .buttonStyle(.plain)
            }

            if let selectedEntry {
                Text("Edit `normalizedFrame` and `slotGlyphScaleOverrides` in DataStore and watch this preview.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                ZStack {
                    PuzzleGridView(
                        slots: selectedEntry.layout.slots,
                        slotGlyphScaleOverrides: selectedEntry.slotGlyphScaleOverrides,
                        slotGlyphStretchXOverrides: selectedEntry.slotGlyphStretchXOverrides,
                        slotGlyphStretchYOverrides: selectedEntry.slotGlyphStretchYOverrides,
                        placedTiles: filledTiles(for: selectedEntry),
                        radicalLookup: dataStore.radical(for:),
                        selectedRadicalID: nil,
                        hoveredSlotID: nil,
                        draggingRadicalID: nil,
                        feedbackSlotID: nil,
                        slotFeedback: nil,
                        coordinateSpaceName: "DataStoreGridTuningPreview",
                        onUpdateGridFrame: { _ in },
                        onUpdateSlotFrames: { _ in },
                        onTapSlot: { _ in },
                        onDoubleTapSlot: { _ in }
                    )
                    SlotLabelOverlayView(
                        slots: selectedEntry.layout.slots,
                        slotGlyphScaleOverrides: selectedEntry.slotGlyphScaleOverrides
                    )
                }
                .coordinateSpace(name: "DataStoreGridTuningPreview")
                .frame(width: 560, height: 560)

                ScrollView {
                    VStack(alignment: .leading, spacing: 6) {
                        ForEach(selectedEntry.layout.slots) { slot in
                            let frame = slot.normalizedFrame
                            let scale = selectedEntry.slotGlyphScaleOverrides[slot.id] ?? 1.0
                            let stretchX = selectedEntry.slotGlyphStretchXOverrides[slot.id] ?? 1.0
                            let stretchY = selectedEntry.slotGlyphStretchYOverrides[slot.id] ?? 1.0
                            let frameUThickness = slot.frameUThicknessRatio ?? 0.16
                            let frameUSideThickness = slot.frameUSideThicknessRatio ?? frameUThickness
                            let frameUTopThickness = slot.frameUTopThicknessRatio ?? frameUThickness
                            Text(
                                "\(slot.id): shape=\(slot.shapeType.rawValue) frame=(x:\(format(frame.x)), y:\(format(frame.y)), w:\(format(frame.w)), h:\(format(frame.h))) scale=\(format(scale)) stretch=(x:\(format(stretchX)), y:\(format(stretchY))) frameUThickness=\(format(frameUThickness)) side=\(format(frameUSideThickness)) top=\(format(frameUTopThickness))"
                            )
                            .font(.caption.monospaced())
                        }
                    }
                }
                .frame(maxHeight: 180)
            } else {
                Text("No Kanji entries")
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .onAppear {
            if selectedEntryID.isEmpty {
                selectedEntryID = dataStore.kanjiEntries.first?.id ?? ""
            }
        }
    }

    private func filledTiles(for entry: KanjiEntry) -> [String: String] {
        Dictionary(uniqueKeysWithValues: entry.layout.slots.map { ($0.id, $0.expectedRadicalID) })
    }

    private func format(_ value: Double) -> String {
        String(format: "%.2f", value)
    }
}

private struct SlotLabelOverlayView: View {
    let slots: [PuzzleSlot]
    let slotGlyphScaleOverrides: [String: Double]

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .topLeading) {
                ForEach(slots) { slot in
                    let frame = CGRect(
                        x: slot.normalizedFrame.x * proxy.size.width,
                        y: slot.normalizedFrame.y * proxy.size.height,
                        width: slot.normalizedFrame.w * proxy.size.width,
                        height: slot.normalizedFrame.h * proxy.size.height
                    )
                    let scale = slotGlyphScaleOverrides[slot.id] ?? 1.0

                    Text("\(slot.id)\n×\(String(format: "%.2f", scale))")
                        .font(.caption2.monospaced())
                        .padding(4)
                        .background(.black.opacity(0.6), in: RoundedRectangle(cornerRadius: 6))
                        .foregroundStyle(.white)
                        .frame(width: frame.width, height: frame.height, alignment: .topLeading)
                        .offset(x: frame.minX, y: frame.minY)
                }
            }
        }
        .allowsHitTesting(false)
    }
}

#Preview("DataStore Grid Tuning") {
    DataStoreGridTuningPreview()
}
#endif
