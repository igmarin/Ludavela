import SwiftData
import SwiftUI

/// Lotería (#548): a family lotería night, calm and with no timer. A card is called; the player
/// taps its picture on their board to place a bean, or "Next card" when it isn't there. When the
/// level's pattern is complete a big "¡Lotería!" button appears; the game never wins by itself.
/// Rules live in `LoteriaDeal`; this view draws, speaks and forwards taps.
struct LoteriaView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize

    @State private var difficulty: Difficulty
    @State private var deal: LoteriaDeal
    /// The kind note under the instruction, if a tap just needs one.
    @State private var note: Note?
    /// The tile that just took a "not called yet" tap, for its miss cue.
    @State private var missedTile: Int?
    /// The called tile shown by the one-time help cue after "Look again" is tapped twice.
    @State private var helpTile: Int?
    @State private var helpPulse = false
    @State private var helpCueID = 0
    @State private var startedAt = Date.now
    @State private var showCelebration = false
    @State private var finalDetail = ""

    /// Gap between tiles and between the play area's rows.
    private let gap: CGFloat = 8
    private let rowGap: CGFloat = 12
    /// The called card's row, and the smallest tile (the brief's 80pt on an iPhone SE).
    private static let topRowMinimum: CGFloat = 100
    private static let tileMinimum: CGFloat = 80

    enum Note {
        case lookAgain, notCalled

        var key: String {
            switch self {
            case .lookAgain: "game.loteria.lookagain"
            case .notCalled: "game.loteria.notcalled"
            }
        }
    }

    init() {
        let level = Difficulty.stored(.loteria)
        _difficulty = State(initialValue: level)
        _deal = State(initialValue: Self.newDeal(level))
    }

    private static func newDeal(_ level: Difficulty) -> LoteriaDeal {
        var generator = SystemRandomNumberGenerator()
        return LoteriaDeal.make(difficulty: level, using: &generator)
    }

    private var hasStarted: Bool { deal.calledCount > 1 || deal.attempts > 0 }

    var body: some View {
        Group {
            if typeSize.isAccessibilitySize {
                accessibilityLayout
            } else {
                regularLayout.fitOrScroll()
            }
        }
        .gameColumn()
        .padding(.horizontal, 12)
        .padding(.vertical, 16)
        .gameHeader(
            .loteria, instruction: AppLanguage.localized("game.loteria.instruction"),
            inProgress: hasStarted, celebrating: showCelebration
        )
        .firstPlayGuide(
            .loteria, line: AppLanguage.localized("game.loteria.guide"),
            example: AppLanguage.localized("guide.loteria.example")
        )
        .onAppear { if !hasStarted { announceCalled() } }
        .task(id: helpCueID) { await animateHelpCue() }
        .celebration(isPresented: $showCelebration, game: .loteria, detail: finalDetail, onPlayAgain: restart)
    }

    private var regularLayout: some View {
        VStack(spacing: rowGap) {
            LevelExplainBanner(game: .loteria, hasStarted: hasStarted, keepsSpace: true)
            instructionRow
            goalLine
            playArea
                .frame(minHeight: minimumPlayHeight)
        }
    }

    /// Holds the called card above the scroll region, so the player can keep finding it at the
    /// largest text sizes while the instructions and board move into view.
    private var accessibilityLayout: some View {
        GeometryReader { proxy in
            VStack(spacing: rowGap) {
                if deal.hasLoteria {
                    Button(action: finish) {
                        Text(AppLanguage.localized("game.loteria.call"))
                            .font(.largeTitle.weight(.heavy))
                            .frame(maxWidth: .infinity, minHeight: Self.topRowMinimum)
                    }
                    .buttonStyle(RetroButtonStyle())
                } else {
                    HStack(spacing: rowGap) {
                        compactCalledCard
                        nextCardButton
                    }
                }
                ScrollView {
                    VStack(spacing: rowGap) {
                        LevelExplainBanner(game: .loteria, hasStarted: hasStarted, keepsSpace: true)
                        instructionRow
                        goalLine
                        if !deal.hasLoteria {
                            board(
                                tile: Self.tileSide(
                                    width: proxy.size.width, height: proxy.size.width, side: deal.side, gap: gap)
                            )
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .frame(maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private var goalLine: some View {
        Text(AppLanguage.localized(goalKey))
            .font(.title3.weight(.semibold))
            .foregroundStyle(.tint)
            .multilineTextAlignment(.center)
    }

    // MARK: - Instruction and goal

    private var goalKey: String {
        switch deal.pattern {
        case .line: "game.loteria.goal.line"
        case .corners: "game.loteria.goal.corners"
        case .fullBoard: "game.loteria.goal.full"
        }
    }

    /// The instruction and the note share one row, as tall as the tallest of them, so a note
    /// appearing never takes height from the board and shrinks every tile mid-game.
    private var instructionRow: some View {
        ZStack {
            Text(AppLanguage.localized("game.loteria.instruction"))
                .font(.title2)
                .multilineTextAlignment(.center)
                .opacity(note == nil ? 1 : 0)
                .accessibilityHidden(note != nil)
            ForEach([Note.lookAgain, .notCalled], id: \.self) { AlmostNote(text: AppLanguage.localized($0.key)).hidden() }
            if let note {
                AlmostNote(text: AppLanguage.localized(note.key))
            }
        }
    }

    // MARK: - Play area

    /// The called card (or "¡Lotería!") above the board, sized together from the space left: the
    /// board as big as it fits, never under 80pt a tile; the card row takes what remains.
    private var playArea: some View {
        GeometryReader { proxy in
            let tile = Self.tileSide(
                width: proxy.size.width, height: proxy.size.height - Self.topRowMinimum - rowGap,
                side: deal.side, gap: gap)
            let boardSide = tile * CGFloat(deal.side) + gap * CGFloat(deal.side - 1)
            let topHeight = min(220, max(Self.topRowMinimum, proxy.size.height - boardSide - rowGap))
            VStack(spacing: rowGap) {
                topRow(height: topHeight)
                board(tile: tile)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        }
    }

    private var minimumPlayHeight: CGFloat {
        Self.topRowMinimum + rowGap + Self.tileMinimum * CGFloat(deal.side) + gap * CGFloat(deal.side - 1)
    }

    /// The widest square tile that fits `side` across and down, held at 80pt or more (the page
    /// scrolls instead), and at 170pt or less so an iPad board stays a board, not a wall.
    static func tileSide(width: CGFloat, height: CGFloat, side: Int, gap: CGFloat) -> CGFloat {
        let gaps = gap * CGFloat(side - 1)
        let fit = min(width - gaps, height - gaps) / CGFloat(side)
        return min(170, max(tileMinimum, fit.rounded(.down)))
    }

    @ViewBuilder private func topRow(height: CGFloat) -> some View {
        if deal.hasLoteria {
            Button(action: finish) {
                Text(AppLanguage.localized("game.loteria.call"))
                    .font(.largeTitle.weight(.heavy))
                    .frame(maxHeight: .infinity)
            }
            .buttonStyle(RetroButtonStyle())
            .frame(height: height)
        } else {
            HStack(spacing: rowGap) {
                calledCard(height: height)
                nextCardButton
            }
            .frame(height: height)
        }
    }

    private var nextCardButton: some View {
        Button(action: nextCard) {
            Text(AppLanguage.localized("game.loteria.next"))
                .font(.title2.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 8)
        }
        .buttonStyle(AnswerTileStyle(minHeight: Self.topRowMinimum))
    }

    /// A smaller copy of the called card for the pinned accessibility-size bar.
    private var compactCalledCard: some View {
        let name = AppLanguage.localized(deal.current.nameKey)
        let showsPicture = LoteriaDeal.showsPicture(for: difficulty)
        return HStack(spacing: 8) {
            if showsPicture {
                PictureView(picture: deal.current, size: 56)
            }
            Text(name)
                .font(.title3.weight(.bold))
                .lineLimit(2)
                .minimumScaleFactor(0.6)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
        }
        .padding(8)
        .frame(maxWidth: .infinity, minHeight: Self.topRowMinimum)
        .background(Color.paper, in: .rect(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.tint, lineWidth: 4))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(format: AppLanguage.localized("game.loteria.a11y.called %@"), name))
        .guideTarget()
    }

    /// The called card, framed like a lotería card: its picture and name, or the name alone from
    /// level 7. VoiceOver always hears the full name.
    private func calledCard(height: CGFloat) -> some View {
        let name = AppLanguage.localized(deal.current.nameKey)
        let showsPicture = LoteriaDeal.showsPicture(for: difficulty)
        return VStack(spacing: 4) {
            if showsPicture {
                PictureView(picture: deal.current, size: max(44, height - 52))
            }
            Text(name)
                .font(showsPicture ? .title3.weight(.bold) : .title.weight(.bold))
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .multilineTextAlignment(.center)
        }
        .padding(8)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.paper, in: .rect(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).strokeBorder(.tint, lineWidth: 4))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(String(format: AppLanguage.localized("game.loteria.a11y.called %@"), name))
        .guideTarget()
    }

    private func board(tile: CGFloat) -> some View {
        Grid(horizontalSpacing: gap, verticalSpacing: gap) {
            ForEach(0..<deal.side, id: \.self) { row in
                GridRow {
                    ForEach(0..<deal.side, id: \.self) { column in
                        tileButton(row * deal.side + column, size: tile)
                    }
                }
            }
        }
    }

    private func tileButton(_ index: Int, size: CGFloat) -> some View {
        let picture = deal.board[index]
        let marked = deal.marked.contains(index)
        let isHelpTile = helpTile == index
        let name = AppLanguage.localized(picture.nameKey)
        let label =
            isHelpTile
            ? positionLabel(of: index)
            : String(format: AppLanguage.localized(marked ? "game.loteria.a11y.marked %@" : "game.loteria.a11y.open %@"), name)
        return Button {
            tap(index)
        } label: {
            // The bean sits on the card's lower corner, so the picture under it still shows.
            PictureView(picture: picture, size: size * 0.72)
                .overlay(alignment: .bottomTrailing) {
                    if marked { Bean(size: size * 0.42).offset(x: size * 0.06, y: size * 0.04) }
                }
        }
        .buttonStyle(AnswerTileStyle(strength: marked ? 0.3 : 0.12, minHeight: size))
        .frame(width: size, height: size)
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.amber, lineWidth: 6)
                .opacity(isHelpTile && reduceMotion ? 1 : 0)
                .accessibilityHidden(true)
        }
        .scaleEffect(isHelpTile && helpPulse && !reduceMotion ? 1.06 : 1)
        .animation(.easeInOut(duration: 0.25), value: helpPulse)
        .modifier(MissCue(active: Binding(get: { missedTile == index }, set: { if !$0 { missedTile = nil } })))
        .accessibilityLabel(label)
    }

    // MARK: - Play

    private func tap(_ index: Int) {
        guard !showCelebration else { return }
        switch deal.tap(index) {
        case .marked:
            note = nil
            clearHelpCue()
            if deal.hasLoteria {
                Feedback.play(.success)
                AccessibilityNotification.Announcement(AppLanguage.localized("game.loteria.ready")).post()
            } else {
                Feedback.play(.tap)
            }
        case .notCalled:
            note = .notCalled
            missedTile = index
            Feedback.play(.miss)
            AccessibilityNotification.Announcement(AppLanguage.localized(Note.notCalled.key)).post()
        case .ignored:
            break
        }
    }

    private func nextCard() {
        switch deal.next() {
        case .called:
            note = nil
            clearHelpCue()
            announceCalled()
        case .lookAgain:
            note = .lookAgain
            Feedback.play(.miss)
            AccessibilityNotification.Announcement(AppLanguage.localized(Note.lookAgain.key)).post()
        case .showHelp(let index):
            note = .lookAgain
            showHelpCue(for: index)
            Feedback.play(.miss)
            announcePosition(of: index)
        case .deckDone:
            break
        }
    }

    private func showHelpCue(for index: Int) {
        helpCueID += 1
        helpTile = index
        helpPulse = false
    }

    private func clearHelpCue() {
        helpCueID += 1
        helpTile = nil
        helpPulse = false
    }

    /// Expands and settles the matching tile once; a ring stays in its place under Reduce Motion.
    private func animateHelpCue() async {
        guard helpTile != nil else { return }
        withAnimation(.easeInOut(duration: 0.25)) { helpPulse = true }
        do {
            try await Task.sleep(for: .milliseconds(250))
            withAnimation(.easeInOut(duration: 0.25)) { helpPulse = false }
        } catch {
            return
        }
    }

    /// Gives the hinted tile a one-based position VoiceOver can announce and users can confirm.
    private func positionLabel(of index: Int) -> String {
        let row = index / deal.side + 1
        let column = index % deal.side + 1
        let name = AppLanguage.localized(deal.board[index].nameKey)
        return String(format: AppLanguage.localized("game.loteria.a11y.position"), row, column, name)
    }

    /// VoiceOver hears the target's one-based row and column with its name.
    private func announcePosition(of index: Int) {
        guard UIAccessibility.isVoiceOverRunning else { return }
        AccessibilityNotification.Announcement(positionLabel(of: index)).post()
    }

    /// Calls the card out: spoken when "Read names aloud" is on (the voice rule every game
    /// follows), otherwise announced to VoiceOver, so its name never depends on the picture.
    private func announceCalled() {
        let name = AppLanguage.localized(deal.current.nameKey)
        if CaptionSpeaker.autoSpeaks() {
            CaptionSpeaker.speak(name)
        } else if UIAccessibility.isVoiceOverRunning {
            AccessibilityNotification.Announcement(
                String(format: AppLanguage.localized("game.loteria.a11y.called %@"), name)
            ).post()
        }
    }

    private func restart() {
        difficulty = Difficulty.stored(.loteria)
        deal = Self.newDeal(difficulty)
        note = nil
        missedTile = nil
        clearHelpCue()
        startedAt = .now
        announceCalled()
    }

    private func finish() {
        guard deal.hasLoteria, !showCelebration else { return }
        CaptionSpeaker.stop()
        modelContext.record(
            GameSession(
                gameID: .loteria, rounds: deal.calledCount,
                durationSeconds: Int(Date.now.timeIntervalSince(startedAt)),
                correct: deal.correct, attempts: deal.attempts, difficulty: difficulty))
        finalDetail = AppLanguage.localized("game.celebration.loteria")
        showCelebration = true
    }
}

/// The bean that marks a called card, drawn as a shape so "marked" is never colour alone: a
/// tilted brown oval with a dark edge and a soft shine, the same in light and dark mode.
private struct Bean: View {
    let size: CGFloat

    var body: some View {
        ZStack {
            Ellipse().fill(Color(UIColor(rgb: 0x7A4B2A)))
            Ellipse().strokeBorder(Color.espresso, lineWidth: max(2, size * 0.05))
            Ellipse()
                .fill(Color.white.opacity(0.45))
                .frame(width: size * 0.32, height: size * 0.14)
                .offset(x: -size * 0.12, y: -size * 0.1)
        }
        .frame(width: size, height: size * 0.66)
        .rotationEffect(.degrees(-25))
        .shadow(color: .black.opacity(0.3), radius: 0, x: 2, y: 2)
        .accessibilityHidden(true)
    }
}

#Preview {
    NavigationStack { LoteriaView() }
}
