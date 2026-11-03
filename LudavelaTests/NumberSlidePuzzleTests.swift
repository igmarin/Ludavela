import SwiftData
import XCTest

@testable import Ludavela

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
        // The player finds the shortest way on their own: the solver's path, tapped by them.
        var solved = deal
        for cell in NumberSlideSolver.hintSearch(from: deal).path { XCTAssertTrue(solved.slide(at: cell)) }
        XCTAssertTrue(solved.isSolved)
        let context = ModelContext(
            try ModelContainer(for: GameSession.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true)))

        context.record(solved.session(level: level, fewestMoves: fewest, hints: 0, seconds: 30))

        let saved = try XCTUnwrap(try context.fetch(FetchDescriptor<GameSession>()).first)
        XCTAssertEqual(saved.game, .numberSlide)
        XCTAssertEqual(saved.resolvedLevel, level)
        XCTAssertEqual(saved.correct, fewest)
        XCTAssertEqual(saved.attempts, fewest)
        XCTAssertEqual(saved.accuracy, 1, "the fewest moves, none shown")
    }

    func testGivenLevelOneSolvedByShowMeAMoveAloneThenTheSessionSaysSoAndTheLevelHolds() throws {
        var generator = SeededGenerator(state: 1)
        let deal = NumberSlidePuzzle.deal(for: Difficulty(level: 1), using: &generator)
        let fewest = try XCTUnwrap(NumberSlideSolver.fewestMoves(from: deal))
        let solved = solvedByHints(deal)
        let session = solved.session(level: Difficulty(level: 1), fewestMoves: fewest, hints: solved.movesMade, seconds: 30)
        XCTAssertEqual(session.attempts, 3 * fewest, "each shown move counts itself and two more")
        let accuracy = try? XCTUnwrap(session.accuracy)
        XCTAssertEqual(accuracy ?? 0, 1.0 / 3, accuracy: 1e-9)
        XCTAssertLessThan(accuracy ?? 1, DailyPolicy.strongAccuracy(for: .numberSlide), "watching alone never climbs")
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
    /// 15 ms, so a hint that keeps within the budget answers well under the 100 ms allowed.
    /// Seed 60 is past the exact search's 80,000 nodes and is answered by the widened search; seeds
    /// 62 and 64 are answered exactly. Each answer is a whole solution found inside the budget, never
    /// the fallback slide.
    func testGivenASixtyMoveFourByFourScrambleWhenAskedForAHintThenItAnswersWithinTheBudget() {
        for seed: UInt64 in [60, 62, 64] {
            var generator = SeededGenerator(state: seed)
            let puzzle = NumberSlidePuzzle.scrambled(size: 4, moves: 60, using: &generator)
            let search = NumberSlideSolver.hintSearch(from: puzzle)
            XCTAssertLessThan(search.nodes, NumberSlideSolver.hintBudget, "seed \(seed) found a path inside the budget")
            XCTAssertEqual(search.cell, search.path.first, "seed \(seed)")
            var replay = puzzle
            for cell in search.path { XCTAssertTrue(replay.slide(at: cell), "seed \(seed)") }
            XCTAssertTrue(replay.isSolved, "seed \(seed): the path solves the board")
            XCTAssertGreaterThanOrEqual(search.path.count, NumberSlideSolver.estimate(puzzle))
            if search.nodes < NumberSlideSolver.hintSteps[0].nodes {
                // Answered by the exact step: the path is a shortest one.
                XCTAssertEqual(search.path.count, NumberSlideSolver.fewestMoves(from: puzzle), "seed \(seed)")
            } else {
                XCTAssertEqual(seed, 60, "only seed 60 needs the widened search")
            }
        }
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
            XCTAssertTrue((3...4).contains(NumberSlideSolver.fewestMoves(from: deal) ?? 0), "\(deal.tiles)")
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

    func testGivenShownMovesThenEachCountsTwiceMoreAsAnAttempt() {
        var puzzle = NumberSlidePuzzle.solved(size: 3)
        puzzle.slide(at: 7)
        puzzle.slide(at: 6)
        let session = puzzle.session(level: Difficulty(level: 2), fewestMoves: 2, hints: 1, seconds: 5)
        XCTAssertEqual(session.attempts, 4, "two moves, one of them shown")
        XCTAssertEqual(session.accuracy, 0.5)
    }

    // MARK: - The heuristic (#547 review)

    func testGivenALineWithFewerThanTwoOfItsOwnTilesThenItHasNoConflict() {
        XCTAssertEqual(NumberSlideSolver.lineCosts[0], 0, "no tile of its own")
        XCTAssertEqual(NumberSlideSolver.lineCosts[1 << 8], 0, "one tile of its own")
        XCTAssertTrue(NumberSlideSolver.lineCosts.allSatisfy { $0 >= 0 })
        // Two tiles home in the line but in each other's way: one must leave and come back.
        XCTAssertEqual(NumberSlideSolver.lineCosts[2 << 8 | 1], 2)
    }

    /// The exact solver against a breadth-first count of every 3×3 board from the goal.
    func testGivenSeededThreeByThreeBoardsThenTheFewestMovesAreTheBreadthFirstDistance() {
        // Each board as one Int, 4 bits a cell.
        func key(_ tiles: [Int]) -> Int { tiles.reversed().reduce(0) { $0 << 4 | $1 } }
        let goal = NumberSlidePuzzle.solved(size: 3).tiles
        var distance = [key(goal): 0]
        var frontier = [goal]
        while !frontier.isEmpty {
            var next: [[Int]] = []
            for board in frontier {
                let gap = board.firstIndex(of: 0) ?? 0
                let steps = distance[key(board)] ?? 0
                for cell in NumberSlidePuzzle.neighbours(of: gap, size: 3) {
                    var moved = board
                    moved.swapAt(gap, cell)
                    if distance[key(moved)] == nil {
                        distance[key(moved)] = steps + 1
                        next.append(moved)
                    }
                }
            }
            frontier = next
        }
        XCTAssertEqual(distance.count, 181_440)
        var generator = SeededGenerator(state: 8)
        for _ in 0..<300 {
            let board = NumberSlidePuzzle.scrambled(size: 3, moves: Int.random(in: 1...60, using: &generator), using: &generator)
            XCTAssertEqual(NumberSlideSolver.fewestMoves(from: board), distance[key(board.tiles)], "\(board.tiles)")
            XCTAssertLessThanOrEqual(NumberSlideSolver.estimate(board), distance[key(board.tiles)] ?? 0, "\(board.tiles)")
        }
    }

    /// The search keeps the estimate up to date slide by slide instead of counting the board
    /// again (#559 review): after every one of thousands of random slides on both boards it
    /// matches a fresh count.
    func testGivenThousandsOfRandomSlidesThenTheKeptEstimateMatchesAFreshCountEveryTime() {
        var generator = SeededGenerator(state: 559)
        for size in [3, 4] {
            for _ in 0..<5 {
                var board = NumberSlidePuzzle.scrambled(size: size, moves: 200, using: &generator)
                let start = board
                var cells: [Int] = []
                var fresh: [Int] = []
                for _ in 0..<1_000 {
                    let options = NumberSlidePuzzle.neighbours(of: board.gap, size: size)
                    let cell = options[Int.random(in: options.indices, using: &generator)]
                    board.slide(at: cell)
                    cells.append(cell)
                    fresh.append(NumberSlideSolver.estimate(board))
                }
                XCTAssertEqual(
                    NumberSlideSolver.estimates(along: cells, from: start), fresh, "\(size)×\(size) from \(start.tiles)")
            }
        }
    }

    /// Leaving the screen cancels the count of the deal's fewest moves (#559 review): the search
    /// asks once, at its first check, and stops there, finding nothing.
    func testGivenACancelledCountWhenSearchingAHardBoardThenItStopsAtTheFirstCheck() {
        var generator = SeededGenerator(state: 60)
        let hard = NumberSlidePuzzle.scrambled(size: 4, moves: 60, using: &generator)
        var asked = 0
        let fewest = NumberSlideSolver.fewestMoves(from: hard) {
            asked += 1
            return true
        }
        XCTAssertNil(fewest)
        XCTAssertEqual(asked, 1, "one check, after 4,096 nodes, then nothing more")
    }

    /// With no count found, the session is scored from the moves alone, never from the estimate
    /// (#559 review): the estimate is a lower bound, not a solution.
    func testGivenNoFewestMovesWhenSavedThenTheSessionScoresFromTheMovesAlone() {
        var puzzle = NumberSlidePuzzle.solved(size: 4)
        puzzle.slide(at: 12)
        puzzle.slide(at: 0)
        let session = puzzle.session(level: Difficulty(level: 10), fewestMoves: nil, hints: 1, seconds: 60)
        XCTAssertEqual(session.attempts, puzzle.movesMade + 2)
        XCTAssertEqual(session.correct, puzzle.movesMade)
    }

    // MARK: - The staircase (#547 review)

    /// A steady player who takes 2.5 times the fewest moves, one game a day from level 1, follows
    /// `DailyPolicy` the way the app feeds it: accuracies at the current level since it last moved,
    /// newest first, and no second move on the day a level changed.
    func testGivenAPlayerAtTwoAndAHalfTimesTheFewestMovesThenTheyReachTheFourByFourInAFewGames() {
        var generator = SeededGenerator(state: 25)
        var level = Difficulty(level: 1)
        var recent: [Double] = []
        var changedOn: String?
        var games = 0
        for day in 1...20 where level.level < 6 {
            let today = String(format: "2026-12-%02d", day)
            let stats = PlayerStateSummary.GameStats(
                sessionsLast14Days: games, meanAccuracy: recent.first, meanRoundsCompleted: 1, daysSinceLastPlayed: 1,
                currentDifficulty: level, recentAccuracies: recent)
            let summary = PlayerStateSummary(games: [GameID.numberSlide.rawValue: stats])
            let plan = DailyPolicy.plan(
                state: summary, lastChange: changedOn.map { [.numberSlide: $0] } ?? [:], dayStamp: today, pinned: [:],
                hidden: [])
            if let next = plan.difficulty[.numberSlide], next != level {
                level = next
                recent = []
                changedOn = today
            }
            guard level.level < 6 else { break }
            let deal = NumberSlidePuzzle.deal(for: level, using: &generator)
            let fewest = NumberSlideSolver.fewestMoves(from: deal) ?? 0
            let moves = Int((2.5 * Double(fewest)).rounded())
            let session = GameSession(gameID: .numberSlide, rounds: 1, durationSeconds: 60, correct: fewest, attempts: moves)
            recent.insert(session.accuracy ?? 0, at: 0)
            games += 1
        }
        XCTAssertEqual(level, Difficulty(level: 6), "the 4×4 is reached")
        XCTAssertLessThanOrEqual(games, 5, "one level a game, from level 1")
    }
}
