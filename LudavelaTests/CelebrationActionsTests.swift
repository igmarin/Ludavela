import XCTest

@testable import Ludavela

/// #583: the celebration shows one filled action and one quieter one. Which is which depends on
/// whether a next game exists, and the end of the day never promises a game that is not there.
final class CelebrationActionsTests: XCTestCase {
    func testGivenGamesLeftTodayWhenAGameEndsThenNextIsPrimaryAndHomeStaysAvailable() {
        let actions = CelebrationActions(next: .sudoku, closesTheDay: false)

        XCTAssertEqual(actions.primary, .next(.sudoku))
        XCTAssertEqual(actions.secondary, .home)
    }

    func testGivenTheGameClosedTheDayWhenItEndsThenHomeIsPrimaryAndPlayAgainStaysAvailable() {
        let actions = CelebrationActions(next: nil, closesTheDay: true)

        XCTAssertEqual(actions.primary, .home)
        XCTAssertEqual(actions.secondary, .playAgain)
    }

    func testGivenAReplayOrOffPlanGameWhenItEndsThenPlayAgainIsPrimaryAndHomeStaysAvailable() {
        let actions = CelebrationActions(next: nil, closesTheDay: false)

        XCTAssertEqual(actions.primary, .playAgain)
        XCTAssertEqual(actions.secondary, .home)
    }

    func testGivenNoPlanYetWhenAGameEndsThenItIsTheOrdinaryReplayChoice() {
        // No saved plan means no TodayRun: the view passes no next game and no closed day.
        XCTAssertEqual(CelebrationActions(next: nil, closesTheDay: false).primary, .playAgain)
    }
}
