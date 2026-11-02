import SwiftData
import SwiftUI
import UIKit

/// Find themed words by tapping or dragging between their endpoints.
struct WordSearchView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var difficulty = Difficulty.stored(.wordSearch)
    @State private var deal: WordSearchDeal?
    @State private var first: Int?
    @State private var found: Set<String> = []
    @State private var attempts = 0
    @State private var startedAt = Date.now
    @State private var showMiss = false
    @State private var hint: Int?
    @State private var hintTask: Task<Void, Never>?
    @State private var showCelebration = false
    @State private var boardOffset: CGFloat = 0
    @State private var boardWidth: CGFloat = 0
    @State private var boardOffsetY: CGFloat = 0
    @State private var dragging = false
    @State private var dragStart: Int?
    @State private var dragPoint: CGPoint = .zero
    @State private var dragTask: Task<Void, Never>?
    private let cell: CGFloat = 100

    private var instruction: String { AppLanguage.localized("game.wordsearch.instruction") }

    var body: some View {
        ScrollViewReader { proxy in
            VStack(spacing: 16) {
                LevelExplainBanner(game: .wordSearch, hasStarted: attempts > 0, keepsSpace: true)
                Text(instruction).font(.title2).multilineTextAlignment(.center)
                if let deal {
                    Text(AppLanguage.localized(deal.themeKey)).font(.title2.bold())
                    GeometryReader { geometry in
                        board(deal)
                            .offset(x: -boardOffset, y: -boardOffsetY)
                            .onAppear { boardWidth = geometry.size.width }
                            .onChange(of: geometry.size.width) { _, width in
                                boardWidth = width
                                boardOffset = min(boardOffset, max(0, CGFloat(deal.side) * cell - width))
                            }
                    }
                    .frame(height: boardHeight(deal))
                    .clipped()
                    .coordinateSpace(name: "wordsearch.viewport")
                    .id("wordsearch.board")
                    if CGFloat(deal.side) * cell > boardWidth {
                        HStack {
                            pageButton("game.wordsearch.previous", symbol: "chevron.left", forward: false, deal: deal)
                            pageButton("game.wordsearch.next", symbol: "chevron.right", forward: true, deal: deal)
                        }
                    }
                    if CGFloat(deal.side) * cell > boardHeight(deal) {
                        HStack {
                            pageButton("game.wordsearch.up", symbol: "chevron.up", forward: false, deal: deal, vertical: true)
                            pageButton("game.wordsearch.down", symbol: "chevron.down", forward: true, deal: deal, vertical: true)
                        }
                    }
                    words(deal)
                    if showMiss {
                        Text(AppLanguage.localized("game.wordsearch.miss"))
                            .font(.title2).multilineTextAlignment(.center)
                    }
                    Button(AppLanguage.localized("game.wordsearch.hint"), action: showHint)
                        .buttonStyle(AnswerTileStyle(strength: 0.12, minHeight: 100))
                }
            }
            .padding()
            .fitOrScroll()
            .scrollDisabled(dragging)
            .onChange(of: hint) { _, index in
                if index != nil { proxy.scrollTo("wordsearch.board", anchor: .center) }
            }
        }
        .gameHeader(.wordSearch, instruction: instruction, inProgress: attempts > 0, celebrating: showCelebration)
        .firstPlayGuide(
            .wordSearch, line: AppLanguage.localized("game.wordsearch.guide"),
            example: AppLanguage.localized("game.wordsearch.example")
        )
        .onAppear { if deal == nil { newDeal() } }
        .onDisappear {
            hintTask?.cancel()
            dragTask?.cancel()
        }
        .celebration(
            isPresented: $showCelebration, game: .wordSearch,
            detail: AppLanguage.localized("game.wordsearch.complete"), onPlayAgain: newDeal)
    }

    /// The fixed 100-point cells remain tappable on small phones; the board scrolls sideways when needed.
    private func board(_ deal: WordSearchDeal) -> some View {
        ZStack(alignment: .topLeading) {
            Canvas { context, _ in
                for word in deal.words where found.contains(word.text) {
                    guard let start = word.cells.first, let end = word.cells.last else { continue }
                    var line = Path()
                    line.move(to: center(start, side: deal.side))
                    line.addLine(to: center(end, side: deal.side))
                    context.stroke(
                        line, with: .color(GameID.wordSearch.ink.opacity(0.25)),
                        style: StrokeStyle(lineWidth: 44, lineCap: .round))
                }
            }
            .accessibilityHidden(true)
            VStack(spacing: 0) {
                ForEach(0..<deal.side, id: \.self) { row in
                    HStack(spacing: 0) {
                        ForEach(0..<deal.side, id: \.self) { column in
                            let index = row * deal.side + column
                            Button {
                                tap(index)
                            } label: {
                                Text(String(deal.grid[index]))
                                    .font(.system(size: 44, weight: .bold))
                                    .frame(width: cell, height: cell)
                                    .contentShape(Rectangle())
                                    .overlay {
                                        if first == index || hint == index {
                                            Circle().stroke(GameID.wordSearch.ink, lineWidth: 3).padding(3)
                                        }
                                    }
                            }
                            .buttonStyle(.plain)
                            .accessibilityHint(first == index ? AppLanguage.localized("game.wordsearch.selected") : "")
                            .accessibilityLabel(
                                String(
                                    format: AppLanguage.localized("game.wordsearch.cell %@ %lld %lld"),
                                    String(deal.grid[index]), row + 1, column + 1))
                        }
                    }
                }
            }
        }
        .frame(width: CGFloat(deal.side) * cell, height: CGFloat(deal.side) * cell)
        .simultaneousGesture(
            DragGesture(minimumDistance: 15, coordinateSpace: .named("wordsearch.viewport"))
                .onChanged { value in
                    dragPoint = value.location
                    if !dragging {
                        dragging = true
                        dragStart = index(
                            at: CGPoint(x: value.startLocation.x + boardOffset, y: value.startLocation.y + boardOffsetY),
                            side: deal.side)
                        dragTask = Task { @MainActor in
                            while !Task.isCancelled {
                                try? await Task.sleep(for: .milliseconds(200))
                                guard !Task.isCancelled else { return }
                                scrollDuringDrag(deal)
                            }
                        }
                    }
                }
                .onEnded { value in
                    dragTask?.cancel()
                    dragging = false
                    let point = CGPoint(x: value.location.x + boardOffset, y: value.location.y + boardOffsetY)
                    guard let start = dragStart, let end = index(at: point, side: deal.side), start != end else { return }
                    dragStart = nil
                    first = nil
                    select(start, end)
                })
    }

    /// Holding near a viewport edge reveals the next cells during a long drag.
    private func scrollDuringDrag(_ deal: WordSearchDeal) {
        let edge: CGFloat = 40
        func movement(_ position: CGFloat, extent: CGFloat) -> CGFloat {
            if position < edge { return -30 }
            if position > extent - edge { return 30 }
            return 0
        }
        boardOffset = min(
            max(0, boardOffset + movement(dragPoint.x, extent: boardWidth)), max(0, CGFloat(deal.side) * cell - boardWidth))
        boardOffsetY = min(
            max(0, boardOffsetY + movement(dragPoint.y, extent: boardHeight(deal))),
            max(0, CGFloat(deal.side) * cell - boardHeight(deal)))
    }

    /// Paging keeps horizontal swipes reserved for selecting words, so scrolling cannot count a miss.
    private func boardHeight(_ deal: WordSearchDeal) -> CGFloat {
        min(400, CGFloat(deal.side) * cell)
    }

    private func pageButton(
        _ key: String, symbol: String, forward: Bool, deal: WordSearchDeal, vertical: Bool = false
    ) -> some View {
        let extent = vertical ? boardHeight(deal) : boardWidth
        let offset = vertical ? boardOffsetY : boardOffset
        let limit = max(0, CGFloat(deal.side) * cell - extent)
        return Button {
            let step = max(cell, extent - cell)
            let next = min(limit, max(0, offset + (forward ? step : -step)))
            if vertical { boardOffsetY = next } else { boardOffset = next }
        } label: {
            Image(systemName: symbol).font(.title.bold()).frame(width: 100, height: 100)
        }
        .buttonStyle(AnswerTileStyle(strength: 0.12, minHeight: 100))
        .disabled(forward ? offset >= limit : offset <= 0)
        .accessibilityLabel(AppLanguage.localized(key))
    }

    private func center(_ index: Int, side: Int) -> CGPoint {
        CGPoint(x: (CGFloat(index % side) + 0.5) * cell, y: (CGFloat(index / side) + 0.5) * cell)
    }

    private func index(at point: CGPoint, side: Int) -> Int? {
        guard point.x >= 0, point.y >= 0, point.x < CGFloat(side) * cell, point.y < CGFloat(side) * cell else { return nil }
        return Int(point.y / cell) * side + Int(point.x / cell)
    }

    private func words(_ deal: WordSearchDeal) -> some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 140))], spacing: 8) {
            ForEach(deal.words, id: \.text) { word in
                let isFound = found.contains(word.text)
                HStack {
                    if isFound { Image(systemName: "checkmark").accessibilityHidden(true) }
                    Text(word.text).strikethrough(isFound).font(.title2.bold())
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
        if let first {
            self.first = nil
            select(first, index)
        } else {
            first = index
            showMiss = false
        }
    }

    private func select(_ start: Int, _ end: Int) {
        guard let deal, !showCelebration else { return }
        guard let word = deal.match(from: start, to: end), !found.contains(word) else {
            attempts += 1
            showMiss = true
            Feedback.play(.miss)
            AccessibilityNotification.Announcement(AppLanguage.localized("game.wordsearch.miss")).post()
            return
        }
        attempts += 1
        found.insert(word)
        showMiss = false
        Feedback.play(.success)
        AccessibilityNotification.Announcement(String(format: AppLanguage.localized("game.wordsearch.found %@"), word)).post()
        if found.count == deal.words.count {
            modelContext.record(
                GameSession(
                    gameID: .wordSearch, rounds: deal.words.count, durationSeconds: Int(Date.now.timeIntervalSince(startedAt)),
                    correct: found.count, attempts: attempts, difficulty: difficulty))
            showCelebration = true
        }
    }

    private func showHint() {
        guard let word = deal?.words.first(where: { !found.contains($0.text) }) else { return }
        hintTask?.cancel()
        hint = word.cells.first
        if let index = hint, let deal {
            let side = deal.side
            boardOffset = min(max(0, CGFloat(index % side) * cell - cell), max(0, CGFloat(side) * cell - boardWidth))
            boardOffsetY = min(max(0, CGFloat(index / side) * cell - cell), max(0, CGFloat(side) * cell - boardHeight(deal)))
            AccessibilityNotification.Announcement(
                String(
                    format: AppLanguage.localized("game.wordsearch.hintposition %lld %lld"),
                    index / side + 1, index % side + 1)
            ).post()
        }
        hintTask = Task { @MainActor in
            try? await Task.sleep(for: .seconds(3))
            guard !Task.isCancelled else { return }
            hint = nil
        }
    }

    private func newDeal() {
        difficulty = Difficulty.stored(.wordSearch)
        var random = SystemRandomNumberGenerator()
        let themes = ["animals", "garden", "music"].map { name in
            let key = "game.wordsearch.\(name)"
            return (key, AppLanguage.localized(key + ".words").split(separator: ",").map(String.init))
        }
        deal = WordSearchDeal.make(
            level: difficulty.level, tablet: UIDevice.current.userInterfaceIdiom == .pad,
            spanish: AppLanguage.currentLocale.language.languageCode?.identifier == "es", themes: themes, using: &random)
        found = []
        boardOffset = 0
        boardOffsetY = 0
        first = nil
        hint = nil
        attempts = 0
        showMiss = false
        startedAt = .now
    }
}
