import SwiftData
import SwiftUI

/// Rompecocos / Number Slide (#547): the 15-number sliding puzzle, drawn as the wooden tray and
/// cream tiles of the toy. Tap a tile in the gap's row or column and it slides, pushing the tiles
/// between it and the gap, as a thumb does on the real one; a swipe toward the gap does the same.
/// Each tile that can move shows a small arrow toward the gap, so the cue never rests on colour.
/// The rules live in `NumberSlidePuzzle` and `NumberSlideSolver`; this view owns taps, drawing and
/// the celebration. A tap that can't move anything does nothing and counts nothing, so there is no
/// miss copy at all.
struct NumberSlideView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    /// Re-read on every deal, so "Play again" follows a level change.
    @State private var difficulty = Difficulty.stored(.numberSlide)
    @State private var puzzle: NumberSlidePuzzle?
    /// The deal's fewest moves, recorded as `correct`. Worked out off the main thread at the deal
    /// (up to half a second on the hardest 4×4 deals), long before anyone finishes.
    @State private var fewest: Task<Int?, Never>?
    /// The tile "Show me a move" just slid, ringed in amber until the next move, so the eye finds
    /// it even when Reduce Motion lands it at once.
    @State private var shownTile: Int?
    /// The tile the first-play guide rings, the one that slides next on the way home: worked out
    /// once per deal while the guide still has to show, never on each redraw (a 4×4 hint can search
    /// 155,000 nodes). The guide covers the board until it is dismissed, so the deal is the only
    /// board it ever points at.
    @State private var guideTile: Int?
    @State private var hintsUsed = 0
    /// True for the three seconds the finished board lies over the real one (#630).
    @State private var showingGoal = false
    @State private var goalTask: Task<Void, Never>?
    @State private var startedAt = Date.now
    @State private var showCelebration = false
    @State private var finalDetail = ""

    private var instruction: String { AppLanguage.localized("game.numberslide.instruction") }
    private var hasMoved: Bool { (puzzle?.movesMade ?? 0) > 0 }

    var body: some View {
        VStack(spacing: 16) {
            LevelExplainBanner(game: GameID.numberSlide, hasStarted: hasMoved, keepsSpace: true)
            goalAndInstruction

            board
                .frame(minHeight: 300)
                // While the goal shows, the board is a picture: no slides, nothing for VoiceOver to act on.
                .allowsHitTesting(!showingGoal)
                .accessibilityHidden(showingGoal)

            controls
        }
        .gameColumn()
        .padding()
        .fitOrScroll()
        .gameHeader(.numberSlide, instruction: instruction, inProgress: hasMoved, celebrating: showCelebration)
        .firstPlayGuide(
            .numberSlide, line: AppLanguage.localized("game.numberslide.guide"),
            example: AppLanguage.localized("guide.numberslide.example")
        )
        .onAppear {
            if let puzzle {
                // Coming back to a deal whose count leaving the screen cancelled: count it again.
                if fewest?.isCancelled ?? true { countFewest(NumberSlidePuzzle(size: puzzle.size, tiles: puzzle.dealt)) }
            } else {
                deal()
            }
        }
        .onDisappear {
            fewest?.cancel()
            goalTask?.cancel()
            showingGoal = false
        }
        .celebration(isPresented: $showCelebration, game: .numberSlide, detail: finalDetail, onPlayAgain: deal)
    }

    // MARK: - Board

    /// The tray's wooden rim around the tiles, in points.
    private let rim: CGFloat = 10

    private var board: some View {
        GeometryReader { proxy in
            if let puzzle = showingGoal ? puzzle.map({ NumberSlidePuzzle.solved(size: $0.size) }) : puzzle {
                let inner = CGSize(width: proxy.size.width - 2 * rim, height: proxy.size.height - 2 * rim)
                let cell = SlidingBoardLayout.cellSize(in: inner, columns: puzzle.size, rows: puzzle.size)
                let side = cell * CGFloat(puzzle.size)
                ZStack(alignment: .topLeading) {
                    // The tray's floor: what shows through the gap, a dark recess in the wood.
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.black.opacity(0.38))
                        .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(Color.black.opacity(0.3), lineWidth: 3))
                        .frame(width: side, height: side)
                        .accessibilityHidden(true)
                    gapLabel(in: puzzle, cell: cell)
                    ForEach(1..<puzzle.tiles.count, id: \.self) { number in
                        tile(number, in: puzzle, cell: cell, isGuideTarget: number == guideTile)
                    }
                }
                .frame(width: side, height: side)
                .padding(rim)
                .background(Wood.tray, in: RoundedRectangle(cornerRadius: 16))
                .compositingGroup()
                .shadow(color: .black.opacity(0.25), radius: 0, x: 3, y: 3)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .accessibilityElement(children: .contain)
    }

    /// One tile: cream wood with its number in the game's crimson, a print shadow, and a small
    /// arrow on the edge facing the gap when it can slide.
    private func tile(_ number: Int, in puzzle: NumberSlidePuzzle, cell: CGFloat, isGuideTarget: Bool) -> some View {
        let index = puzzle.tiles.firstIndex(of: number) ?? 0
        // The goal is a picture: no arrows on it, so nothing suggests a move to make.
        let direction = showingGoal ? nil : puzzle.direction(ofTileAt: index)
        let shape = RoundedRectangle(cornerRadius: cell * 0.14)
        let isShown = shownTile == number
        return
            shape
            .fill(LinearGradient(colors: [Wood.faceLight, Wood.face], startPoint: .topLeading, endPoint: .bottomTrailing))
            .overlay(shape.strokeBorder(isShown ? Color.amber : Wood.edge, lineWidth: isShown ? 5 : 1.5))
            .overlay {
                Text(verbatim: "\(number)")
                    .font(.system(size: cell * 0.44, weight: .heavy, design: .rounded))
                    .foregroundStyle(Wood.number)
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)
            }
            .overlay(alignment: direction.map(Self.edge) ?? .center) {
                if let direction {
                    Image(systemName: direction.arrowSymbol)
                        .font(.system(size: cell * 0.18, weight: .black))
                        .foregroundStyle(Wood.number)
                        .padding(cell * 0.035)
                }
            }
            .compositingGroup()
            .shadow(color: .black.opacity(0.3), radius: 0, x: 2, y: 3)
            .padding(3)
            .frame(width: cell, height: cell)
            .contentShape(Rectangle())
            .position(x: (CGFloat(index % puzzle.size) + 0.5) * cell, y: (CGFloat(index / puzzle.size) + 0.5) * cell)
            .guideTarget(isGuideTarget)
            // The one place a move animates. Reduce Motion: the tiles land at once (issue spec).
            .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: puzzle.tiles)
            .onTapGesture { slide(at: index) }
            // A swipe counts only toward the gap; any other way does nothing.
            .gesture(
                DragGesture(minimumDistance: 16).onEnded { value in
                    if Self.swipe(value.translation) == direction { slide(at: index) }
                }
            )
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(
                AppLanguage.localized(
                    "game.numberslide.tile \(number) \(index / puzzle.size + 1) \(index % puzzle.size + 1)"
                        as String.LocalizationValue)
            )
            .accessibilityAddTraits(direction == nil ? [] : .isButton)
            // Read in board order, whatever order the tiles are drawn in.
            .accessibilitySortPriority(Double(puzzle.tiles.count - index))
            // VoiceOver hears only the slide this tile can make now, named by its way (issue spec).
            .accessibilityActions {
                if let direction {
                    Button(AppLanguage.localized("game.sliding.move.\(direction.rawValue)")) { slide(at: index) }
                }
            }
    }

    /// The gap, as an element VoiceOver can find: "empty space, row 4, column 4".
    private func gapLabel(in puzzle: NumberSlidePuzzle, cell: CGFloat) -> some View {
        let gap = puzzle.gap
        return Color.clear
            .frame(width: cell, height: cell)
            .position(x: (CGFloat(gap % puzzle.size) + 0.5) * cell, y: (CGFloat(gap / puzzle.size) + 0.5) * cell)
            .accessibilityElement()
            .accessibilityLabel(
                AppLanguage.localized(
                    "game.numberslide.gap \(gap / puzzle.size + 1) \(gap % puzzle.size + 1)" as String.LocalizationValue)
            )
            .accessibilitySortPriority(Double(puzzle.tiles.count - gap))
            .allowsHitTesting(false)
    }

    /// Where a tile's arrow sits: on the edge that faces the gap, and for a sideways slide in the
    /// lower corner, clear of a two-digit number on the smallest phones.
    nonisolated private static func edge(_ direction: SlidingDirection) -> Alignment {
        switch direction {
        case .up: .top
        case .down: .bottom
        case .left: .bottomLeading
        case .right: .bottomTrailing
        }
    }

    /// The way a finished swipe went, by its longer axis.
    nonisolated private static func swipe(_ translation: CGSize) -> SlidingDirection {
        if abs(translation.width) > abs(translation.height) { return translation.width > 0 ? .right : .left }
        return translation.height > 0 ? .down : .up
    }

    // MARK: - Goal

    /// "Put the numbers in order" left players asking what the end looks like (#630). Beside the
    /// instruction sits the finished board, small, like the picture on the toy's box. At the
    /// accessibility sizes it has no room, so a button lays the finished board over the real one.
    @ViewBuilder
    private var goalAndInstruction: some View {
        let text = Text(instruction)
            .font(.title2.weight(.semibold))
            .foregroundStyle(Color.espresso)
            .multilineTextAlignment(.center)
        if typeSize.isAccessibilitySize {
            text
            Button(action: showGoal) {
                Text(AppLanguage.localized("game.numberslide.goal.show"))
                    .font(.title2.weight(.semibold))
                    .multilineTextAlignment(.center)
            }
            .buttonStyle(AnswerTileStyle(minHeight: 100))
            .disabled(showingGoal || puzzle == nil)
        } else {
            HStack(spacing: 16) {
                text.frame(maxWidth: .infinity)
                if let puzzle { GoalBoard(size: puzzle.size) }
            }
        }
    }

    /// Three seconds of the finished board, then the player's own board again.
    private func showGoal() {
        guard let puzzle else { return }
        showingGoal = true
        AccessibilityNotification.Announcement(Self.goalLabel(size: puzzle.size)).post()
        goalTask?.cancel()
        goalTask = FinishBeat.after(seconds: 3) { showingGoal = false }
    }

    /// "Goal: 1 to 8 in order, the space last."
    static func goalLabel(size: Int) -> String {
        AppLanguage.localized("game.numberslide.goal \(size * size - 1)" as String.LocalizationValue)
    }

    // MARK: - Controls

    /// The three 100pt buttons in a row, as in Sliding Blocks; at the accessibility text sizes, one
    /// per row, so no word is split.
    @ViewBuilder
    private var controls: some View {
        if typeSize.isAccessibilitySize {
            VStack(spacing: 12) { buttons }
        } else {
            HStack(spacing: 12) { buttons }
        }
    }

    @ViewBuilder
    private var buttons: some View {
        controlButton("game.sliding.undo", enabled: !(puzzle?.history.isEmpty ?? true) && !isSolved, action: undo)
        controlButton("game.sliding.restart", enabled: hasMoved && !isSolved, action: startOver)
        controlButton("game.sliding.hint", enabled: puzzle != nil && !isSolved, action: showMove)
    }

    private var isSolved: Bool { puzzle?.isSolved ?? false }

    /// A label that would split a word on a narrow phone ("Muéstrame un paso" or "Deshacer" on an
    /// iPhone SE) shrinks instead: a one-word label keeps to one line and a longer one to two, so
    /// the text shrinks before any word is broken, with a margin inside the tile.
    private func controlButton(_ key: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(AppLanguage.localized(key))
                .font(.title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .lineLimit(typeSize.isAccessibilitySize ? nil : min(2, AppLanguage.localized(key).split(separator: " ").count))
                .minimumScaleFactor(0.6)
                .padding(.horizontal, 8)
        }
        .buttonStyle(AnswerTileStyle(minHeight: 100))
        .disabled(!enabled)
    }

    // MARK: - Play

    /// A tap (or a VoiceOver action) on the tile at `cell`. A solved board takes no more moves, so
    /// the session is recorded once.
    private func slide(at cell: Int, shown: Bool = false) {
        guard var current = puzzle, !current.isSolved else { return }
        let number = current.tiles[cell]
        guard current.slide(at: cell) else { return }
        puzzle = current
        shownTile = shown ? number : nil
        Feedback.play(.tap)
        if current.isSolved { finish(solved: current) }
    }

    private func undo() {
        guard var current = puzzle, current.undo() else { return }
        puzzle = current
        shownTile = nil
        Feedback.play(.tap)
    }

    private func startOver() {
        guard var current = puzzle, current.movesMade > 0 else { return }
        current.startOver()
        puzzle = current
        hintsUsed = 0
        shownTile = nil
        Feedback.play(.tap)
    }

    /// "Show me a move": the next slide of a short solution is played for the player; each shown
    /// move adds one attempt on top of the move itself.
    private func showMove() {
        guard let current = puzzle, let cell = NumberSlideSolver.hint(from: current) else { return }
        hintsUsed += 1
        slide(at: cell, shown: true)
    }

    /// Counts the deal's fewest moves in the background. Cancelled on a new deal or when the screen
    /// goes, and the search stops within a few milliseconds of it.
    private func countFewest(_ deal: NumberSlidePuzzle) {
        fewest?.cancel()
        fewest = Task.detached(priority: .userInitiated) {
            NumberSlideSolver.fewestMoves(from: deal) { Task.isCancelled }
        }
    }

    private func deal() {
        difficulty = Difficulty.stored(.numberSlide)
        var generator = SystemRandomNumberGenerator()
        let fresh = NumberSlidePuzzle.deal(for: difficulty, using: &generator)
        puzzle = fresh
        goalTask?.cancel()
        showingGoal = false
        guideTile =
            FirstPlayGuideStore.shouldShow(.numberSlide) ? NumberSlideSolver.hint(from: fresh).map { fresh.tiles[$0] } : nil
        hintsUsed = 0
        shownTile = nil
        startedAt = .now
        countFewest(fresh)
    }

    /// All in order: record the session with its level (issue spec), then the shared celebration
    /// says it warmly. The fewest moves are long since worked out; waiting for them keeps the
    /// session and the celebration's level offer in step.
    private func finish(solved: NumberSlidePuzzle) {
        let elapsed = Int(Date.now.timeIntervalSince(startedAt))
        let (level, hints, work) = (difficulty, hintsUsed, fewest)
        Task { @MainActor in
            // Nil when no count was found: the session is then scored from the moves alone.
            let best = await work?.value ?? nil
            modelContext.record(solved.session(level: level, fewestMoves: best, hints: hints, seconds: elapsed))
            finalDetail = AppLanguage.localized("game.numberslide.done")
            if CaptionSpeaker.autoSpeaks() { CaptionSpeaker.speak(finalDetail) }
            AccessibilityNotification.Announcement(finalDetail).post()
            showCelebration = true
        }
    }
}

