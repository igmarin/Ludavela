import XCTest

@testable import MenteViva

/// #548: Lotería's deal, with the generator passed in. A card is called, the player marks it on
/// their board ("tabla"), and "¡Lotería!" appears only once the level's pattern is complete.
final class LoteriaDealTests: XCTestCase {
    /// Deterministic generator so the property runs never flake.
    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
    }

    private func deal(level: Int, seed: UInt64) -> LoteriaDeal {
        var generator = SeededGenerator(state: seed)
        return LoteriaDeal.make(difficulty: Difficulty(level: level), using: &generator)
    }

    /// Calls cards until the called card is on the board and not yet marked.
    private func callUntilOnBoard(_ deal: inout LoteriaDeal) -> Int {
        while true {
            if let index = deal.board.firstIndex(of: deal.current), !deal.marked.contains(index) { return index }
            guard case .called = deal.next() else { preconditionFailure("deck ran out") }
        }
    }

    // MARK: Acceptance

    func testGivenAnySeedWhenDealtThenEveryBoardCardIsCalledOnceBeforeTheDeckEnds() {
        for level in 1...10 {
            for seed in 1...200 {
                let dealt = deal(level: level, seed: UInt64(seed))
                let side = LoteriaDeal.side(for: Difficulty(level: level))
                XCTAssertEqual(dealt.board.count, side * side, "level \(level) seed \(seed)")
                XCTAssertEqual(Set(dealt.board).count, dealt.board.count, "level \(level) seed \(seed)")
                // The calling order is the whole deck, each card once, so it holds every board card.
                XCTAssertEqual(dealt.calls.count, LoteriaDeal.deck.count, "level \(level) seed \(seed)")
                XCTAssertEqual(Set(dealt.calls), Set(LoteriaDeal.deck), "level \(level) seed \(seed)")
                XCTAssertTrue(Set(dealt.board).isSubset(of: Set(dealt.calls)), "level \(level) seed \(seed)")
            }
        }
    }

    func testGivenTheCalledCardWaitsOnTheBoardAtANameOnlyLevelWhenNextIsTappedTwiceThenHelpShowsOnceAndCountsAsATry() {
        var dealt = deal(level: 7, seed: 7)
        let index = callUntilOnBoard(&dealt)
        let called = dealt.current
        XCTAssertEqual(dealt.next(), .lookAgain)
        XCTAssertEqual(dealt.misses, 1)
        XCTAssertEqual(dealt.current, called, "the card stays until it is marked")
        XCTAssertEqual(dealt.next(), .showHelp(index))
        XCTAssertEqual(dealt.misses, 2)
        XCTAssertEqual(dealt.attempts, 2)
        XCTAssertEqual(dealt.next(), .lookAgain)
        XCTAssertEqual(dealt.attempts, 2, "the help is shown once for this called card")
    }

    func testGivenTheCalledCardWaitsOnTheBoardAtAPictureLevelWhenNextIsTappedTwiceThenOnlyTheFirstTryCounts() {
        var dealt = deal(level: 6, seed: 7)
        _ = callUntilOnBoard(&dealt)

        XCTAssertEqual(dealt.next(), .lookAgain)
        XCTAssertEqual(dealt.next(), .lookAgain)
        XCTAssertEqual(dealt.misses, 1)
        XCTAssertEqual(dealt.attempts, 1)
    }

    func testGivenATileThatWasNotCalledWhenTappedThenItIsNotMarkedAndAMissIsCounted() throws {
        var played = deal(level: 5, seed: 3)
        // Only the first card has been called, so any other picture is one not called yet.
        let index = try XCTUnwrap(played.board.indices.first { played.board[$0] != played.current })
        XCTAssertEqual(played.tap(index), .notCalled)
        XCTAssertFalse(played.marked.contains(index))
        XCTAssertEqual(played.misses, 1)
    }

    func testGivenTheCalledCardWhenItsTileIsTappedThenItIsMarkedOnceWithNoMiss() {
        var dealt = deal(level: 1, seed: 11)
        let index = callUntilOnBoard(&dealt)
        XCTAssertEqual(dealt.tap(index), .marked)
        XCTAssertTrue(dealt.marked.contains(index))
        XCTAssertEqual(dealt.tap(index), .ignored, "a bean already there is left alone")
        XCTAssertEqual(dealt.misses, 0)
        XCTAssertEqual(dealt.attempts, 1)
        XCTAssertEqual(dealt.correct, 1)
    }

    func testGivenThePatternCompleteThenLoteriaShowsAndNotBefore() {
        for level in 1...10 {
            for seed in 1...100 {
                var dealt = deal(level: level, seed: UInt64(seed))
                while !dealt.hasLoteria {
                    XCTAssertFalse(
                        LoteriaDeal.isComplete(dealt.pattern, side: dealt.side, marked: dealt.marked),
                        "level \(level) seed \(seed)")
                    let index = callUntilOnBoard(&dealt)
                    XCTAssertEqual(dealt.tap(index), .marked)
                }
                XCTAssertTrue(LoteriaDeal.isComplete(dealt.pattern, side: dealt.side, marked: dealt.marked))
                XCTAssertEqual(dealt.misses, 0, "level \(level) seed \(seed)")
            }
        }
    }

    func testGivenTheSameSeedWhenDealtTwiceThenTheSameBoardAndCallingOrder() {
        for level in [1, 5, 9] {
            XCTAssertEqual(deal(level: level, seed: 42).board, deal(level: level, seed: 42).board)
            XCTAssertEqual(deal(level: level, seed: 42).calls, deal(level: level, seed: 42).calls)
        }
        XCTAssertNotEqual(deal(level: 5, seed: 1).calls, deal(level: 5, seed: 2).calls)
    }

    /// VoiceOver hears the called card's name and each tile as "name, not marked". A player who
    /// has only those words, in either language, can finish a level 1 game without a miss.
    func testGivenVoiceOverOnlyWhenPlayingLevelOneThenTheGameCanBeWon() throws {
        let strings = try catalog()
        for language in ["en", "es"] {
            let open = try value(strings, "game.loteria.a11y.open %@", language)
            for seed in 1...50 {
                var dealt = deal(level: 1, seed: UInt64(seed))
                func name(_ picture: GamePicture) throws -> String { try value(strings, picture.nameKey, language) }
                var steps = 0
                while !dealt.hasLoteria, steps < LoteriaDeal.deck.count * 2 {
                    steps += 1
                    let heard = String(format: open, try name(dealt.current))
                    let labels = try dealt.board.indices.map { index in
                        dealt.marked.contains(index) ? "" : String(format: open, try name(dealt.board[index]))
                    }
                    if let index = labels.firstIndex(of: heard) {
                        XCTAssertEqual(dealt.tap(index), .marked)
                    } else {
                        XCTAssertNotEqual(dealt.next(), .deckDone, "\(language) seed \(seed)")
                    }
                }
                XCTAssertTrue(dealt.hasLoteria, "\(language) seed \(seed)")
                XCTAssertEqual(dealt.misses, 0, "\(language) seed \(seed)")
            }
        }
    }

    // MARK: Patterns

    func testGivenEachPatternWhenItsTilesAreMarkedThenItIsDetected() {
        // Rows and columns on a 3×3 and a 4×4 board.
        for side in [3, 4] {
            for line in 0..<side {
                let row = Set((0..<side).map { line * side + $0 })
                let column = Set((0..<side).map { $0 * side + line })
                XCTAssertTrue(LoteriaDeal.isComplete(.line, side: side, marked: row), "row \(line) of \(side)")
                XCTAssertTrue(LoteriaDeal.isComplete(.line, side: side, marked: column), "column \(line) of \(side)")
                XCTAssertFalse(LoteriaDeal.isComplete(.line, side: side, marked: row.subtracting([line * side])))
            }
            let corners: Set<Int> = [0, side - 1, side * (side - 1), side * side - 1]
            XCTAssertTrue(LoteriaDeal.isComplete(.corners, side: side, marked: corners))
            XCTAssertFalse(LoteriaDeal.isComplete(.corners, side: side, marked: corners.subtracting([0])))
            XCTAssertFalse(LoteriaDeal.isComplete(.line, side: side, marked: corners))
            let all = Set(0..<side * side)
            XCTAssertTrue(LoteriaDeal.isComplete(.fullBoard, side: side, marked: all))
            XCTAssertFalse(LoteriaDeal.isComplete(.fullBoard, side: side, marked: all.subtracting([5])))
        }
        // A diagonal is not a line here: the goal says "a row or a column".
        XCTAssertFalse(LoteriaDeal.isComplete(.line, side: 3, marked: [0, 4, 8]))
        XCTAssertFalse(LoteriaDeal.isComplete(.line, side: 4, marked: []))
    }

    // MARK: Levels and deck

    func testGivenEachLevelThenBoardCalledCardAndPatternFollowTheBrief() {
        let levels = (1...10).map { Difficulty(level: $0) }
        XCTAssertEqual(levels.map(LoteriaDeal.side(for:)), [3, 3, 3, 3, 4, 4, 4, 4, 4, 4])
        XCTAssertEqual(
            levels.map(LoteriaDeal.showsPicture(for:)), [true, true, true, true, true, true, false, false, false, false])
        XCTAssertEqual(
            levels.map(LoteriaDeal.pattern(for:)),
            [.line, .line, .corners, .corners, .line, .line, .corners, .corners, .fullBoard, .fullBoard])
    }

    func testGivenTheDeckThenItIsOurOwnDistinctPicturesAndNotTheClassicSet() {
        let slugs = LoteriaDeal.deck.map(\.slug)
        XCTAssertEqual(slugs.count, 24)
        XCTAssertEqual(Set(slugs).count, slugs.count)
        XCTAssertTrue(slugs.allSatisfy { !$0.hasPrefix("color.") }, "a colour swatch is not a card")
        // Pictures in our bank that a classic card also shows are left out, so the deck shares no
        // card with the classic set.
        let classic: Set<String> = [
            "moon", "star", "tree", "pear", "umbrella", "rose", "watermelon", "pine", "frog", "potted_plant",
            "cactus", "violin",
        ]
        XCTAssertTrue(Set(slugs).isDisjoint(with: classic))
    }

    // MARK: Catalog

    private func catalog() throws -> [String: Any] {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("MenteViva/Localizable.xcstrings"))
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        return try XCTUnwrap(json["strings"] as? [String: Any])
    }

    private func value(_ strings: [String: Any], _ key: String, _ language: String) throws -> String {
        let localizations = try XCTUnwrap((strings[key] as? [String: Any])?["localizations"] as? [String: Any], key)
        let unit = try XCTUnwrap((localizations[language] as? [String: Any])?["stringUnit"] as? [String: Any], key)
        return try XCTUnwrap(unit["value"] as? String, key)
    }
}
