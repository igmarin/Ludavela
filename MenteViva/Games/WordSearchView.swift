import SwiftData
import SwiftUI

/// Find themed words by tapping or dragging between their endpoints.
struct WordSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var difficulty = Difficulty.stored(.wordSearch)
    @State private var game: WordSearchSelection?
    @State private var startedAt = Date.now
    @State private var showMiss = false
    @State private var hint: Int?
    @State private var hintTask: Task<Void, Never>?
    @State private var showCelebration = false
    /// An iPad on its side puts the board beside everything else, so the whole game fits on one screen.
    @State private var wide = false
    /// A finger on the board. SwiftUI clears it when the finger lifts or the touch is cancelled,
    /// so the page can always scroll again.
    @GestureState private var touching = false
    /// The word list's column width grows with the text size, so a word is never broken across lines.
    @ScaledMetric(relativeTo: .title2) private var wordColumn: CGFloat = 140

    /// Cells grow with the screen up to this size; an 8×8 board on an iPhone SE gets 44pt (#560).
    private static let maxCell: CGFloat = 64

    private var instruction: String { AppLanguage.localized("game.wordsearch.instruction") }

    var body: some View {
        HStack(spacing: 24) {
            if wide, let game { board(game) }
            VStack(spacing: 16) {
                LevelExplainBanner(game: .wordSearch, hasStarted: (game?.attempts ?? 0) > 0, keepsSpace: true)
                Text(instruction).font(.title2).multilineTextAlignment(.center)
                if let game {
                    Text(AppLanguage.localized(game.deal.themeKey)).font(.title2.bold())
                    if !wide { board(game) }
                    words(game)
                    if showMiss {
                        Text(AppLanguage.localized("game.wordsearch.miss"))
                            .font(.title2).multilineTextAlignment(.center)
                    }
                    Button(AppLanguage.localized("game.wordsearch.hint"), action: showHint)
                        .buttonStyle(AnswerTileStyle(strength: 0.12, minHeight: 100))
                }
            }
        }
        .gameColumn(maxWidth: wide ? .infinity : GameColumn.maxWidth)
        // A narrow side margin, so an 8×8 board on an iPhone SE keeps 44pt cells.
        .padding(.vertical)
        .padding(.horizontal, 8)
        .fitOrScroll()
        // A drag on the board picks letters and never scrolls the page.
        .scrollDisabled(touching)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onGeometryChange(for: Bool.self) { proxy in
            GameColumn.isPad && proxy.size.width > proxy.size.height
        } action: { isWide in
            wide = isWide
        }
        .gameHeader(.wordSearch, instruction: instruction, inProgress: (game?.attempts ?? 0) > 0, celebrating: showCelebration)
        .firstPlayGuide(
            .wordSearch, line: AppLanguage.localized("game.wordsearch.guide"),
            example: AppLanguage.localized("game.wordsearch.example")
        )
        .onAppear { if game == nil { newDeal() } }
        .onDisappear { hintTask?.cancel() }
        .celebration(
            isPresented: $showCelebration, game: .wordSearch,
            detail: AppLanguage.localized("game.wordsearch.complete"), onPlayAgain: newDeal)
    }

    /// A square as wide as the screen allows, so every letter is always in view.
    private func board(_ game: WordSearchSelection) -> some View {
        Color.clear
            .aspectRatio(1, contentMode: .fit)
            .frame(maxWidth: Self.maxCell * CGFloat(game.deal.side))
            .overlay {
                GeometryReader { proxy in grid(game, cell: proxy.size.width / CGFloat(game.deal.side)) }
            }
    }

    private func grid(_ game: WordSearchSelection, cell: CGFloat) -> some View {
        let side = game.deal.side
        return ZStack(alignment: .topLeading) {
            Canvas { context, _ in
                for word in game.deal.words where game.found.contains(word.text) {
                    guard let start = word.cells.first, let end = word.cells.last else { continue }
                    var line = Path()
                    line.move(to: center(start, side: side, cell: cell))
                    line.addLine(to: center(end, side: side, cell: cell))
                    context.stroke(
                        line, with: .color(GameID.wordSearch.ink.opacity(0.25)),
                        style: StrokeStyle(lineWidth: cell * 0.8, lineCap: .round))
                }
            }
            .accessibilityHidden(true)
            VStack(spacing: 0) {
                ForEach(0..<side, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<side, id: \.self) { column in
                            letter(game, row: row, column: column, cell: cell)
                        }
                    }
                }
            }
        }
        .contentShape(Rectangle())
        // Minimum distance 0, so the board owns the touch from the start and the page's ScrollView
        // never sees it; the same gesture reads taps, since a Button would race it.
        .highPriorityGesture(
            DragGesture(minimumDistance: 0)
                .updating($touching) { _, state, _ in state = true }
                .onEnded { value in
                    guard let start = index(at: value.startLocation, side: side, cell: cell) else { return }
                    // A wobbling finger is still a tap.
                    if hypot(value.translation.width, value.translation.height) < 15 {
                        tap(start)
                    } else if let end = index(at: value.location, side: side, cell: cell), end != start {
                        pick(start, end)
                    }
                })
    }

    private func letter(_ game: WordSearchSelection, row: Int, column: Int, cell: CGFloat) -> some View {
        let index = row * game.deal.side + column
        return Text(String(game.deal.grid[index]))
            .font(.system(size: cell * 0.7, weight: .bold))
            .frame(width: cell, height: cell)
            .overlay {
                if game.first == index || hint == index {
                    Circle().stroke(GameID.wordSearch.ink, lineWidth: 3).padding(2)
                }
            }
            .accessibilityLabel(
                String(
                    format: AppLanguage.localized("game.wordsearch.cell %@ %lld %lld"),
                    String(game.deal.grid[index]), row + 1, column + 1)
            )
            .accessibilityHint(game.first == index ? AppLanguage.localized("game.wordsearch.selected") : "")
            .accessibilityAddTraits(.isButton)
            .accessibilityAction { tap(index) }
    }

    private func center(_ index: Int, side: Int, cell: CGFloat) -> CGPoint {
        CGPoint(x: (CGFloat(index % side) + 0.5) * cell, y: (CGFloat(index / side) + 0.5) * cell)
    }

    private func index(at point: CGPoint, side: Int, cell: CGFloat) -> Int? {
        guard point.x >= 0, point.y >= 0, point.x < CGFloat(side) * cell, point.y < CGFloat(side) * cell else { return nil }
        return Int(point.y / cell) * side + Int(point.x / cell)
    }

    private func words(_ game: WordSearchSelection) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: min(wordColumn, 300)))], spacing: 8) {
            ForEach(game.deal.words, id: \.text) { word in
                let isFound = game.found.contains(word.text)
                HStack {
                    if isFound { Image(systemName: "checkmark").accessibilityHidden(true) }
                    Text(word.text).strikethrough(isFound).font(.title2.bold()).lineLimit(1).minimumScaleFactor(0.5)
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    String(
                        format: AppLanguage.localized(isFound ? "game.wordsearch.found %@" : "game.wordsearch.notfound %@"),
                        word.text))
            }
        }
    }

    private func tap(_ index: Int) {
        guard !showCelebration, let outcome = game?.tap(index) else { return }
        if outcome == .started { showMiss = false }
        show(outcome)
    }

    private func pick(_ start: Int, _ end: Int) {
        guard !showCelebration, let outcome = game?.pick(from: start, to: end) else { return }
        show(outcome)
    }

    private func show(_ outcome: WordSearchSelection.Outcome) {
        guard let game else { return }
        switch outcome {
        case .started, .cancelled:
            return
        case .miss:
            showMiss = true
            Feedback.play(.miss)
            AccessibilityNotification.Announcement(AppLanguage.localized("game.wordsearch.miss")).post()
        case .found(let word):
            showMiss = false
            Feedback.play(.success)
            AccessibilityNotification.Announcement(String(format: AppLanguage.localized("game.wordsearch.found %@"), word))
                .post()
            guard game.isComplete else { return }
            modelContext.record(
                GameSession(
                    gameID: .wordSearch, rounds: game.deal.words.count,
                    durationSeconds: Int(Date.now.timeIntervalSince(startedAt)),
                    correct: game.found.count, attempts: game.attempts, difficulty: difficulty))
            showCelebration = true
        }
    }

    private func showHint() {
        guard let game, let word = game.deal.words.first(where: { !game.found.contains($0.text) }),
            let index = word.cells.first
        else { return }
        hintTask?.cancel()
        hint = index
        AccessibilityNotification.Announcement(
            String(
                format: AppLanguage.localized("game.wordsearch.hintposition %lld %lld"),
                index / game.deal.side + 1, index % game.deal.side + 1)
        ).post()
        hintTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            hint = nil
        }
    }

    private func newDeal() {
        difficulty = Difficulty.stored(.wordSearch)
        var random = SystemRandomNumberGenerator()
        let themes = WordSearchDeal.themeNames.map { name in
            let key = "game.wordsearch.\(name)"
            return (key, AppLanguage.localized(key + ".words").split(separator: ",").map(String.init))
        }
        game = WordSearchSelection(
            deal: WordSearchDeal.make(
                level: difficulty.level, tablet: GameColumn.isPad,
                spanish: AppLanguage.currentLocale.language.languageCode?.identifier == "es", themes: themes,
                using: &random))
        hint = nil
        showMiss = false
        startedAt = .now
    }
}