/// The toy's colours. The tiles stay cream wood with crimson numbers in dark mode too, because they
/// are the object, not the page; the tray is the game's ink, a shade deeper in dark mode so the
/// cream tiles stand out on the dark surround. Number on face: 5.6:1.
/// The finished board in miniature (#630): every number where it ends up and the gap last, in the
/// toy's own wood and crimson. A picture, not a control; VoiceOver reads it as one line.
private struct GoalBoard: View {
    let size: Int

    var body: some View {
        let cell: CGFloat = size == 3 ? 26 : 21
        VStack(spacing: 4) {
            Text(AppLanguage.localized("game.numberslide.goal.title"))
                .font(.headline)
                .foregroundStyle(Color.espresso)
            Grid(horizontalSpacing: 2, verticalSpacing: 2) {
                ForEach(0..<size, id: \.self) { row in
                    GridRow {
                        ForEach(0..<size, id: \.self) { column in
                            let number = row * size + column + 1
                            if number < size * size {
                                Text(verbatim: "\(number)")
                                    .font(.system(size: cell * 0.5, weight: .heavy, design: .rounded))
                                    .foregroundStyle(Wood.number)
                                    .frame(width: cell, height: cell)
                                    .background(Wood.face, in: .rect(cornerRadius: 4))
                            } else {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.black.opacity(0.38))
                                    .frame(width: cell, height: cell)
                            }
                        }
                    }
                }
            }
            .padding(4)
            .background(Wood.tray, in: .rect(cornerRadius: 8))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(NumberSlideView.goalLabel(size: size))
    }
}

private enum Wood {
    static let tray = Color(light: 0xA3283C, dark: 0x7E1F2F)
    static let face = Color(UIColor(rgb: 0xF6E2B8))
    static let faceLight = Color(UIColor(rgb: 0xFFF6E0))
    static let edge = Color(UIColor(rgb: 0x8A6A3A)).opacity(0.45)
    static let number = Color(UIColor(rgb: 0xA3283C))
}

#Preview {
    NumberSlideView()
}
