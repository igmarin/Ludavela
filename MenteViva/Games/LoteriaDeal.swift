import Foundation

/// Lotería's rules (#548): a deck of our own pictures, a board ("tabla") dealt from it, a calling
/// order, the beans placed and the pattern that wins. Pure and seeded, so a test can replay a
/// game; the view only shows the state and forwards taps.
///
/// The calling order is the whole deck, each card once, and the player cannot move past a called
/// card that is still unmarked on the board. So every board card is called and marked before the
/// deck ends, and every game reaches "¡Lotería!": there is no "the deck ran out" ending.
nonisolated struct LoteriaDeal: Equatable {
    /// What has to be marked before "¡Lotería!" appears.
    enum Pattern: Equatable {
        /// Any full row or column.
        case line
        /// The board's four corners.
        case corners
        /// Every card on the board.
        case fullBoard
    }

    /// What a tap on a board tile did.
    enum TapOutcome: Equatable {
        /// The picture has been called: a bean goes on it.
        case marked
        /// Not called yet: no bean, one miss.
        case notCalled
        /// Already has a bean: nothing changes.
        case ignored
    }

    /// What "Next card" did.
    enum NextOutcome: Equatable {
        /// A new card was called.
        case called(GamePicture)
        /// The called card is on the board with no bean yet: the card stays.
        case lookAgain
        /// The player asked again, so the matching tile is shown as a one-time hint.
        case showHelp(Int)
        /// Nothing left to call. Unreachable in play (see the type's comment); kept so the view never traps.
        case deckDone
    }

    /// Our cards: 24 pictures from the shared bank, named by what they show. Pictures that a
    /// classic lotería card also shows (moon, star, tree, pear, umbrella, rose, watermelon, pine,
    /// frog, potted plant, cactus, violin) are left out, so the deck shares no card with that set.
    /// 24 keeps a game to about 13 calls at level 1 and 24 at most for a full 4×4 board.
    static let deck = GamePictures.named([
        "dog", "cat", "turtle", "butterfly", "elephant", "bee", "ladybug", "lion",
        "apple", "banana", "grapes", "strawberry", "lemon", "bread", "chocolate", "coffee",
        "guitar", "trumpet", "accordion", "sunflower", "house", "clock", "bicycle", "sailboat",
    ])

    /// Board side per level 1...10: 3×3 to level 4, then 4×4.
    static func side(for difficulty: Difficulty) -> Int {
        difficulty.values([3, 3, 3, 3, 4, 4, 4, 4, 4, 4])
    }

    /// Whether the called card shows its picture as well as its name: from level 7, the name only.
    static func showsPicture(for difficulty: Difficulty) -> Bool {
        difficulty.level <= 6
    }

    /// The winning pattern per level 1...10: a line, then four corners, at each board size; a full
    /// board at the top.
    static func pattern(for difficulty: Difficulty) -> Pattern {
        difficulty.values([.line, .line, .corners, .corners, .line, .line, .corners, .corners, .fullBoard, .fullBoard])
    }

    /// Whether the beans on a `side`×`side` board (row-major indices) complete the pattern. A
    /// diagonal is not a line: the goal is said as "a row or a column", and that is all that counts.
    static func isComplete(_ pattern: Pattern, side: Int, marked: Set<Int>) -> Bool {
        switch pattern {
        case .line:
            let indices = 0..<side
            return indices.contains { row in indices.allSatisfy { marked.contains(row * side + $0) } }
                || indices.contains { column in indices.allSatisfy { marked.contains($0 * side + column) } }
        case .corners:
            return [0, side - 1, side * (side - 1), side * side - 1].allSatisfy(marked.contains)
        case .fullBoard:
            return (0..<side * side).allSatisfy(marked.contains)
        }
    }

    let side: Int
    let pattern: Pattern
    /// Whether a second "Look again" can point to the called card, for name-only levels 7–10.
    let helpAvailable: Bool
    /// The board's cards, row by row.
    let board: [GamePicture]
    /// The calling order: every deck card, once.
    let calls: [GamePicture]
    /// How many cards have been called; the first is called when the game is dealt.
    private(set) var calledCount = 1
    /// Board indices with a bean.
    private(set) var marked: Set<Int> = []
    /// Taps on a tile not called yet, plus "Next card" while the called card waited on the board.
    private(set) var misses = 0
    /// Whether the first "Next card" already showed "Look again" for this called card.
    private var lookedAgain = false
    /// Whether the matching tile has already been shown for this called card.
    private var showedHelp = false

    /// Deals a board and a calling order for the level.
    static func make(difficulty: Difficulty, using generator: inout some RandomNumberGenerator) -> LoteriaDeal {
        let side = side(for: difficulty)
        return LoteriaDeal(
            side: side, pattern: pattern(for: difficulty), helpAvailable: difficulty.level >= 7,
            board: Array(deck.shuffled(using: &generator).prefix(side * side)),
            calls: deck.shuffled(using: &generator))
    }

    /// The card called now.
    var current: GamePicture { calls[calledCount - 1] }

    /// The level's pattern is complete: the view shows "¡Lotería!". It never ends the game itself.
    var hasLoteria: Bool { Self.isComplete(pattern, side: side, marked: marked) }

    /// Every pick the player made, for the saved session: beans placed plus misses.
    var attempts: Int { marked.count + misses }
    /// Picks that placed a bean.
    var correct: Int { marked.count }

    /// A tap on board tile `index`: a bean if its picture has been called, else a miss.
    mutating func tap(_ index: Int) -> TapOutcome {
        guard !marked.contains(index) else { return .ignored }
        guard calls.prefix(calledCount).contains(board[index]) else {
            misses += 1
            return .notCalled
        }
        marked.insert(index)
        return .marked
    }

    /// "Next card": calls the next card, unless the called one is on the board and unmarked.
    mutating func next() -> NextOutcome {
        if let index = board.firstIndex(of: current), !marked.contains(index) {
            if !lookedAgain {
                misses += 1
                lookedAgain = true
                return .lookAgain
            }
            guard helpAvailable else { return .lookAgain }
            if !showedHelp {
                misses += 1
                showedHelp = true
                return .showHelp(index)
            }
            return .lookAgain
        }
        guard calledCount < calls.count else { return .deckDone }
        calledCount += 1
        lookedAgain = false
        showedHelp = false
        return .called(current)
    }
}
