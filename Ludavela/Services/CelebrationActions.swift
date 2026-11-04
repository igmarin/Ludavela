import Foundation

/// The two buttons that end a game (#583): one filled, one quieter, both always reachable.
/// Kept pure so the rule is tested and the view only draws it. While today's picks last the filled
/// one is the next game. When this game closed today's table the day is done, so the filled one
/// is Home and playing again stays as the quiet choice: the screen never offers a game that
/// isn't there. After a replay or an off-plan game it is "Play again" as before.
nonisolated struct CelebrationActions: Equatable {
    enum Choice: Equatable {
        case next(GameID)
        case playAgain
        case home
    }

    let primary: Choice
    let secondary: Choice

    /// `next` is `TodayRun.next(after:)`; `closesTheDay` is `TodayRun.closesTheDay(finishing:)`.
    init(next: GameID?, closesTheDay: Bool) {
        if let next {
            primary = .next(next)
            secondary = .home
        } else if closesTheDay {
            primary = .home
            secondary = .playAgain
        } else {
            primary = .playAgain
            secondary = .home
        }
    }
}
