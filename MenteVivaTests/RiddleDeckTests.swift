import XCTest

@testable import MenteViva

/// #551: Riddles deals 5 riddles a game, each with its answer once among decoys of the same kind,
/// a clue on request, and a miss that fades the tile and keeps the round open.
final class RiddleDeckTests: XCTestCase {
    /// Deterministic generator so the property runs never flake.
    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
    }

    private var defaults: UserDefaults!
    private let books: [(language: String, riddles: [Riddle])] = [("es", Riddles.spanish), ("en", Riddles.english)]

    override func setUp() {
        defaults = UserDefaults(suiteName: "RiddleDeckTests")!
        defaults.removePersistentDomain(forName: "RiddleDeckTests")
    }

    private func deal(_ level: Int = 4, pool: [Riddle] = Riddles.spanish, seed: UInt64 = 1) -> [RiddleRound] {
        var generator = SeededGenerator(state: seed)
        return RiddleDeck.deal(difficulty: Difficulty(level: level), from: pool, defaults: defaults, using: &generator)
    }

    // MARK: - Acceptance

    func testGivenAnySeedWhenDealtThenTheAnswerIsAmongTheChoicesOnceAndTheDecoysAreDistinctAndOfItsKind() {
        for book in books {
            for level in 1...10 {
                for seed in UInt64(1)...25 {
                    defaults.removePersistentDomain(forName: "RiddleDeckTests")
                    let rounds = deal(level, pool: book.riddles, seed: seed)
                    XCTAssertEqual(rounds.count, RiddleDeck.roundsPerGame)
                    for round in rounds {
                        let answer = round.riddle.answer
                        XCTAssertEqual(round.choices.filter { $0 == answer }.count, 1, "\(book.language) \(answer.slug)")
                        XCTAssertEqual(Set(round.choices).count, round.choices.count)
                        XCTAssertEqual(round.choices.count, RiddleDeck.choiceCount(for: Difficulty(level: level)))
                        for decoy in round.choices where decoy != answer {
                            XCTAssertEqual(decoy.kind, answer.kind, "\(answer.slug) offered \(decoy.slug)")
                            XCTAssertFalse(round.riddle.avoid.contains(decoy.slug), "\(answer.slug) offered \(decoy.slug)")
                        }
                    }
                }
            }
        }
    }

    func testGivenAWrongPickWhenPickedThenAMissIsCountedTheTileFadesAndTheRoundStaysOpen() throws {
        var run = RiddleRun(rounds: deal())
        let round = try XCTUnwrap(run.round)
        let wrong = try XCTUnwrap(round.choices.first { $0 != round.riddle.answer })

        XCTAssertEqual(run.pick(wrong), .faded)

        XCTAssertEqual(run.misses, 1)
        XCTAssertEqual(run.attempts, 1)
        XCTAssertTrue(run.faded.contains(wrong))
        XCTAssertFalse(run.solved)
        XCTAssertEqual(run.round, round, "the round stays open")
    }

    func testGivenGiveMeAClueWhenAskedThenTheClueShowsAndCountsAsATry() throws {
        var run = RiddleRun(rounds: deal())
        XCTAssertFalse(run.clueShown)

        run.showClue()

        XCTAssertTrue(run.clueShown)
        XCTAssertEqual(run.attempts, 1)
        // A clue is help, so the right pick after it is not a first-try answer.
        XCTAssertEqual(run.pick(try XCTUnwrap(run.round).riddle.answer), .right)
        XCTAssertEqual(run.correct, 0)
        XCTAssertEqual(run.attempts, 2)
    }

    func testGivenTheSameSeedWhenDealtTwiceThenTheSameRiddlesInTheSameOrder() {
        for book in books {
            for level in [1, 5, 9] {
                let first = deal(level, pool: book.riddles, seed: 42)
                defaults.removePersistentDomain(forName: "RiddleDeckTests")
                XCTAssertEqual(deal(level, pool: book.riddles, seed: 42), first, "\(book.language) level \(level)")
            }
        }
    }

    /// The catalog test: every riddle in both languages has an answer from the catalogue, a clue, two
    /// to four lines and at least three decoys of its kind, drawn from pictures where its levels show them.
    func testGivenEveryRiddleInBothLanguagesWhenCheckedThenEachHasAnAnswerThreeSameKindDecoysAndAClue() {
        for book in books {
            XCTAssertGreaterThanOrEqual(book.riddles.count, 60, book.language)
            XCTAssertEqual(Set(book.riddles.map(\.id)).count, book.riddles.count, "\(book.language) ids are unique")
            for riddle in book.riddles {
                let name = "\(riddle.id) \(riddle.answer.slug)"
                XCTAssertNotNil(RiddleAnswers.named(riddle.answer.slug), "\(name) has no answer in the catalogue")
                XCTAssertTrue((1...5).contains(riddle.tier), name)
                XCTAssertTrue((2...4).contains(riddle.lines.count), name)
                XCTAssertFalse(riddle.lines.contains { $0.trimmingCharacters(in: .whitespaces).isEmpty }, name)
                XCTAssertFalse(riddle.clue.trimmingCharacters(in: .whitespaces).isEmpty, name)
                let pictured = RiddleDeck.tiersWithPictures.contains(riddle.tier)
                if pictured { XCTAssertNotNil(riddle.answer.picture, "\(name) shows pictures but has none") }
                let decoys = RiddleDeck.decoys(for: riddle, pictures: pictured)
                XCTAssertGreaterThanOrEqual(decoys.count, 3, name)
                for slug in riddle.avoid {
                    XCTAssertNotNil(RiddleAnswers.named(slug), "\(name) avoids unknown \(slug)")
                }
            }
            for tier in 1...5 {
                let inTier = book.riddles.filter { $0.tier == tier }
                XCTAssertGreaterThanOrEqual(inTier.count, RiddleDeck.roundsPerGame * 2, "\(book.language) tier \(tier)")
            }
            XCTAssertTrue(book.riddles.filter { $0.tier == 1 }.allSatisfy { $0.lines.count == 2 }, "very easy: 2 lines")
            XCTAssertTrue(book.riddles.filter { $0.tier == 5 }.allSatisfy { $0.lines.count == 4 }, "harder: 4 lines")
        }
    }

    func testGivenVoiceOverOnlyWhenEveryRoundIsAnsweredByItsSpokenNameThenTheGameFinishes() throws {
        for (language, riddles) in books {
            AppLanguage.apply(language, to: defaults)
            var run = RiddleRun(rounds: deal(7, pool: riddles))
            while let round = run.round {
                // Each tile reads its own name, so a listener can tell every choice apart.
                let names = round.choices.map { AppLanguage.localized($0.nameKey, defaults: defaults) }
                XCTAssertEqual(Set(names).count, names.count, "\(language) \(names)")
                XCTAssertFalse(names.contains { $0.isEmpty || $0 == round.riddle.answer.nameKey }, "\(names)")
                XCTAssertFalse(RiddleDeck.spoken(round.riddle).isEmpty)
                let heard = try XCTUnwrap(
                    round.choices.first {
                        AppLanguage.localized($0.nameKey, defaults: defaults)
                            == AppLanguage.localized(round.riddle.answer.nameKey, defaults: defaults)
                    })
                XCTAssertEqual(run.pick(heard), .right)
                run.next()
            }
            XCTAssertTrue(run.isFinished)
            XCTAssertEqual(run.correct, RiddleDeck.roundsPerGame)
        }
    }

    // MARK: - Levels and the deck

    func testGivenEachLevelWhenAskedThenThreePicturesThenFourPicturesThenFourWords() {
        let choices = (1...10).map { RiddleDeck.choiceCount(for: Difficulty(level: $0)) }
        XCTAssertEqual(choices, [3, 3, 3, 3, 4, 4, 4, 4, 4, 4])
        let pictures = (1...10).map { RiddleDeck.showsPictures(Difficulty(level: $0)) }
        XCTAssertEqual(pictures, [true, true, true, true, true, true, false, false, false, false])
        XCTAssertEqual((1...10).map { RiddleDeck.tier(for: Difficulty(level: $0)) }, [1, 1, 2, 2, 3, 3, 4, 4, 5, 5])
    }

    func testGivenALevelWhenDealtThenItsRiddlesComeFromItsOwnTierAndPictureLevelsOfferOnlyPictures() {
        for level in 1...10 {
            let difficulty = Difficulty(level: level)
            for round in deal(level, seed: UInt64(level)) {
                XCTAssertEqual(round.riddle.tier, RiddleDeck.tier(for: difficulty))
                if RiddleDeck.showsPictures(difficulty) {
                    XCTAssertTrue(round.choices.allSatisfy { $0.picture != nil }, "level \(level)")
                }
            }
        }
    }

    func testGivenRiddlesSolvedWhenDealtAgainThenNoneRepeatsUntilTheTierIsSeen() {
        let first = deal(1, seed: 3)
        for round in first { RiddleDeck.markSeen(round.riddle, defaults: defaults) }
        let second = deal(1, seed: 4)
        XCTAssertTrue(Set(first.map(\.riddle.id)).isDisjoint(with: second.map(\.riddle.id)))
        for round in second { RiddleDeck.markSeen(round.riddle, defaults: defaults) }
        // Fewer than a game's worth left unseen: the tier starts over rather than repeat inside a game.
        let third = deal(1, seed: 5)
        XCTAssertEqual(Set(third.map(\.riddle.id)).count, RiddleDeck.roundsPerGame)
    }

    func testGivenTheAppLanguageWhenChoosingABookThenSpanishGetsAdivinanzasAndEnglishGetsRiddles() {
        XCTAssertEqual(RiddleDeck.riddles(for: .spanish), Riddles.spanish)
        XCTAssertEqual(RiddleDeck.riddles(for: .english), Riddles.english)
        XCTAssertTrue(Riddles.spanish.allSatisfy { $0.id.hasPrefix("es.") })
        XCTAssertTrue(Riddles.english.allSatisfy { $0.id.hasPrefix("en.") })
    }

    func testGivenAPickAfterAMissWhenRightThenTheRoundIsSolvedButNotCountedFirstTry() throws {
        var run = RiddleRun(rounds: deal())
        let round = try XCTUnwrap(run.round)
        _ = run.pick(try XCTUnwrap(round.choices.first { $0 != round.riddle.answer }))
        XCTAssertEqual(run.pick(round.riddle.answer), .right)
        XCTAssertTrue(run.solved)
        XCTAssertEqual(run.correct, 0)
        run.next()
        XCTAssertFalse(run.solved)
        XCTAssertFalse(run.clueShown)
        XCTAssertTrue(run.faded.isEmpty)
        XCTAssertEqual(run.progress.completedRounds, 1)
    }

    // MARK: - Content

    /// Look-alike answers (#551 review): wherever one is the answer and another could be offered beside
    /// it, the riddle avoids it, because its lines would fit both.
    func testGivenLookAlikeAnswersWhenOneIsTheAnswerThenTheOthersAreAvoided() {
        let lookAlikes: [Set<String>] = [["airplane", "helicopter", "rocket"], ["letter", "book", "stamp"], ["moon", "star"]]
        for book in books {
            for riddle in book.riddles {
                guard let group = lookAlikes.first(where: { $0.contains(riddle.answer.slug) }) else { continue }
                let pictured = RiddleDeck.tiersWithPictures.contains(riddle.tier)
                // Everything of its kind the level could show, before `avoid` takes any out.
                let offerable = RiddleAnswers.all.filter {
                    $0.kind == riddle.answer.kind && (!pictured || $0.picture != nil)
                }.map(\.slug)
                for other in group.subtracting([riddle.answer.slug]) where offerable.contains(other) {
                    XCTAssertTrue(riddle.avoid.contains(other), "\(riddle.id) \(riddle.answer.slug) should avoid \(other)")
                }
            }
        }
    }

    /// A riddle never names another answer it could offer (#551 review): its lines and clue don't say the
    /// name of any decoy it may be dealt, in its own language.
    func testGivenEveryRiddleWhenReadThenItNamesNoOtherAnswerItCouldOffer() throws {
        for book in books {
            AppLanguage.apply(book.language, to: defaults)
            for riddle in book.riddles {
                let text = (riddle.lines + [riddle.clue]).joined(separator: " ").lowercased()
                let pictured = RiddleDeck.tiersWithPictures.contains(riddle.tier)
                for decoy in RiddleDeck.decoys(for: riddle, pictures: pictured) {
                    let name = AppLanguage.localized(decoy.nameKey, defaults: defaults).lowercased()
                    let pattern = "\\b" + NSRegularExpression.escapedPattern(for: name) + "(s|es)?\\b"
                    XCTAssertNil(
                        text.range(of: pattern, options: .regularExpression),
                        "\(riddle.id) \(riddle.answer.slug) names \(name)")
                }
            }
        }
    }

    func testGivenEveryWordOnlyAnswerWhenNamedThenItHasEnglishAndSpanish() {
        for answer in RiddleAnswers.all {
            for language in ["en", "es"] {
                AppLanguage.apply(language, to: defaults)
                let name = AppLanguage.localized(answer.nameKey, defaults: defaults)
                XCTAssertNotEqual(name, answer.nameKey, "\(answer.slug) [\(language)]")
            }
        }
    }

    /// Kind and clean (#551): nothing about illness, death or fear. Each book is checked in its own
    /// language, so "dientes" is not mistaken for " die".
    func testGivenEveryRiddleWhenReadThenItSaysNothingAboutIllnessDeathOrFear() {
        let banned = [
            "es": ["muert", "muere", "morir", "enferm", "miedo", "susto", "fantasma", "sangre", "llor", "dolor"],
            "en": ["death", "dead", " die", "sick", " ill ", "fear", "scare", "ghost", "blood", " pain", "cry"],
        ]
        for book in books {
            for riddle in book.riddles {
                let text = (riddle.lines + [riddle.clue]).joined(separator: " ").lowercased()
                for word in banned[book.language] ?? [] {
                    XCTAssertFalse(text.contains(word), "\(riddle.id) says \(word): \(text)")
                }
            }
        }
    }
}
