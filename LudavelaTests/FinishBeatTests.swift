import SwiftData
import XCTest

@testable import Ludavela

/// #415: the finished board stays on screen for a beat before the celebration covers it.
final class FinishBeatTests: XCTestCase {
    @MainActor
    func testGivenACancelledBeatWhenWaitingThenTheCelebrationDoesNotShow() async {
        var shown = false
        let task = FinishBeat.after(seconds: 0.05) { shown = true }
        task.cancel()
        await task.value
        XCTAssertFalse(shown)
    }

    @MainActor
    func testGivenABeatWhenTheWaitEndsThenTheCelebrationShows() async {
        var shown = false
        await FinishBeat.after(seconds: 0.05) { shown = true }.value
        XCTAssertTrue(shown)
    }

    @MainActor
    func testGivenFinalAnswerWhenLeavingDuringBeatThenSessionIsSavedOnce() async throws {
        for game in [GameID.categoryFluency, .quickEyes] {
            let container = try ModelContainer(
                for: GameSession.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)
            context.autosaveEnabled = false
            var recorder = FinishBeat.Recorder()
            let session = GameSession(gameID: game, rounds: 3, durationSeconds: 10)
            recorder.record(session, in: context)
            recorder.record(session, in: context)  // a repeated final tap
            var shown = false
            let task = FinishBeat.after(seconds: 1.2) { shown = true }
            task.cancel()
            await task.value
            XCTAssertFalse(shown)
            XCTAssertEqual(try ModelContext(container).fetchCount(FetchDescriptor<GameSession>()), 1, "\(game)")
        }
    }

    @MainActor
    func testGivenFinishedRunWhenPlayingAgainThenEachRunIsRecordedOnce() throws {
        for game in [GameID.categoryFluency, .quickEyes] {
            let container = try ModelContainer(
                for: GameSession.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)
            var recorder = FinishBeat.Recorder()
            XCTAssertEqual(try context.fetchCount(FetchDescriptor<GameSession>()), 0)  // incomplete
            recorder.record(GameSession(gameID: game, rounds: 3, durationSeconds: 10), in: context)
            recorder.reset()
            recorder.record(GameSession(gameID: game, rounds: 3, durationSeconds: 12), in: context)
            recorder.record(GameSession(gameID: game, rounds: 3, durationSeconds: 12), in: context)
            XCTAssertEqual(try ModelContext(container).fetchCount(FetchDescriptor<GameSession>()), 2, "\(game)")
        }
    }

    @MainActor
    func testGivenFinalAnswerWhenBeatEndsThenCelebrationDoesNotRecordAgain() async throws {
        for game in [GameID.categoryFluency, .quickEyes] {
            let container = try ModelContainer(
                for: GameSession.self, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
            let context = ModelContext(container)
            var recorder = FinishBeat.Recorder()
            recorder.record(GameSession(gameID: game, rounds: 3, durationSeconds: 10), in: context)
            var shown = false
            await FinishBeat.after(seconds: 0.01) { shown = true }.value
            XCTAssertTrue(shown)
            XCTAssertEqual(try ModelContext(container).fetchCount(FetchDescriptor<GameSession>()), 1, "\(game)")
        }
    }

}
