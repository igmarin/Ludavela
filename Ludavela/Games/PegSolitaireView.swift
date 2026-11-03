import SwiftData
import SwiftUI

/// A hand-drawn peg board. Rules and the solution search stay in the pure board type.
struct PegSolitaireView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var difficulty = Difficulty.stored(.pegSolitaire)
    @State private var board: PegSolitaireBoard?
    @State private var initial: PegSolitaireBoard?
    @State private var selected: Int?
    @State private var hinted: PegSolitaireBoard.Move?
    @State private var attempts = 0
    @State private var note: String?
    @State private var searching = false
    @State private var pointsToUndo = false
    @State private var startedAt = Date.now
    @State private var showCelebration = false
    @State private var searchID = 0
    @State private var hintTask: Task<PegSolitaireBoard.Hint, Never>?

    private var instruction: String { AppLanguage.localized("game.peg.instruction") }

    var body: some View {
        VStack(spacing: 16) {
            LevelExplainBanner(game: .pegSolitaire, hasStarted: !(board?.history.isEmpty ?? true), keepsSpace: true)
            Text(instruction).font(.title2).multilineTextAlignment(.center)
            boardArea
            if let note {
                AlmostNote(text: note)
                if pointsToUndo {
                    Image(systemName: "arrow.down").font(.title.bold()).accessibilityHidden(true)
                }
            }
            controls
        }
        .padding()
        .fitOrScroll()
        .gameHeader(
            .pegSolitaire, instruction: instruction, inProgress: !(board?.history.isEmpty ?? true), celebrating: showCelebration
        )
        .firstPlayGuide(
            .pegSolitaire, line: AppLanguage.localized("game.peg.guide"), example: AppLanguage.localized("game.peg.example")
        )
        .onAppear { if board == nil { deal() } }
        .onDisappear {
            hintTask?.cancel()
            searchID += 1
            searching = false
        }
        .celebration(
            isPresented: $showCelebration, game: .pegSolitaire, detail: AppLanguage.localized("game.peg.win"), onPlayAgain: deal)
    }

    /// Hole index at `[row][column]`, nil off the cross; built once, not on every render.
    private static let holeAt: [[Int?]] = (0..<7).map { row in
        (0..<7).map { column in PegSolitaireBoard.holes.firstIndex { $0.row == row && $0.column == column } }
    }

    /// A square as wide as the screen allows (at most 7 x 60pt), so the board never scrolls sideways.
    private var boardArea: some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: 420)
            .overlay { GeometryReader { proxy in boardView(cell: min(60, proxy.size.width / 7)) } }
    }

    private func boardView(cell: CGFloat) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { row in
                HStack(spacing: 0) {
                    ForEach(0..<7, id: \.self) { column in
                        if let index = Self.holeAt[row][column] {
                            hole(index, cell: cell)
                        } else {
                            Color.clear.frame(width: cell, height: cell).accessibilityHidden(true)
                        }
                    }
                }
            }
        }
        .background(Color.amber.opacity(0.35), in: RoundedRectangle(cornerRadius: 20))
        .accessibilityElement(children: .contain)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func hole(_ index: Int, cell: CGFloat) -> some View {
        let occupied = board?.contains(index) == true
        let jumps = board?.moves.filter { $0.from == index } ?? []
        let landing = board?.moves.first { $0.from == selected && $0.to == index && (hinted == nil || hinted == $0) }
        let position = PegSolitaireBoard.holes[index]
        return Button {
            tap(index)
        } label: {
            ZStack {
                Circle().fill(Color.espresso.opacity(0.25)).frame(width: cell * 0.73, height: cell * 0.73)
                if occupied {
                    Circle().fill(GameID.pegSolitaire.ink)
                        .overlay(Circle().strokeBorder(Color.paper, lineWidth: selected == index ? 4 : 2))
                        .frame(width: cell * 0.73, height: cell * 0.73)
                        .offset(y: selected == index ? -cell / 12 : 0)
                }
                if let landing {
                    Circle().strokeBorder(Color.espresso, lineWidth: 3).frame(width: cell * 0.83, height: cell * 0.83)
                    Image(systemName: arrow(for: landing))
                        .foregroundStyle(Color.espresso)
                        .font(.system(size: cell * 0.4, weight: .bold))
                }
            }
            .frame(width: cell, height: cell)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(
            AppLanguage.localized("game.peg.cell \(position.row + 1) \(position.column + 1)" as String.LocalizationValue)
        )
        .accessibilityValue(AppLanguage.localized(occupied ? "game.peg.occupied" : "game.peg.empty"))
        .accessibilityActions {
            ForEach(jumps, id: \.to) { move in
                Button(AppLanguage.localized("game.peg.\(direction(for: move))")) { apply(move) }
            }
        }
    }

    private var controls: some View {
        VStack(spacing: 10) {
            control("game.sliding.undo", enabled: !(board?.history.isEmpty ?? true), action: undo)
            control("game.sliding.restart", enabled: !(board?.history.isEmpty ?? true), action: restart)
            control("game.sliding.hint", enabled: board != nil && !searching, action: hint)
        }
    }

    private func control(_ key: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) { Text(AppLanguage.localized(key)).font(.title2.weight(.semibold)).frame(maxWidth: .infinity) }
            .buttonStyle(AnswerTileStyle(minHeight: 100)).disabled(!enabled)
    }

    private func tap(_ index: Int) {
        guard let board else { return }
        if let move = board.moves.first(where: { $0.from == selected && $0.to == index }) {
            apply(move)
        } else if board.contains(index) && board.moves.contains(where: { $0.from == index }) {
            selected = selected == index ? nil : index
            hinted = nil
            Feedback.play(.tap)
        } else {
            Feedback.play(.miss)
        }
    }

    private func apply(_ move: PegSolitaireBoard.Move) {
        guard var current = board, current.jump(move) else { return }
        hintTask?.cancel()
        searchID += 1
        searching = false
        note = nil
        pointsToUndo = false
        selected = nil
        hinted = nil
        // Undone and restarted jumps count on purpose: they are the struggle signal.
        attempts += 1
        withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.25)) { board = current }
        Feedback.play(.tap)
        if current.pegCount > 1 && current.moves.isEmpty {
            note = AppLanguage.localized("game.peg.unsolvable")
            pointsToUndo = true
        }
        if current.pegCount == 1 {
            modelContext.record(
                GameSession(
                    gameID: .pegSolitaire, rounds: 1, durationSeconds: Int(Date.now.timeIntervalSince(startedAt)),
                    correct: (initial?.pegCount ?? 1) - 1, attempts: attempts, difficulty: difficulty))
            showCelebration = true
        }
    }

    private func undo() {
        guard var current = board, current.undo() else { return }
        hintTask?.cancel()
        searchID += 1
        searching = false
        note = nil
        pointsToUndo = false
        selected = nil
        hinted = nil
        board = current
        Feedback.play(.tap)
    }

    private func restart() {
        guard let initial else { return }
        hintTask?.cancel()
        searchID += 1
        searching = false
        note = nil
        pointsToUndo = false
        selected = nil
        hinted = nil
        board = initial
        Feedback.play(.tap)
    }

    private func deal() {
        difficulty = Difficulty.stored(.pegSolitaire)
        var rng = SystemRandomNumberGenerator()
        let fresh = PegSolitaireBoard.deal(level: difficulty.level, using: &rng)
        board = fresh
        initial = fresh
        selected = nil
        hinted = nil
        attempts = 0
        note = nil
        pointsToUndo = false
        startedAt = .now
    }

    /// Search away from the main thread and discard an answer if the board changed meanwhile.
    private func hint() {
        guard let current = board else { return }
        hintTask?.cancel()
        searchID += 1
        let id = searchID
        searching = true
        let work = Task.detached { current.hint(cancelled: { Task.isCancelled }) }
        hintTask = work
        Task {
            let result = await work.value
            guard id == searchID else { return }
            searching = false
            switch result {
            case .move(let move):
                selected = move.from
                hinted = move
                note = nil
                pointsToUndo = false
            case .unsolvable:
                selected = nil
                note = AppLanguage.localized("game.peg.unsolvable")
                pointsToUndo = true
            case .inconclusive:
                selected = nil
                note = AppLanguage.localized("game.peg.searchmore")
                pointsToUndo = false
            case .solved: break
            }
        }
    }

    private func direction(for move: PegSolitaireBoard.Move) -> String {
        let from = PegSolitaireBoard.holes[move.from]
        let to = PegSolitaireBoard.holes[move.to]
        if to.row < from.row { return "up" }
        if to.row > from.row { return "down" }
        return to.column < from.column ? "left" : "right"
    }

    private func arrow(for move: PegSolitaireBoard.Move) -> String { "arrow.\(direction(for: move))" }
}
