import SwiftData
import SwiftUI

/// Riddles / Adivinanzas (#551): a short traditional riddle, line by line, and he picks the answer from
/// pictures with names (levels 1-6) or words (7-10). A miss fades that tile and the round stays open, as
/// in Quick Eyes; "Give me a clue" shows one more line. Five riddles, no timer. The rules are
/// `RiddleRun` and `RiddleDeck`; this view shows them and forwards taps.
struct RiddleView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dynamicTypeSize) private var typeSize

    @ScaledMetric(relativeTo: .title2) private var pictureSize: CGFloat = 60

    @State private var difficulty = Difficulty.stored(.riddles)
    @State private var run = RiddleRun(rounds: [])
    @State private var startedAt = Date.now
    @State private var missed = false
    @State private var missedChoice: RiddleAnswer?
    @State private var showAlmost = false
    @State private var showCelebration = false
    @State private var finalDetail = ""

    private var pictures: Bool { RiddleDeck.showsPictures(difficulty) }

    var body: some View {
        VStack(spacing: 16) {
            LevelExplainBanner(game: .riddles, hasStarted: run.attempts > 0 || run.progress.completedRounds > 0)
            // At accessibility text sizes the instruction would push the answers far down; the speaker in
            // the header still reads it, and the amber note still shows after a miss (as Quick Eyes, #117).
            if !typeSize.isAccessibilitySize || showAlmost {
                instructionRow
            }

            if let round = run.round {
                riddleText(round.riddle)
                // At accessibility sizes the answers come straight after the riddle and the clue waits
                // below them, so the tiles are not pushed off the first screen (#551 review).
                if !typeSize.isAccessibilitySize { clueRow(round.riddle) }
                if run.solved {
                    solvedRow(round.riddle.answer)
                } else {
                    choices(round)
                }
                if typeSize.isAccessibilitySize { clueRow(round.riddle) }
                RoundCounter(progress: run.progress)
            }
        }
        .gameColumn()
        .padding(16)
        .fitOrScroll()
        .gameHeader(
            .riddles, instruction: AppLanguage.localized("game.riddles.instruction"),
            inProgress: run.progress.completedRounds > 0
        )
        .onAppear { if run.rounds.isEmpty { deal() } }
        .onDisappear { CaptionSpeaker.stop() }
        .firstPlayGuide(
            .riddles, line: AppLanguage.localized("game.riddles.guide"),
            example: AppLanguage.localized("guide.riddles.example")
        )
        .celebration(isPresented: $showCelebration, game: .riddles, detail: finalDetail, onPlayAgain: restart)
    }

    /// The instruction and the amber note share one row, as in Finish the Saying (#494): after a miss
    /// the note stands where the instruction was, so no tile moves under his finger.
    private var instructionRow: some View {
        ZStack {
            Text(AppLanguage.localized("game.riddles.instruction"))
                .font(.title2.weight(.semibold))
                .foregroundStyle(Color.espresso)
                .multilineTextAlignment(.center)
                .opacity(showAlmost ? 0 : 1)
                .accessibilityHidden(showAlmost)
            AlmostNote(text: AppLanguage.localized("game.riddles.miss")).hidden()
            if showAlmost { AlmostNote(text: AppLanguage.localized("game.riddles.miss")) }
        }
    }

    /// The riddle line by line in title2, read by VoiceOver as one passage.
    private func riddleText(_ riddle: Riddle) -> some View {
        VStack(spacing: 4) {
            ForEach(riddle.lines.indices, id: \.self) { index in
                Text(riddle.lines[index])
            }
        }
        .font(.system(.title2, design: .serif).weight(.semibold))
        .multilineTextAlignment(.center)
        .fixedSize(horizontal: false, vertical: true)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(RiddleDeck.spoken(riddle))
    }

    /// The clue once asked for, else the button that asks (hidden once the riddle is solved).
    @ViewBuilder
    private func clueRow(_ riddle: Riddle) -> some View {
        if run.clueShown {
            iconLine(clueLine(riddle), systemImage: "lightbulb.fill")
                .font(.title2.italic())
                .foregroundStyle(.tint)
                .multilineTextAlignment(.center)
        } else if !run.solved {
            Button {
                run.showClue()
                AccessibilityNotification.Announcement(clueLine(riddle)).post()
            } label: {
                iconLine(AppLanguage.localized("game.riddles.clue"), systemImage: "lightbulb")
                    .font(.title2.weight(.semibold))
            }
            .buttonStyle(AnswerTileStyle(strength: 0.08, minHeight: 72))
            .guideTarget()
        }
    }

    /// An icon beside text that may wrap: the icon sits on the first line's baseline, not halfway down
    /// a wrapped label, and VoiceOver reads only the text.
    private func iconLine(_ text: String, systemImage: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Image(systemName: systemImage).accessibilityHidden(true)
            Text(text)
        }
        .multilineTextAlignment(.center)
        .padding(.horizontal, 8)
    }

    private func clueLine(_ riddle: Riddle) -> String {
        String(format: AppLanguage.localized("game.riddles.clue.line %@"), riddle.clue)
    }

    /// Three pictures in a row, four in two rows, words two by two; one column at accessibility sizes.
    private func choices(_ round: RiddleRound) -> some View {
        let count = typeSize.isAccessibilitySize ? 1 : (round.choices.count == 3 && pictures ? 3 : 2)
        let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
        return LazyVGrid(columns: columns, spacing: 12) {
            ForEach(round.choices, id: \.self) { answer in
                Button {
                    choose(answer)
                } label: {
                    choiceLabel(answer)
                }
                .buttonStyle(AnswerTileStyle(minHeight: 100))
                .disabled(run.faded.contains(answer))
                .opacity(run.faded.contains(answer) ? 0.35 : 1)
                .modifier(MissCue(active: missedChoice == answer ? $missed : .constant(false)))
                .accessibilityLabel(name(answer))
            }
        }
    }

    private func choiceLabel(_ answer: RiddleAnswer) -> some View {
        VStack(spacing: 6) {
            if pictures, let picture = answer.picture {
                PictureView(picture: picture, size: pictureSize)
            }
            Text(name(answer))
                .font(pictures ? .title3.weight(.semibold) : .title2.weight(.semibold))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.8)
        }
        .padding(6)
    }

    /// The answer with its picture, and Next: he moves on when he is ready.
    private func solvedRow(_ answer: RiddleAnswer) -> some View {
        VStack(spacing: 16) {
            if pictures, let picture = answer.picture {
                PictureView(picture: picture, size: pictureSize * 1.5)
                    .accessibilityHidden(true)
            }
            Text(solvedLine(answer))
                .font(.title2.weight(.semibold))
                .foregroundStyle(.tint)
                .multilineTextAlignment(.center)
            Button(action: next) {
                Text(AppLanguage.localized("game.riddles.next")).font(.title2.weight(.semibold))
            }
            .buttonStyle(AnswerTileStyle(minHeight: 100))
        }
    }

    private func solvedLine(_ answer: RiddleAnswer) -> String {
        String(format: AppLanguage.localized("game.riddles.solved %@"), name(answer))
    }

    private func name(_ answer: RiddleAnswer) -> String {
        AppLanguage.localized(answer.nameKey)
    }

    private func deal() {
        var generator = SystemRandomNumberGenerator()
        run = RiddleRun(
            rounds: RiddleDeck.deal(
                difficulty: difficulty, from: RiddleDeck.riddles(for: AppLanguage.selected()), defaults: .standard,
                using: &generator))
    }

    private func restart() {
        difficulty = Difficulty.stored(.riddles)
        startedAt = .now
        clearMiss()
        deal()
    }

    private func clearMiss() {
        showAlmost = false
        missed = false
        missedChoice = nil
    }

    private func choose(_ answer: RiddleAnswer) {
        switch run.pick(answer) {
        case .right:
            // Seen as soon as it is solved: leaving before Next must not bring it back early.
            if let round = run.round { RiddleDeck.markSeen(round.riddle, defaults: .standard) }
            clearMiss()
            Feedback.play(.success)
            AccessibilityNotification.Announcement(solvedLine(answer)).post()
        case .faded:
            missedChoice = answer
            missed = true
            showAlmost = true
            Feedback.play(.miss)
            // Posted here, not from a `.task(id:)`: two misses in a row keep the same text.
            AccessibilityNotification.Announcement(AppLanguage.localized("game.riddles.miss")).post()
        }
    }

    private func next() {
        clearMiss()
        run.next()
        if run.isFinished {
            finish()
        } else if let round = run.round {
            // Next is replaced by the new tiles, so VoiceOver focus jumps and the new riddle would not be read (#391).
            AccessibilityNotification.Announcement(RiddleDeck.spoken(round.riddle)).post()
        }
    }

    private func finish() {
        modelContext.record(
            GameSession(
                gameID: .riddles,
                rounds: RiddleDeck.roundsPerGame, durationSeconds: Int(Date.now.timeIntervalSince(startedAt)),
                correct: run.correct, attempts: run.attempts,
                difficulty: difficulty))
        finalDetail = String(format: AppLanguage.localized("game.celebration.riddles %lld"), RiddleDeck.roundsPerGame)
        showCelebration = true
    }
}

#Preview {
    RiddleView()
}
