import SwiftData
import SwiftUI

/// Find themed words by tapping or dragging between their endpoints.
/// #599: the grid sits on the approved table without taking room from it (docs/design/2026-11-03-sobremesa.md).
struct WordSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var difficulty = Difficulty.stored(.wordSearch)
    @State private var game: WordSearchSelection?
    @State private var startedAt = Date.now
    @State private var hint: Int?
    @State private var hintTask: Task<Void, Never>?
    @State private var showCelebration = false
    /// The play area inside the screen's margins. Zero until measured; the first deal waits for it.
    @State private var area = CGSize.zero
    /// A finger on the board. SwiftUI clears it when the finger lifts or the touch is cancelled,
    /// so the page can always scroll again.
    @GestureState private var touching = false
    /// The word list's column width grows with the text size, so a word is never broken across lines.
    @ScaledMetric(relativeTo: .title2) private var wordColumn: CGFloat = 140

    /// An iPad on its side puts the board beside everything else, so the whole game fits on one screen.
    private var wide: Bool { GameColumn.isPad && area.width > area.height }

    /// The width the board may take: the screen's on a phone, the centred column's on an iPad, and
    /// beside the word list (at least 300pt wide) on an iPad on its side, where the height counts too.
    private var boardSpace: Double {
        if wide { return min(area.height, area.width - 24 - 300) }
        return GameColumn.isPad ? min(area.width, GameColumn.maxWidth) : area.width
    }

    private var instruction: String { AppLanguage.localized("game.wordsearch.instruction") }

    var body: some View {
        HStack(spacing: 24) {
            if wide, let game { board(game) }
            VStack(spacing: 16) {
                LevelExplainBanner(game: .wordSearch, hasStarted: (game?.attempts ?? 0) > 0, keepsSpace: true)
                Text(instruction)
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(Color.espresso)
                    .multilineTextAlignment(.center)
                if let game {
                    Text(AppLanguage.localized(game.deal.themeKey)).font(.title2.bold())
                    if !wide { board(game) }
                    words(game)
                    if game.showsMiss {
                        Text(AppLanguage.localized("game.wordsearch.miss"))
                            .font(.title2).multilineTextAlignment(.center)
                    }
                    Button(AppLanguage.localized("game.wordsearch.hint"), action: showHint)
                        .buttonStyle(AnswerTileStyle(strength: 0.12, minHeight: 100))
                }
            }
        }
        .gameColumn(maxWidth: wide ? .infinity : GameColumn.maxWidth)
        // A narrow side margin, so a 375pt iPhone SE fits six 60pt squares.
        .padding(.vertical)
        .padding(.horizontal, WordSearchDeal.sideMargin)
        .fitOrScroll()
        // A drag on the board picks letters and never scrolls the page.
        .scrollDisabled(touching)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Measured outside the padding and the fit-or-scroll, so it is the space the screen offers.
        .onGeometryChange(for: CGSize.self) {
            CGSize(width: $0.size.width - 2 * WordSearchDeal.sideMargin, height: $0.size.height - 32)
        } action: { size in
            guard size.width > 0, size.height > 0 else { return }
            area = size
            // As in Sudoku: a board that no longer fits with 60pt squares is dealt again at a size
            // that does; one that still fits keeps its progress.
            if let game, Double(game.deal.side) * WordSearchDeal.minCell <= boardSpace { return }
            newDeal()
        }
        .gameHeader(.wordSearch, instruction: instruction, inProgress: (game?.attempts ?? 0) > 0, celebrating: showCelebration)
        .firstPlayGuide(
            .wordSearch, line: AppLanguage.localized("game.wordsearch.guide"),
            example: AppLanguage.localized("game.wordsearch.example")
        )
        .onDisappear { hintTask?.cancel() }
        .celebration(
            isPresented: $showCelebration, game: .wordSearch,
            detail: AppLanguage.localized("game.wordsearch.complete"), onPlayAgain: newDeal)
    }

    /// The whole grid at once, with squares of 60 to 64pt.
    private func board(_ game: WordSearchSelection) -> some View {
        let cell = WordSearchDeal.cell(side: game.deal.side, space: boardSpace)
        return grid(game, cell: cell).frame(width: cell * Double(game.deal.side), height: cell * Double(game.deal.side))
            // The flat jade table (#599, as Memory Lane #582), drawn outside the grid's own space so the
            // squares keep the width they were dealt by. 4pt, the screen's side margin: on an iPhone SE
            // the 367pt grid leaves room for no more, and the table must not leave the screen.
            .padding(WordSearchDeal.sideMargin)
            .background(Color.tableSurface, in: .rect(cornerRadius: 30))
            .padding(-WordSearchDeal.sideMargin)
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
                    // A wobbling finger is still a tap; so is a drag that ends where it began.
                    let wobble = hypot(value.translation.width, value.translation.height) < 15
                    guard let end = wobble ? start : index(at: value.location, side: side, cell: cell) else { return }
                    drag(start, end)
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
                // The tick goes above a word too long to share its line, so no word is ever broken.
                ViewThatFits(in: .horizontal) {
                    HStack { listed(word.text, isFound: isFound) }
                    VStack { listed(word.text, isFound: isFound) }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(
                    String(
                        format: AppLanguage.localized(isFound ? "game.wordsearch.found %@" : "game.wordsearch.notfound %@"),
                        word.text))
            }
        }
    }

    @ViewBuilder
    private func listed(_ text: String, isFound: Bool) -> some View {
        if isFound { Image(systemName: "checkmark").font(.title2).accessibilityHidden(true) }
        Text(text).strikethrough(isFound).font(.title2.bold()).fixedSize()
    }

    private func tap(_ index: Int) {
        guard !showCelebration, let outcome = game?.tap(index) else { return }
        show(outcome)
    }

    private func drag(_ start: Int, _ end: Int) {
        guard !showCelebration, let outcome = game?.drag(from: start, to: end) else { return }
        show(outcome)
    }

    private func show(_ outcome: WordSearchSelection.Outcome) {
        guard let game else { return }
        switch outcome {
        case .started, .cancelled:
            return
        case .miss:
            Feedback.play(.miss)
            AccessibilityNotification.Announcement(AppLanguage.localized("game.wordsearch.miss")).post()
        case .found(let word):
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
                level: difficulty.level, tablet: GameColumn.isPad, space: boardSpace,
                spanish: AppLanguage.currentLocale.language.languageCode?.identifier == "es", themes: themes,
                using: &random))
        hint = nil
        startedAt = .now
    }
}
