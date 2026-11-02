import Foundation

/// A seeded word-search board and the straight lines that solve it.
nonisolated struct WordSearchDeal: Equatable {
    /// The displayed word and its cells in reading order.
    struct Word: Equatable {
        let text: String
        let cells: [Int]
    }

    let side: Int
    let grid: [Character]
    let words: [Word]
    let themeKey: String

    /// Each name has a title, `game.wordsearch.<name>`, and a word list, `<title key>.words`, in EN and ES.
    static let themeNames = ["animals", "garden", "music", "food", "family", "kitchen"]

    /// Weighted letter pools approximate each language's ordinary letter frequency.
    static let spanishLetters = Array("AAAAAAAABCDEEEEEEEEEFGHIIIIIIJKLMNÑOOOOOOOPQRRRRSSSSSTTTTUUUVXYZ")
    private static let englishLetters = Array(
        "AAAAAAAABCDEEEEEEEEEEEEFFGHHHHIIIIIIJKLLLLMMNNNNNNOOOOOOOOPPQRRRRRRSSSSSSTTTTTTTTTUUUVWWXYYZ")
    /// Rude words a grid must never show by accident, in any direction (#560). A theme word that
    /// contains one could never be dealt, so the shipped lists are tested against these too.
    static let spanishBlocked = [
        "CULO", "PUTA", "PEDO", "MIERDA", "CACA", "PENE", "VERGA", "PITO", "CHICHI", "MAMON", "JOTO", "PINCHE",
        "CABRON", "PUTO", "PUTAS", "CULOS", "COÑO",
    ]
    static let englishBlocked = [
        "ASS", "FUCK", "SHIT", "DICK", "CUM", "TIT", "FAG", "CUNT", "PISS", "POO", "COCK", "SLUT", "CRAP", "TWAT",
    ]
    private static let directions = [(0, 1), (1, 0), (1, 1), (-1, 1)]
    private static let allDirections = directions + [(0, -1), (-1, 0), (-1, -1), (1, -1)]
    /// A letter's square never drops under the house's 60pt touch target (AGENTS.md, #560) and
    /// grows to 64pt where there is room.
    static let minCell = 60.0
    static let maxCell = 64.0
    /// The screen's side margin on each side, trimmed so a 375pt iPhone SE still fits six 60pt squares.
    static let sideMargin = 4.0

    /// The level's grid, capped at the most 60pt squares that fit across `space` points, as Sudoku
    /// deals by width (#560). Wanted grid by level band (1–2, 3–4, 5–6, 7–8, 9–10):
    /// iPhone 6, 7, 8, 8, 8 and iPad 6, 8, 9, 10, 10. So an iPhone SE (367pt of board) plays 6×6,
    /// one with Display Zoom (312pt) 5×5, a 393pt iPhone 6×6 and a 440pt one up to 7×7. Never under 5×5.
    static func side(level: Int, tablet: Bool, space: Double) -> Int {
        let band = (max(1, min(level, 10)) - 1) / 2
        let wanted = (tablet ? [6, 8, 9, 10, 10] : [6, 7, 8, 8, 8])[band]
        return max(5, min(wanted, Int(min(space, 1_000) / minCell)))
    }

    /// The square size for a `side`-wide grid across `space` points.
    static func cell(side: Int, space: Double) -> Double {
        min(maxCell, space / Double(side))
    }

    /// Words by level band (4, 4, 5, 5, 6, 6, 7, 7, 8, 8), capped at the grid's side: by experiment,
    /// side + 1 words often take hundreds of re-rolls on a 5×5 to 7×7, while side words take a few.
    static func wordCount(level: Int, side: Int) -> Int {
        min(4 + (max(1, min(level, 10)) - 1) / 2, side)
    }

    /// Words, directions and the wanted grid change only between the five level bands; `space` is the
    /// width the board may take, in points.
    static func make(
        level: Int, tablet: Bool, space: Double = 1_000, spanish isSpanish: Bool, themes: [(String, [String])],
        using random: inout some RandomNumberGenerator
    )
        -> Self
    {
        let band = (max(1, min(level, 10)) - 1) / 2
        let side = side(level: level, tablet: tablet, space: space)
        let count = wordCount(level: level, side: side)
        // Only words that fit this board can be dealt at this level.
        let eligible = themes.filter { $0.1.filter { $0.count <= side }.count >= count }
        let theme = eligible.randomElement(using: &random)!
        let texts = Array(theme.1.filter { $0.count <= side }.shuffled(using: &random).prefix(count))
        let allowed = Array(directions.prefix([1, 2, 3, 3, 4][band]))
        let pool = isSpanish ? spanishLetters : englishLetters

        while true {
            var grid = Array(repeating: Character(" "), count: side * side)
            var placed: [Word] = []
            for text in texts {
                let letters = Array(text)
                let candidates = (0..<(side * side)).flatMap { start in
                    allowed.compactMap { direction -> [Int]? in
                        let row = start / side
                        let column = start % side
                        let endRow = row + direction.0 * (letters.count - 1)
                        let endColumn = column + direction.1 * (letters.count - 1)
                        guard (0..<side).contains(endRow), (0..<side).contains(endColumn) else { return nil }
                        let cells = (0..<letters.count).map { (row + $0 * direction.0) * side + column + $0 * direction.1 }
                        guard zip(cells, letters).allSatisfy({ grid[$0.0] == " " || grid[$0.0] == $0.1 }) else { return nil }
                        return cells
                    }
                }
                guard let cells = candidates.randomElement(using: &random) else { break }
                for (cell, letter) in zip(cells, letters) { grid[cell] = letter }
                placed.append(Word(text: text, cells: cells))
            }
            guard placed.count == texts.count else { continue }
            for index in grid.indices where grid[index] == " " {
                grid[index] = pool.randomElement(using: &random)!
            }
            let deal = Self(side: side, grid: grid, words: placed, themeKey: theme.0)
            // Any rude word or extra copy re-rolls the whole grid from the same generator, so a seed still
            // gives one board.
            if placed.allSatisfy({ deal.occurrences(of: $0.text) == [$0.cells] }),
                !deal.showsBlockedWord(spanish: isSpanish)
            {
                return deal
            }
        }
    }

    func showsBlockedWord(spanish: Bool) -> Bool {
        (spanish ? Self.spanishBlocked : Self.englishBlocked).contains { !occurrences(of: $0).isEmpty }
    }

    /// Searches all directions, including backwards, to reject accidental copies.
    func occurrences(of text: String) -> [[Int]] {
        let letters = Array(text)
        return (0..<grid.count).flatMap { start in
            Self.allDirections.compactMap { direction -> [Int]? in
                let row = start / side
                let column = start % side
                let endRow = row + direction.0 * (letters.count - 1)
                let endColumn = column + direction.1 * (letters.count - 1)
                guard (0..<side).contains(endRow), (0..<side).contains(endColumn) else { return nil }
                let cells = (0..<letters.count).map { (row + $0 * direction.0) * side + column + $0 * direction.1 }
                return zip(cells, letters).allSatisfy { grid[$0.0] == $0.1 } ? cells : nil
            }
        }
    }

    /// Tapping either endpoint first identifies the same word.
    func match(from start: Int, to end: Int) -> String? {
        words.first { ($0.cells.first == start && $0.cells.last == end) || ($0.cells.first == end && $0.cells.last == start) }?
            .text
    }
}

