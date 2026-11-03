import Foundation

/// A thing a riddle can be about (#551): an answer, or a decoy for a riddle of the same kind. Most are
/// pictures from `GamePictures`, so levels 1-6 can show them; the rest are words only (levels 7-10),
/// named under `riddle.thing.<slug>` in `Localizable.xcstrings`.
nonisolated struct RiddleAnswer: Hashable {
    /// The broad kind decoys share with the answer: a riddle about an animal offers other animals.
    enum Kind: CaseIterable {
        case animal, fruit, food, home, nature, travel, music
    }

    let slug: String
    let kind: Kind
    /// Its picture, or nil for a word-only answer.
    let picture: GamePicture?

    /// The name a tile shows and VoiceOver reads, in the app's language.
    var nameKey: String { picture?.nameKey ?? "riddle.thing.\(slug)" }
}

/// Every answer and decoy, in one place for both languages: the Spanish and English riddles are
/// written separately, but a pear is a pear in both, and its decoys are the same kind.
nonisolated enum RiddleAnswers {
    /// Pictures from the shared bank, by kind. The colours and the wine glass are left out.
    private static let pictured: [(RiddleAnswer.Kind, [String])] = [
        (.animal, ["dog", "cat", "lion", "frog", "turtle", "butterfly", "elephant", "bee", "ladybug"]),
        (.fruit, ["apple", "banana", "grapes", "orange", "strawberry", "watermelon", "peach", "lemon", "pear"]),
        (.food, ["bread", "cheese", "honey", "cake", "chocolate", "egg", "coffee", "olives", "croissant"]),
        (
            .home,
            [
                "clock", "key", "house", "chair", "umbrella", "book", "lamp", "telephone", "sofa", "picture_frame",
                "yarn", "teapot", "suitcase", "map",
            ]
        ),
        (
            .nature,
            ["moon", "star", "sunflower", "rose", "tulip", "tree", "pine", "cactus", "mountain", "beach", "potted_plant"]
        ),
        (.travel, ["car", "bus", "airplane", "rocket", "bicycle", "train", "sailboat", "helicopter"]),
        (.music, ["guitar", "violin", "trumpet", "piano", "radio", "accordion"]),
    ]

    /// Answers the bank has no picture of: shown as words, so only levels 7-10 ask for them.
    private static let words: [(RiddleAnswer.Kind, [String])] = [
        (.animal, ["snail", "rooster", "donkey", "cow", "horse", "owl"]),
        (.fruit, ["avocado", "pineapple"]),
        (.food, ["corn", "tortilla", "onion", "chili", "potato"]),
        (
            .home,
            [
                "hat", "candle", "scissors", "needle", "mirror", "broom", "letter", "pencil", "comb", "towel", "bottle",
                "button", "spoon", "coin", "glove", "stamp", "shoe",
            ]
        ),
        (.nature, ["sun", "rainbow", "shadow", "river", "cloud", "snow", "wind"]),
        (.music, ["bell", "drum"]),
    ]

    static let all: [RiddleAnswer] =
        pictured.flatMap { kind, slugs in
            slugs.map { RiddleAnswer(slug: $0, kind: kind, picture: GamePictures.named($0)) }
        }
        + words.flatMap { kind, slugs in slugs.map { RiddleAnswer(slug: $0, kind: kind, picture: nil) } }

    private static let bySlug = Dictionary(uniqueKeysWithValues: all.map { ($0.slug, $0) })

    /// The answer for a slug, or nil for a typo (the catalog test checks every riddle's).
    static func named(_ slug: String) -> RiddleAnswer? { bySlug[slug] }
}

/// One riddle (#551): two to four short lines, the answer, one clue line, and its tier (1 very easy,
/// 5 harder). `avoid` names things of the same kind that the lines would also fit, so they are never
/// offered as decoys. The text is written in its own language, never translated (see `Riddles`).
nonisolated struct Riddle: Hashable {
    let id: String
    let tier: Int
    let answer: RiddleAnswer
    let lines: [String]
    let clue: String
    let avoid: [String]
}

/// One round: the riddle and the answers offered, its own among them once.
nonisolated struct RiddleRound: Equatable {
    let riddle: Riddle
    let choices: [RiddleAnswer]
}

