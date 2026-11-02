import Foundation

/// Rompecocos / Number Slide (#547): the classic 15-number sliding puzzle, on a 3×3 or 4×4 board.
/// The tiles 1…n²−1 and one gap; the goal is the numbers in reading order with the gap last.
///
/// A tap on any tile in the gap's row or column slides that tile and every tile between it and the
/// gap, as a thumb does on the wooden puzzle. Moves are counted per tile per cell (a tap that pushes
/// three tiles is three moves), the same unit `NumberSlideSolver.fewestMoves` counts in, so a perfect
/// game scores exactly 1 and never more.
///
/// Pure and seeded: no SwiftUI, no clock, no global random generator.
nonisolated struct NumberSlidePuzzle: Hashable, Sendable {
    /// Tiles per side: 3 or 4.
    let size: Int
    /// The board in reading order; 0 is the gap.
    private(set) var tiles: [Int]
    /// The board as dealt, so "Start over" goes back to it.
    let dealt: [Int]
    /// The board before each tap, newest last, so Undo takes back one whole tap.
    private(set) var history: [[Int]] = []
    /// Tiles moved so far, one per tile per cell (see the type's comment). Undo takes them back.
    private(set) var movesMade = 0

    init(size: Int, tiles: [Int]) {
        precondition(tiles.sorted() == Array(0..<size * size), "\(tiles) is not a \(size)×\(size) board")
        self.size = size
        self.tiles = tiles
        self.dealt = tiles
    }

    /// The goal board: 1…n²−1 in reading order, the gap last.
    static func solved(size: Int) -> NumberSlidePuzzle {
        NumberSlidePuzzle(size: size, tiles: Array(1..<size * size) + [0])
    }

    var gap: Int { tiles.firstIndex(of: 0) ?? tiles.count - 1 }

    var isSolved: Bool { tiles.last == 0 && tiles.dropLast().enumerated().allSatisfy { $1 == $0 + 1 } }

    // MARK: - Moves

    /// The way the tile at `cell` slides when tapped: toward the gap when it shares the gap's row or
    /// column, nil otherwise (and for the gap itself). The view's arrows and VoiceOver's actions both
    /// come from here, so neither can offer a slide the board would refuse.
    func direction(ofTileAt cell: Int) -> SlidingDirection? {
        let gap = gap
        guard tiles.indices.contains(cell), cell != gap else { return nil }
        if cell / size == gap / size { return gap > cell ? .right : .left }
        if cell % size == gap % size { return gap > cell ? .down : .up }
        return nil
    }

    /// Slides the tile at `cell`, and every tile between it and the gap, one cell toward the gap; the
    /// gap ends where the tapped tile was. A tile out of the gap's line moves nothing and counts
    /// nothing.
    @discardableResult
    mutating func slide(at cell: Int) -> Bool {
        guard let direction = direction(ofTileAt: cell) else { return false }
        history.append(tiles)
        // The tile beside the gap moves in first, then the next, until the gap reaches `cell`.
        let step = direction.dx + direction.dy * size
        var hole = gap
        while hole != cell {
            tiles.swapAt(hole, hole - step)
            hole -= step
            movesMade += 1
        }
        return true
    }

    /// Takes back the last tap, with the moves it counted.
    @discardableResult
    mutating func undo() -> Bool {
        guard let previous = history.popLast() else { return false }
        let before = previous.firstIndex(of: 0) ?? 0
        let now = gap
        movesMade -= abs(before / size - now / size) + abs(before % size - now % size)
        tiles = previous
        return true
    }

    /// Back to the deal, as if no tile had moved.
    mutating func startOver() {
        tiles = dealt
        history.removeAll()
        movesMade = 0
    }

    /// The cells next to `cell`, in a fixed order (up, down, left, right) so seeded deals and the
    /// solver's search repeat exactly.
    static func neighbours(of cell: Int, size: Int) -> [Int] {
        var out: [Int] = []
        if cell >= size { out.append(cell - size) }
        if cell < size * (size - 1) { out.append(cell + size) }
        if cell % size > 0 { out.append(cell - 1) }
        if cell % size < size - 1 { out.append(cell + 1) }
        return out
    }

    // MARK: - Deals and levels

    /// A deal made only by `moves` random slides from the goal, so it can always be solved (half of
    /// all shuffles cannot). The gap never steps straight back to the cell it just left, and a walk
    /// that happens to end on the goal keeps walking, so no deal starts solved.
    static func scrambled(size: Int, moves: Int, using generator: inout some RandomNumberGenerator) -> NumberSlidePuzzle {
        var board = solved(size: size).tiles
        var gap = board.count - 1
        var previous = -1
        var made = 0
        while made < moves || board == solved(size: size).tiles {
            let options = neighbours(of: gap, size: size).filter { $0 != previous }
            let next = options[Int.random(in: options.indices, using: &generator)]
            board.swapAt(gap, next)
            previous = gap
            gap = next
            made += 1
        }
        return NumberSlidePuzzle(size: size, tiles: board)
    }

    /// Board size, random-walk length and the least `NumberSlideSolver.estimate` a deal may show, per
    /// level 1…10 (#547). Levels 1–5 are 3×3, 6–10 are 4×4; level 5's walk is long enough to mix the
    /// small board fully. A walk can wander back near the goal (levels 4, 5 and 6 each dealt a 2-move
    /// board in 1,000 walks), so a deal that looks closer than `floor` is walked again. Each floor
    /// sits at the closest 5 in 100 walks of its level by `NumberSlideSolver.estimate` (measured for
    /// #547 over 1,000 walks a level), so a re-walk is rare and a level never feels like the one below.
    static let levels: [(size: Int, scramble: ClosedRange<Int>, floor: Int)] = [
        (3, 3...4, 0), (3, 5...7, 0), (3, 8...12, 5), (3, 14...20, 7), (3, 150...200, 10),
        (4, 6...10, 5), (4, 12...18, 8), (4, 20...30, 11), (4, 35...50, 16), (4, 60...80, 22),
    ]

    /// A fresh deal for the player's level.
    static func deal(for difficulty: Difficulty, using generator: inout some RandomNumberGenerator) -> NumberSlidePuzzle {
        let level = difficulty.values(levels)
        while true {
            let moves = Int.random(in: level.scramble, using: &generator)
            let deal = scrambled(size: level.size, moves: moves, using: &generator)
            if NumberSlideSolver.estimate(deal) >= level.floor { return deal }
        }
    }

    // MARK: - The session

    /// The finished game as a saved session (#547): `correct` is the deal's fewest moves, capped at
    /// `attempts` so accuracy never passes 1, and `attempts` is the moves made plus two per shown
    /// move (which also counts in `movesMade`). Two, not Sliding Blocks' one, because this game's
    /// staircase climbs from 0.35 (`DailyPolicy.thresholds`): a game played by "Show me a move"
    /// alone scores 1/3 and holds its level instead of climbing.
    func session(level: Difficulty, fewestMoves: Int, hints: Int, seconds: Int) -> GameSession {
        let attempts = movesMade + 2 * hints
        return GameSession(
            gameID: .numberSlide, rounds: 1, durationSeconds: seconds,
            correct: min(fewestMoves, attempts), attempts: attempts, difficulty: level)
    }
}

