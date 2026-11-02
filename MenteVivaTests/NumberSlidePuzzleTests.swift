import SwiftData
import XCTest

@testable import MenteViva

/// #547: Rompecocos / Number Slide, the 15-number sliding puzzle. One test per acceptance line of
/// the issue, then the hint's cost, the levels and the session.
final class NumberSlidePuzzleTests: XCTestCase {
    private struct SeededGenerator: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
    }

    /// Plays hints until the board is solved, or gives up after `limit` moves.
    private func solvedByHints(_ start: NumberSlidePuzzle, limit: Int = 300) -> NumberSlidePuzzle {
        var puzzle = start
        for _ in 0..<limit where !puzzle.isSolved {
            guard let cell = NumberSlideSolver.hint(from: puzzle) else { break }
            XCTAssertTrue(puzzle.slide(at: cell), "a hint is always a legal slide")
        }
        return puzzle
    }

    // MARK: - Acceptance

    func testGivenAnyDealAtAnyLevelWhenSolvedByHintRepeatedlyThenItReachesTheGoal() {
        var generator = SeededGenerator(state: 547)
        for level in 1...10 {
            // The deepest 4×4 deals take a few seconds each in a debug build, so fewer of them.
            for _ in 0..<(level >= 9 ? 1 : 4) {
                let deal = NumberSlidePuzzle.deal(for: Difficulty(level: level), using: &generator)
                XCTAssertFalse(deal.isSolved, "level \(level) deals a board to solve")
                XCTAssertTrue(solvedByHints(deal).isSolved, "level \(level): \(deal.tiles)")
            }
        }
    }

    func testGivenATapTwoCellsFromTheGapInTheSameRowThenBothTilesSlideAndTheGapMovesToTheTappedCell() {
        var puzzle = NumberSlidePuzzle.solved(size: 4)
        XCTAssertTrue(puzzle.slide(at: 13))
        XCTAssertEqual(Array(puzzle.tiles.suffix(4)), [13, 0, 14, 15])
        XCTAssertEqual(puzzle.gap, 13)
        XCTAssertEqual(puzzle.movesMade, 2, "two tiles moved one cell each")
    }

    func testGivenATapOnATileOutOfTheGapsRowAndColumnThenNothingMovesAndNothingCounts() {
        var puzzle = NumberSlidePuzzle.solved(size: 4)
        XCTAssertNil(puzzle.direction(ofTileAt: 0))
        XCTAssertFalse(puzzle.slide(at: 0))
        XCTAssertFalse(puzzle.slide(at: puzzle.gap), "the gap itself is not a tile")
        XCTAssertEqual(puzzle, NumberSlidePuzzle.solved(size: 4))
        XCTAssertEqual(puzzle.movesMade, 0)
        XCTAssertTrue(puzzle.history.isEmpty)
    }

    func testGivenTheSameSeedThenTheSameDeal() {
        for level in 1...10 {
            var first = SeededGenerator(state: 2_026)
            var second = SeededGenerator(state: 2_026)
            XCTAssertEqual(
                NumberSlidePuzzle.deal(for: Difficulty(level: level), using: &first).tiles,
                NumberSlidePuzzle.deal(for: Difficulty(level: level), using: &second).tiles, "level \(level)")
        }
    }

    func testGivenUndoAfterThreeMovesThenTheBoardIsAsItWasAfterTwo() {
        var puzzle = NumberSlidePuzzle.solved(size: 4)
        XCTAssertTrue(puzzle.slide(at: 12))  // the bottom row's three tiles slide right
        XCTAssertTrue(puzzle.slide(at: 0))  // the left column slides down
        let afterTwo = puzzle.tiles
        let movesAfterTwo = puzzle.movesMade
        XCTAssertTrue(puzzle.slide(at: 2))  // two tiles of the top row slide left
        XCTAssertTrue(puzzle.undo())
        XCTAssertEqual(puzzle.tiles, afterTwo)
        XCTAssertEqual(puzzle.movesMade, movesAfterTwo, "the undone tap's moves are taken back too")
    }

    func testGivenLevelOneSolvedThenASessionIsSavedWithItsLevel() throws {
        var generator = SeededGenerator(state: 1)
        let level = Difficulty(level: 1)
        let deal = NumberSlidePuzzle.deal(for: level, using: &generator)
        let fewest = NumberSlideSolver.fewestMoves(from: deal)
        let solved = solvedByHints(deal)
        XCTAssertTrue(solved.isSolved)
        let context = ModelContext(
            try ModelContainer(for: GameSession.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))

        context.record(solved.session(level: level, fewestMoves: fewest, hints: 0, seconds: 30))

        let saved = try XCTUnwrap(try context.fetch(FetchDescriptor<GameSession>()).first)
        XCTAssertEqual(saved.game, .numberSlide)
        XCTAssertEqual(saved.resolvedLevel, level)
        XCTAssertEqual(saved.correct, fewest)
        XCTAssertEqual(saved.accuracy, 1, "hints play the shortest way, so every move counted")
    }

    func testGivenVoiceOverOnlyThenTheLevelOnePuzzleCanBeSolvedWithCustomActions() {
        var generator = SeededGenerator(state: 3)
        var puzzle = NumberSlidePuzzle.deal(for: Difficulty(level: 1), using: &generator)
        for _ in 0..<20 where !puzzle.isSolved {
            // The actions VoiceOver offers: one per tile in the gap's row or column, toward the gap.
            let offered = puzzle.tiles.indices.filter { puzzle.direction(ofTileAt: $0) != nil }
            let inLine = puzzle.tiles.indices.filter {
                $0 != puzzle.gap && ($0 / 3 == puzzle.gap / 3 || $0 % 3 == puzzle.gap % 3)
            }
            XCTAssertEqual(offered, inLine, "only the legal slides are offered")
            guard let cell = NumberSlideSolver.hint(from: puzzle), offered.contains(cell) else {
                return XCTFail("the next slide is not among the actions")
            }
            XCTAssertTrue(puzzle.slide(at: cell))
        }
        XCTAssertTrue(puzzle.isSolved)
    }

    // MARK: - Hint time

    /// Counted in nodes, not on a stopwatch (a wall-clock ceiling flaked on loaded runners for
    /// Sliding Blocks). In a release build on a Mac the slowest hint over 300 such scrambles took
    /// 18 ms, so a hint that keeps within the budget answers well under the 100 ms allowed.
    func testGivenASixtyMoveFourByFourScrambleWhenAskedForAHintThenItAnswersWithinTheBudget() {
        var generator = SeededGenerator(state: 60)
        let puzzle = NumberSlidePuzzle.scrambled(size: 4, moves: 60, using: &generator)
        let search = NumberSlideSolver.hintSearch(from: puzzle)
        XCTAssertLessThanOrEqual(search.nodes, NumberSlideSolver.hintBudget)
        guard let cell = search.cell else { return XCTFail("no hint") }
        XCTAssertTrue(NumberSlidePuzzle.neighbours(of: puzzle.gap, size: 4).contains(cell), "a tile next to the gap")
    }

    // MARK: - Levels

    func testGivenEachLevelThenItsBoardSizeAndHarderDealsThanTheLevelBelow() {
        var generator = SeededGenerator(state: 9)
        var previous = 0.0
        for level in 1...10 {
            let deals = (0..<12).map { _ in NumberSlidePuzzle.deal(for: Difficulty(level: level), using: &generator) }
            XCTAssertTrue(deals.allSatisfy { $0.size == (level <= 5 ? 3 : 4) }, "level \(level)")
            // The estimate is a lower bound on the fewest moves and cheap in a debug build.
            let mean = Double(deals.map(NumberSlideSolver.estimate).reduce(0, +)) / Double(deals.count)
            if level != 6 { XCTAssertGreaterThan(mean, previous, "level \(level)") }
            previous = mean
        }
    }

    func testGivenLevelOneThenTheFewestMovesAreThreeOrFour() {
        var generator = SeededGenerator(state: 4)
        for _ in 0..<20 {
            let deal = NumberSlidePuzzle.deal(for: Difficulty(level: 1), using: &generator)
            XCTAssertTrue((3...4).contains(NumberSlideSolver.fewestMoves(from: deal)), "\(deal.tiles)")
        }
    }

    // MARK: - Moves and the session

    func testGivenStartOverThenTheDealIsBackAndNothingCounts() {
        var generator = SeededGenerator(state: 5)
        var puzzle = NumberSlidePuzzle.deal(for: Difficulty(level: 3), using: &generator)
        let dealt = puzzle.tiles
        for cell in NumberSlidePuzzle.neighbours(of: puzzle.gap, size: 3).prefix(1) { puzzle.slide(at: cell) }
        puzzle.startOver()
        XCTAssertEqual(puzzle.tiles, dealt)
        XCTAssertEqual(puzzle.movesMade, 0)
        XCTAssertTrue(puzzle.history.isEmpty)
    }

    func testGivenASolvedBoardThenThereIsNoHint() {
        XCTAssertNil(NumberSlideSolver.hint(from: .solved(size: 3)))
        XCTAssertEqual(NumberSlideSolver.fewestMoves(from: .solved(size: 4)), 0)
    }

    func testGivenMoreFewestMovesThanAttemptsThenAccuracyStaysAtOne() {
        var puzzle = NumberSlidePuzzle.solved(size: 3)
        puzzle.slide(at: 7)
        let session = puzzle.session(level: Difficulty(level: 2), fewestMoves: 9, hints: 0, seconds: 5)
        XCTAssertEqual(session.attempts, 1)
        XCTAssertEqual(session.accuracy, 1)
    }

    func testGivenShownMovesThenEachCountsOnceMoreAsAnAttempt() {
        var puzzle = NumberSlidePuzzle.solved(size: 3)
        puzzle.slide(at: 7)
        puzzle.slide(at: 6)
        let session = puzzle.session(level: Difficulty(level: 2), fewestMoves: 2, hints: 2, seconds: 5)
        XCTAssertEqual(session.attempts, 4)
        XCTAssertEqual(session.accuracy, 0.5)
    }
}
