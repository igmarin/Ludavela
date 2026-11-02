import XCTest

@testable import MenteViva

/// Peg solitaire deals are reproducible, playable and reversible.
final class PegSolitaireBoardTests: XCTestCase {
    private struct Generator: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
    }

    func testGivenEveryLevelWhenDealtThenSolverReachesOnePeg() {
        let counts = [3, 4, 5, 6, 8, 10, 12, 15, 18, 22]
        for level in 1...10 {
            for seed in 1...5 {
                var rng = Generator(state: UInt64(seed))
                var board = PegSolitaireBoard.deal(level: level, using: &rng)
                XCTAssertEqual(board.pegCount, counts[level - 1])
                while board.pegCount > 1 {
                    guard case .move(let move) = board.hint() else {
                        XCTFail("No solution for level \(level), seed \(seed)")
                        break
                    }
                    XCTAssertTrue(board.jump(move))
                }
                XCTAssertEqual(board.pegCount, 1)
            }
        }
    }

    func testGivenSameSeedWhenDealtThenBoardIsIdentical() {
        var first = Generator(state: 42)
        var second = Generator(state: 42)
        XCTAssertEqual(PegSolitaireBoard.deal(level: 10, using: &first), PegSolitaireBoard.deal(level: 10, using: &second))
    }

    func testGivenLegalJumpWhenPlayedAndUndoneThenPegCountAndBoardRestore() {
        var rng = Generator(state: 1)
        var board = PegSolitaireBoard.deal(level: 1, using: &rng)
        let initial = board
        let move = board.moves[0]
        XCTAssertTrue(board.jump(move))
        XCTAssertEqual(board.pegCount, 2)
        XCTAssertFalse(board.contains(move.over))
        XCTAssertTrue(board.undo())
        XCTAssertEqual(board.pegs, initial.pegs)
    }

    func testGivenIsolatedPegsWhenHintRequestedThenNoSolution() {
        let board = PegSolitaireBoard(pegs: (1 << 0) | (1 << 32))
        XCTAssertEqual(board.hint(), .unsolvable)
        XCTAssertTrue(board.moves.isEmpty)
    }

    func testGivenNoSearchBudgetWhenHintRequestedThenResultIsNotUnsolvable() {
        var rng = Generator(state: 8)
        let board = PegSolitaireBoard.deal(level: 3, using: &rng)
        XCTAssertEqual(board.hint(budget: 0), .inconclusive)
    }
    /// Release builds measure the whole solver call, including memo allocation.
    func testGivenTwentyTwoPegsWhenFindingHintThenItFinishesWithinBudget() {
        var rng = Generator(state: 7)
        let board = PegSolitaireBoard.deal(level: 10, using: &rng)
        let start = Date.now
        guard case .move = board.hint() else { return XCTFail("No solution found") }
        #if !DEBUG
            XCTAssertLessThan(Date.now.timeIntervalSince(start), 0.2)
        #else
            _ = start
        #endif
    }

}