// MARK: - Solver

/// "Show me a move" and the deal's fewest moves (#547). IDA* with Manhattan distance plus linear
/// conflict: exact on 3×3, and on 4×4 exact while that fits the node budget. Past the budget it
/// widens the search (weighted IDA*, a solution at most 1.5×, 2× or 3× the shortest), which
/// answers in far fewer nodes; only if even that runs out does it fall back to any slide that
/// lowers the Manhattan distance.
///
/// The budget is counted in nodes, not time, so a hint is the same on every device and in tests.
/// Measured for #547 in a release build on a Mac: the slowest hint over 300 random 60-move 4×4
/// scrambles and 100 level-10 deals took 15 ms (mean 5 ms), well under the 100 ms the brief allows,
/// and following hints from 75 deals of levels 8–10 solved each in the fewest moves or within 8.
nonisolated enum NumberSlideSolver {
    /// Each step of the hint's search: the weight on h (in halves) and the nodes it may search.
    static let hintSteps: [(weight: Int, nodes: Int)] = [(2, 80_000), (3, 25_000), (4, 25_000), (6, 25_000)]
    /// Nodes one hint may search, all steps together.
    static let hintBudget = hintSteps.reduce(0) { $0 + $1.nodes }

    /// The cell to tap for the next move of a short solution: always a tile next to the gap, so one
    /// tap moves one tile. Nil on a solved board.
    static func hint(from puzzle: NumberSlidePuzzle) -> Int? {
        hintSearch(from: puzzle).cell
    }

    /// `hint`, with the nodes it searched and the whole solution it found (empty for the fallback
    /// slide), so the hint-time test can check both.
    static func hintSearch(from puzzle: NumberSlidePuzzle) -> (cell: Int?, nodes: Int, path: [Int]) {
        guard !puzzle.isSolved else { return (nil, 0, []) }
        var spent = 0
        // f = 2g + weight·h, so the weights 2, 3, 4, 6 are h × 1, 1.5, 2, 3.
        for step in hintSteps {
            var search = Search(puzzle: puzzle, weight: step.weight, budget: step.nodes)
            let path = search.run()
            spent += search.nodes
            if let path, let first = path.first { return (first, spent, path) }
        }
        return (fallback(from: puzzle), spent, [])
    }

    /// The deal's fewest moves (one per tile per cell), recorded as `correct`. Exact when the search
    /// fits 3 million nodes (every 3×3 board, and nearly every 4×4 deal); past it, the length the
    /// widened search finds, which can only make the player's accuracy look better, never worse. Up
    /// to about a third of a second on the hardest level-10 deals in a release build, so the view
    /// runs it off the main thread.
    static func fewestMoves(from puzzle: NumberSlidePuzzle) -> Int {
        for (weight, budget) in [(2, 3_000_000), (3, 500_000), (4, 500_000), (6, 500_000)] {
            var search = Search(puzzle: puzzle, weight: weight, budget: budget)
            if let path = search.run() { return path.count }
        }
        return estimate(puzzle)
    }

    /// The linear-conflict cost of every line a board of up to 4×4 can hold, indexed by
    /// `count << 8 | wants`: `count` tiles that belong to the line, and where along it each wants to
    /// be, 2 bits each in board order. 2 × (count − the longest run already in order), found once by
    /// trying every subset. A line with fewer than two of its own tiles has no conflict.
    static let lineCosts: [Int] = (0..<(5 << 8)).map { key in
        let count = key >> 8
        guard count >= 2 else { return 0 }
        let wants = (0..<count).map { (key >> (2 * $0)) & 3 }
        var longest = 1
        for subset in 1..<(1 << count) where subset.nonzeroBitCount > longest {
            let picked = wants.indices.filter { subset & (1 << $0) != 0 }.map { wants[$0] }
            if zip(picked, picked.dropFirst()).allSatisfy({ $0 < $1 }) { longest = subset.nonzeroBitCount }
        }
        return 2 * (count - longest)
    }

    /// Manhattan distance plus linear conflict: never more than the fewest moves, and cheap, so a
    /// deal can be checked for being far enough from the goal without solving it.
    static func estimate(_ puzzle: NumberSlidePuzzle) -> Int {
        let search = Search(puzzle: puzzle, weight: 2, budget: 0)
        return search.manhattan + search.conflicts
    }

    /// A slide of a tile next to the gap that lowers the Manhattan distance, or the first legal one.
    private static func fallback(from puzzle: NumberSlidePuzzle) -> Int? {
        let size = puzzle.size
        let gap = puzzle.gap
        let cells = NumberSlidePuzzle.neighbours(of: gap, size: size)
        return cells.first { cell in
            // True when the tile ends nearer its home cell than it started.
            let goal = puzzle.tiles[cell] - 1
            let before = abs(cell / size - goal / size) + abs(cell % size - goal % size)
            let after = abs(gap / size - goal / size) + abs(gap % size - goal % size)
            return after < before
        } ?? cells.first
    }

    /// One iterative-deepening search. Keeps the board, the gap, the Manhattan distance and each
    /// line's conflict cost up to date move by move, and reads every row, column and distance from
    /// tables made once per search: a node is a few array reads, no division and no allocation.
    private struct Search {
        let size: Int
        let weight: Int
        let budget: Int
        var board: [Int]
        var gap: Int
        var manhattan = 0
        /// Linear conflict per line, rows 0..<size then columns: 2 × the tiles that must leave the
        /// line for the others, already home in it, to pass each other.
        var lineCost: [Int]
        var conflicts = 0
        var nodes = 0
        var path: [Int] = []
        var found = false

        /// Cells a tile at index `tile * cells + cell` is from home.
        private let distance: [Int]
        /// Each cell's row and column, so the hot loop never divides.
        private let rowOf: [Int]
        private let columnOf: [Int]
        /// The cells beside each cell, `cell * 4 + side` (up, down, left, right), -1 past the edge.
        private let beside: [Int]
        /// The cells of each line in order, `line * size + step`.
        private let lineCells: [Int]
        /// Where along `line` a tile wants to be, `line * cells + tile`, or -1 when it belongs to another line.
        private let place: [Int]
        /// `lineCosts`, held here: reading a static in the hot loop costs a lazy-init check each time.
        private let costTable = NumberSlideSolver.lineCosts

        init(puzzle: NumberSlidePuzzle, weight: Int, budget: Int) {
            let size = puzzle.size
            let cells = size * size
            self.size = size
            self.weight = weight
            self.budget = budget
            board = puzzle.tiles
            gap = puzzle.gap
            var distance = Array(repeating: 0, count: cells * cells)
            var beside = Array(repeating: -1, count: cells * 4)
            var lineCells = Array(repeating: 0, count: 2 * size * size)
            var place = Array(repeating: -1, count: 2 * size * cells)
            for cell in 0..<cells {
                for (side, next) in [-size, size, -1, 1].enumerated() {
                    let sameRow = next == -1 || next == 1
                    let inside = cells > cell + next && cell + next >= 0
                    if inside, !sameRow || (cell + next) / size == cell / size { beside[cell * 4 + side] = cell + next }
                }
                for tile in 1..<cells {
                    let home = tile - 1
                    distance[tile * cells + cell] = abs(home / size - cell / size) + abs(home % size - cell % size)
                }
            }
            for index in 0..<size {
                for step in 0..<size {
                    lineCells[index * size + step] = index * size + step
                    lineCells[(size + index) * size + step] = step * size + index
                }
                for tile in 1..<cells {
                    let home = tile - 1
                    if home / size == index { place[index * cells + tile] = home % size }
                    if home % size == index { place[(size + index) * cells + tile] = home / size }
                }
            }
            (self.distance, self.beside, self.lineCells, self.place) = (distance, beside, lineCells, place)
            rowOf = (0..<cells).map { $0 / size }
            columnOf = (0..<cells).map { $0 % size }
            lineCost = Array(repeating: 0, count: 2 * size)
            for cell in board.indices where board[cell] != 0 { manhattan += distance[board[cell] * cells + cell] }
            for line in 0..<2 * size {
                lineCost[line] = cost(ofLine: line)
                conflicts += lineCost[line]
            }
        }

        /// The cells tapped, in order, or nil when the budget ran out first.
        mutating func run() -> [Int]? {
            var bound = weight * (manhattan + conflicts)
            while true {
                let next = deepen(depth: 0, bound: bound, cameFrom: -1)
                if found { return path }
                if nodes >= budget || next == Int.max { return nil }
                bound = next
            }
        }

        /// Depth-first below `bound`; returns the smallest f seen past it.
        private mutating func deepen(depth: Int, bound: Int, cameFrom: Int) -> Int {
            let h = manhattan + conflicts
            let f = 2 * depth + weight * h
            if f > bound { return f }
            if h == 0 {
                found = true
                return f
            }
            nodes += 1
            if nodes >= budget { return Int.max }
            var smallest = Int.max
            let here = gap
            for side in 0..<4 {
                let cell = beside[here * 4 + side]
                guard cell >= 0, cell != cameFrom else { continue }
                move(from: cell)
                path.append(cell)
                let next = deepen(depth: depth + 1, bound: bound, cameFrom: here)
                if found || nodes >= budget { return next }
                path.removeLast()
                move(from: here)
                smallest = min(smallest, next)
            }
            return smallest
        }

        /// The tile at `cell` slides into the gap.
        private mutating func move(from cell: Int) {
            let tile = board[cell]
            let to = gap
            let cells = board.count
            manhattan += distance[tile * cells + to] - distance[tile * cells + cell]
            board[to] = tile
            board[cell] = 0
            gap = cell
            // A sideways slide (the cells one apart) moves the tile between two columns, an up-down
            // slide between two rows. Only the tile's own column (or row) can gain or lose a
            // conflict, and only when it is one of the two.
            let home = tile - 1
            if abs(cell - to) == 1 {
                let line = columnOf[home]
                if line == columnOf[cell] || line == columnOf[to] { recount(line: size + line) }
            } else {
                let line = rowOf[home]
                if line == rowOf[cell] || line == rowOf[to] { recount(line: line) }
            }
        }

        private mutating func recount(line: Int) {
            let cost = cost(ofLine: line)
            conflicts += cost - lineCost[line]
            lineCost[line] = cost
        }

        /// 2 × (tiles home in this line − the longest run of them already in order), read from
        /// `lineCosts`.
        private func cost(ofLine line: Int) -> Int {
            // Where along the line each tile that belongs to it wants to be, 2 bits each, in board order.
            var wants = 0
            var count = 0
            let cells = board.count
            for step in 0..<size {
                let want = place[line * cells + board[lineCells[line * size + step]]]
                guard want >= 0 else { continue }
                wants |= want << (2 * count)
                count += 1
            }
            return costTable[count << 8 | wants]
        }
    }
}