/// The player's picks on one board (#560): tap the first letter and then the last, either way round,
/// or drag between them. Tapping the start again cancels it, with no miss.
nonisolated struct WordSearchSelection: Equatable {
    enum Outcome: Equatable {
        case started
        case cancelled
        case found(String)
        case miss
    }

    let deal: WordSearchDeal
    private(set) var first: Int?
    private(set) var found: Set<String> = []
    private(set) var attempts = 0
    /// Whether the soft "not one of the words" note shows: only right after a miss.
    private(set) var showsMiss = false

    var isComplete: Bool { found.count == deal.words.count }

    mutating func tap(_ cell: Int) -> Outcome {
        guard let start = first else {
            first = cell
            showsMiss = false
            return .started
        }
        if start == cell {
            first = nil
            showsMiss = false
            return .cancelled
        }
        return pick(from: start, to: cell)
    }

    /// A drag that ends where it began is a tap on that letter.
    mutating func drag(from start: Int, to end: Int) -> Outcome {
        start == end ? tap(start) : pick(from: start, to: end)
    }

    /// A line that is not a word still to find counts as a miss.
    mutating func pick(from start: Int, to end: Int) -> Outcome {
        first = nil
        attempts += 1
        guard let word = deal.match(from: start, to: end), found.insert(word).inserted else {
            showsMiss = true
            return .miss
        }
        showsMiss = false
        return .found(word)
    }
}
