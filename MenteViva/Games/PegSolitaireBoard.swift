import Foundation

/// English cross board. A bit per hole makes legal jumps and undo inexpensive.
nonisolated struct PegSolitaireBoard: Equatable, Sendable {
    /// A jump names its source, the peg removed, and the landing hole.
    struct Move: Equatable, Sendable {
        let from: Int
        let over: Int
        let to: Int
    }

    /// A budget-limited search must not mistake an unfinished search for proof.
    enum Hint: Equatable, Sendable {
        case move(Move)
        case unsolvable
        case inconclusive
        case solved
    }

    static let holes: [(row: Int, column: Int)] = (0..<7).flatMap { row in
        (0..<7).compactMap { column in
            (2...4).contains(row) || (2...4).contains(column) ? (row, column) : nil
        }
    }
    static let allMoves: [Move] = holes.enumerated().flatMap { index, hole in
        [(0, -1), (0, 1), (-1, 0), (1, 0)].compactMap { dr, dc in
            guard let over = holes.firstIndex(where: { $0.row == hole.row + dr && $0.column == hole.column + dc }),
                let to = holes.firstIndex(where: { $0.row == hole.row + 2 * dr && $0.column == hole.column + 2 * dc })
            else { return nil }
            return Move(from: index, over: over, to: to)
        }
    }

    private(set) var pegs: UInt64
    private(set) var history: [UInt64] = []
    private(set) var attempts = 0

    init(pegs: UInt64) { self.pegs = pegs }
    var pegCount: Int { pegs.nonzeroBitCount }
    func contains(_ hole: Int) -> Bool { pegs & (1 << hole) != 0 }
    var moves: [Move] { Self.legalMoves(pegs) }

    private static func legalMoves(_ pegs: UInt64) -> [Move] {
        allMoves.filter { move in
            let occupied = (UInt64(1) << move.from) | (UInt64(1) << move.over)
            return pegs & occupied == occupied && pegs & (UInt64(1) << move.to) == 0
        }
    }

    private static func jumped(_ pegs: UInt64, _ move: Move) -> UInt64 {
        pegs ^ (UInt64(1) << move.from) ^ (UInt64(1) << move.over) ^ (UInt64(1) << move.to)
    }

    mutating func jump(_ move: Move) -> Bool {
        guard moves.contains(move) else { return false }
        history.append(pegs)
        pegs = Self.jumped(pegs, move)
        attempts += 1
        return true
    }

    mutating func undo() -> Bool {
        guard let previous = history.popLast() else { return false }
        pegs = previous
        return true
    }

    /// Reverse jumps each add a peg; the reverse of the resulting path always solves the deal.
    static func deal<R: RandomNumberGenerator>(level: Int, using rng: inout R) -> PegSolitaireBoard {
        let count = [3, 4, 5, 6, 8, 10, 12, 15, 18, 22][min(10, max(1, level)) - 1]
        func grow(_ pegs: UInt64, _ remaining: Int, _ rng: inout R) -> UInt64? {
            if remaining == 0 { return pegs }
            let candidates = allMoves.filter { move in
                let occupied = (UInt64(1) << move.from) | (UInt64(1) << move.over)
                return pegs & occupied == 0 && pegs & (UInt64(1) << move.to) != 0
            }.shuffled(using: &rng)
            for move in candidates {
                if let result = grow(jumped(pegs, move), remaining - 1, &rng) { return result }
            }
            return nil
        }
        let starts = Array(holes.indices).shuffled(using: &rng)
        for start in starts {
            if let pegs = grow(UInt64(1) << start, count - 1, &rng) { return PegSolitaireBoard(pegs: pegs) }
        }
        preconditionFailure("No reverse deal for this level")
    }

    /// Memoized depth-first search returns only a proven next step or a proven dead end.
    func hint(budget: Int = 500_000, cancelled: () -> Bool = { false }) -> Hint {
        if pegCount == 1 { return .solved }
        var seen = Set<UInt64>()
        var remaining = budget
        var exhausted = false
        func solve(_ state: UInt64) -> Bool {
            if state.nonzeroBitCount == 1 { return true }
            if seen.contains(state) { return false }
            guard remaining > 0 && !cancelled() else {
                exhausted = true
                return false
            }
            remaining -= 1
            for move in Self.legalMoves(state) {
                if solve(Self.jumped(state, move)) { return true }
                if exhausted { return false }
            }
            seen.insert(state)
            return false
        }
        guard remaining > 0 && !cancelled() else { return .inconclusive }
        for move in moves {
            if solve(Self.jumped(pegs, move)) { return .move(move) }
            if exhausted { return .inconclusive }
        }
        return .unsolvable
    }
}
