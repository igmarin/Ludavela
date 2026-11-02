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
    private static let directions = [(0, 1), (1, 0), (1, 1), (-1, 1)]
    private static let allDirections = directions + [(0, -1), (-1, 0), (-1, -1), (1, -1)]
    /// Sizes and directions change only between the five level bands.
    static func make(
        level: Int, tablet: Bool, spanish isSpanish: Bool, themes: [(String, [String])],
        using random: inout some RandomNumberGenerator
    )
        -> Self
    {
        let band = (max(1, min(level, 10)) - 1) / 2
        let side = (tablet ? [6, 8, 9, 10, 10] : [6, 7, 8, 8, 8])[band]
        // Only words that fit this board can be dealt at this level.
        let eligible = themes.filter { $0.1.filter { $0.count <= side }.count >= 4 + band }
        let theme = eligible.randomElement(using: &random)!
        let texts = Array(theme.1.filter { $0.count <= side }.shuffled(using: &random).prefix(4 + band))
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
            if placed.allSatisfy({ deal.occurrences(of: $0.text) == [$0.cells] }) { return deal }
        }
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

    var isComplete: Bool { found.count == deal.words.count }

    mutating func tap(_ cell: Int) -> Outcome {
        guard let start = first else {
            first = cell
            return .started
        }
        if start == cell {
            first = nil
            return .cancelled
        }
        return pick(from: start, to: cell)
    }

    /// A line that is not a word still to find counts as a miss.
    mutating func pick(from start: Int, to end: Int) -> Outcome {
        first = nil
        attempts += 1
        guard let word = deal.match(from: start, to: end), found.insert(word).inserted else { return .miss }
        return .found(word)
    }
}