/// Which riddles a game shows and what each offers (#551). Pure and seeded: the view passes the
/// generator and the defaults that remember which riddles were solved.
nonisolated enum RiddleDeck {
    static let roundsPerGame = 5
    static let seenKey = "riddles.seen"

    /// Answers offered per level: 3 pictures at 1-4, 4 pictures at 5-6, 4 words at 7-10.
    static let choicesByLevel = [3, 3, 3, 3, 4, 4, 4, 4, 4, 4]
    /// The riddle tier per level: very easy two-liners at 1-2, up to harder four-liners at 9-10.
    static let tierByLevel = [1, 1, 2, 2, 3, 3, 4, 4, 5, 5]
    /// Tiers whose answers are shown as pictures with names; every answer in them needs a picture.
    static let tiersWithPictures = 1...3

    static func choiceCount(for difficulty: Difficulty) -> Int { difficulty.values(choicesByLevel) }
    static func tier(for difficulty: Difficulty) -> Int { difficulty.values(tierByLevel) }
    static func showsPictures(_ difficulty: Difficulty) -> Bool { tiersWithPictures.contains(tier(for: difficulty)) }

    /// The book in the app's language: Spanish riddles for Spanish, English ones otherwise. "Follow the
    /// device" reads the language the app's strings are shown in.
    static func riddles(for language: AppLanguage) -> [Riddle] {
        switch language {
        case .spanish: Riddles.spanish
        case .english: Riddles.english
        case .system: Bundle.main.preferredLocalizations.first == "es" ? Riddles.spanish : Riddles.english
        }
    }

    /// What VoiceOver reads for a riddle: its lines as one passage.
    static func spoken(_ riddle: Riddle) -> String { riddle.lines.joined(separator: " ") }

    /// Every thing a riddle may offer as a decoy: its kind, not itself or anything it avoids, and only
    /// pictures when the level shows pictures.
    static func decoys(for riddle: Riddle, pictures: Bool) -> [RiddleAnswer] {
        RiddleAnswers.all.filter {
            $0.kind == riddle.answer.kind && $0 != riddle.answer && !riddle.avoid.contains($0.slug)
                && (!pictures || $0.picture != nil)
        }
    }

    /// Marks a riddle solved, so it doesn't come back until the rest of its tier has been seen. Only
    /// solved ones: a game left early doesn't use up riddles he never reached.
    static func markSeen(_ riddle: Riddle, defaults: UserDefaults) {
        var seen = defaults.stringArray(forKey: seenKey) ?? []
        if !seen.contains(riddle.id) { seen.append(riddle.id) }
        defaults.set(seen, forKey: seenKey)
    }

    /// Five riddles of the level's tier he hasn't solved yet, each with its answer and decoys of the
    /// same kind, shuffled. When fewer than five are left unseen, the tier starts over.
    static func deal<G: RandomNumberGenerator>(
        difficulty: Difficulty, from pool: [Riddle], defaults: UserDefaults, using generator: inout G
    ) -> [RiddleRound] {
        let tierPool = pool.filter { $0.tier == tier(for: difficulty) }
        var seen = Set(defaults.stringArray(forKey: seenKey) ?? [])
        if tierPool.filter({ !seen.contains($0.id) }).count < roundsPerGame {
            seen.subtract(tierPool.map(\.id))
            defaults.set(Array(seen).sorted(), forKey: seenKey)
        }
        let picked = tierPool.filter { !seen.contains($0.id) }.shuffled(using: &generator).prefix(roundsPerGame)
        let others = choiceCount(for: difficulty) - 1
        let pictures = showsPictures(difficulty)
        return picked.map { riddle in
            let decoys = decoys(for: riddle, pictures: pictures).shuffled(using: &generator).prefix(others)
            return RiddleRound(riddle: riddle, choices: ([riddle.answer] + decoys).shuffled(using: &generator))
        }
    }
}

/// One game of riddles (#551): the rounds, the round on screen, what a pick or a clue does, and the
/// counts the level staircase reads. The view shows this state and forwards taps.
nonisolated struct RiddleRun {
    enum Pick: Equatable {
        /// The answer: the round is solved and waits for Next.
        case right
        /// Another thing: it fades, a miss is counted, and the round stays open.
        case faded
    }

    let rounds: [RiddleRound]
    private(set) var progress: RoundProgress
    private(set) var faded: Set<RiddleAnswer> = []
    private(set) var clueShown = false
    private(set) var solved = false
    /// Rounds answered on the first try, without a miss or a clue.
    private(set) var correct = 0
    /// Every pick and every clue: a clue counts as a try.
    private(set) var attempts = 0
    private(set) var misses = 0

    init(rounds: [RiddleRound]) {
        self.rounds = rounds
        progress = RoundProgress(totalRounds: rounds.count)
    }

    var round: RiddleRound? {
        rounds.indices.contains(progress.completedRounds) ? rounds[progress.completedRounds] : nil
    }

    var isFinished: Bool { progress.isFinished }

    mutating func pick(_ answer: RiddleAnswer) -> Pick {
        guard let round, !solved else { return .right }
        attempts += 1
        guard answer == round.riddle.answer else {
            faded.insert(answer)
            misses += 1
            return .faded
        }
        if faded.isEmpty, !clueShown { correct += 1 }
        solved = true
        return .right
    }

    /// "Give me a clue": shows the riddle's clue line once, and counts as a try.
    mutating func showClue() {
        guard !clueShown, !solved, round != nil else { return }
        clueShown = true
        attempts += 1
    }

    /// Next: the following riddle, with nothing faded and no clue.
    mutating func next() {
        guard solved else { return }
        faded = []
        clueShown = false
        solved = false
        progress.completeRound()
    }
}

/// The two riddle books (#551), `Riddles.spanish` and `Riddles.english`, each in its own file. They are
/// written separately, not translated: traditional riddles told in our own words, kind and clean. The
/// text lives in Swift rather than `Localizable.xcstrings` because each book has its own riddles and
/// answers, so a key would mean a different riddle in each language.
nonisolated enum Riddles {
    /// Numbers a book's riddles by their place (`es.07`), so a solved riddle is remembered by its id:
    /// add new riddles at the end. An unknown answer stays visible to the catalog test as a word.
    static func book(_ language: String, _ entries: [Riddle.Entry]) -> [Riddle] {
        entries.enumerated().map { index, entry in
            Riddle(
                id: String(format: "%@.%02d", language, index + 1), tier: entry.tier,
                answer: RiddleAnswers.named(entry.answer) ?? RiddleAnswer(slug: entry.answer, kind: .home, picture: nil),
                lines: entry.lines, clue: entry.clue, avoid: entry.avoid)
        }
    }

    /// One riddle as a book writes it: tier, answer slug, lines, clue, and things it would also fit.
    static func r(_ tier: Int, _ answer: String, _ lines: [String], _ clue: String, avoid: [String] = []) -> Riddle.Entry {
        Riddle.Entry(tier: tier, answer: answer, lines: lines, clue: clue, avoid: avoid)
    }
}

extension Riddle {
    /// A riddle before it is numbered and its answer looked up.
    nonisolated struct Entry {
        let tier: Int
        let answer: String
        let lines: [String]
        let clue: String
        let avoid: [String]
    }
}
