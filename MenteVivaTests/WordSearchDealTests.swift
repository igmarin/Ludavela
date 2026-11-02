import XCTest

@testable import MenteViva

/// Word-search boards contain exactly the words the player is asked to find.
final class WordSearchDealTests: XCTestCase {
    private struct Seeded: RandomNumberGenerator {
        var state: UInt64
        mutating func next() -> UInt64 {
            state = state &* 6_364_136_223_846_793_005 &+ 1_442_695_040_888_963_407
            return state
        }
    }

    private let themes = [("animals", ["HORSE", "SHEEP", "TIGER", "ZEBRA", "MOUSE", "FROG", "DUCK", "WHALE"])]

    func testGivenLevelsAndSeedsWhenDealtThenEveryWordAppearsExactlyOnce() {
        for spanish in [false, true] {
            for tablet in [false, true] {
                for level in 1...10 {
                    for seed in 1...10 {
                        var random = Seeded(state: UInt64(seed))
                        let deal = WordSearchDeal.make(
                            level: level, tablet: tablet, spanish: spanish, themes: themes, using: &random)
                        XCTAssertEqual(deal.words.count, [4, 4, 5, 5, 6, 6, 7, 7, 8, 8][level - 1])
                        for word in deal.words {
                            XCTAssertEqual(deal.occurrences(of: word.text).count, 1)
                            XCTAssertEqual(deal.occurrences(of: word.text).first, word.cells)
                        }
                    }
                }
            }
        }
    }

    func testGivenTheSameSeedWhenDealtThenTheBoardIsTheSame() {
        var first = Seeded(state: 42)
        var second = Seeded(state: 42)
        XCTAssertEqual(
            WordSearchDeal.make(level: 9, tablet: false, spanish: true, themes: themes, using: &first),
            WordSearchDeal.make(level: 9, tablet: false, spanish: true, themes: themes, using: &second))
    }

    func testGivenAWordWhenSelectedEitherWayThenItIsFound() {
        var random = Seeded(state: 1)
        let deal = WordSearchDeal.make(level: 1, tablet: false, spanish: false, themes: themes, using: &random)
        for word in deal.words {
            XCTAssertEqual(deal.match(from: word.cells.first!, to: word.cells.last!), word.text)
            XCTAssertEqual(deal.match(from: word.cells.last!, to: word.cells.first!), word.text)
        }
    }

    func testGivenASelectionThatIsNotAWordWhenCheckedThenNothingMatches() {
        var random = Seeded(state: 1)
        let deal = WordSearchDeal.make(level: 1, tablet: false, spanish: false, themes: themes, using: &random)
        XCTAssertNil(deal.match(from: 0, to: 0))
    }

    func testGivenSpanishWhenDealtThenLettersHaveNoAccentsAndEnyeIsAvailable() {
        var random = Seeded(state: 1)
        let deal = WordSearchDeal.make(level: 10, tablet: true, spanish: true, themes: themes, using: &random)
        XCTAssertTrue(deal.grid.allSatisfy { "ABCDEFGHIJKLMNÑOPQRSTUVWXYZ".contains($0) })
        XCTAssertTrue(WordSearchDeal.spanishLetters.contains("Ñ"))
    }
    func testGivenManySeedsAtEveryLevelWhenDealtThenNoRudeWordReadsInAnyDirection() {
        let themes = [
            ("animals", ["HORSE", "SHEEP", "TIGER", "ZEBRA", "MOUSE", "FROG", "DUCK", "WHALE"]),
            ("animales", ["PERRO", "GATO", "TIGRE", "CEBRA", "RATON", "RANA", "PATO", "OVEJA"]),
        ]
        for spanish in [false, true] {
            let blocked = spanish ? WordSearchDeal.spanishBlocked : WordSearchDeal.englishBlocked
            for tablet in [false, true] {
                for level in 1...10 {
                    for seed in 1...20 {
                        var random = Seeded(state: UInt64(seed))
                        let deal = WordSearchDeal.make(
                            level: level, tablet: tablet, spanish: spanish, themes: [themes[spanish ? 1 : 0]],
                            using: &random)
                        for word in blocked {
                            XCTAssertEqual(deal.occurrences(of: word), [], "\(word) at level \(level), seed \(seed)")
                        }
                    }
                }
            }
        }
    }

    func testGivenAPlantedRudeWordWhenCheckedThenTheGridIsRejected() {
        // PUTA read backwards up the first column, and ASS on a diagonal.
        let spanish = WordSearchDeal(
            side: 4, grid: Array("AXXXTXXXUXXXPXXX"), words: [], themeKey: "")
        XCTAssertTrue(spanish.showsBlockedWord(spanish: true))
        XCTAssertFalse(spanish.showsBlockedWord(spanish: false))
        let english = WordSearchDeal(side: 3, grid: Array("AXXXSXXXS"), words: [], themeKey: "")
        XCTAssertTrue(english.showsBlockedWord(spanish: false))
        XCTAssertFalse(WordSearchDeal(side: 2, grid: Array("ABCD"), words: [], themeKey: "").showsBlockedWord(spanish: false))
    }

    /// Level table (#550): across; + down; + diagonal down; + diagonal up from level 9.
    func testGivenEachLevelWhenDealtThenEveryWordRunsInADirectionAllowedThere() {
        let across = [0, 1]
        let down = [1, 0]
        let diagonalDown = [1, 1]
        let diagonalUp = [-1, 1]
        let allowed = [
            [across], [across, down], [across, down, diagonalDown], [across, down, diagonalDown],
            [across, down, diagonalDown, diagonalUp],
        ]
        for tablet in [false, true] {
            for level in 1...10 {
                for seed in 1...20 {
                    var random = Seeded(state: UInt64(seed))
                    let deal = WordSearchDeal.make(level: level, tablet: tablet, spanish: false, themes: themes, using: &random)
                    for word in deal.words {
                        let step = [
                            word.cells[1] / deal.side - word.cells[0] / deal.side,
                            word.cells[1] % deal.side - word.cells[0] % deal.side,
                        ]
                        XCTAssertTrue(allowed[(level - 1) / 2].contains(step), "level \(level): \(word.text) runs \(step)")
                    }
                }
            }
        }
    }

    /// Level table (#550, #560): the phone tops out at 8×8 so a cell stays 44pt on an iPhone SE.
    func testGivenEachLevelWhenDealtThenTheSideMatchesTheLevelTable() {
        let phone = [6, 6, 7, 7, 8, 8, 8, 8, 8, 8]
        let tablet = [6, 6, 8, 8, 9, 9, 10, 10, 10, 10]
        for level in 1...10 {
            var random = Seeded(state: 7)
            XCTAssertEqual(
                WordSearchDeal.make(level: level, tablet: false, spanish: false, themes: themes, using: &random).side,
                phone[level - 1])
            XCTAssertEqual(
                WordSearchDeal.make(level: level, tablet: true, spanish: false, themes: themes, using: &random).side,
                tablet[level - 1])
        }
    }

    private func selection() -> WordSearchSelection {
        var random = Seeded(state: 1)
        return WordSearchSelection(
            deal: WordSearchDeal.make(level: 1, tablet: false, spanish: false, themes: themes, using: &random))
    }

    func testGivenTheFirstLetterTappedThenTheLastWhenCheckedThenTheWordIsFound() throws {
        var selection = selection()
        let word = try XCTUnwrap(selection.deal.words.first)
        XCTAssertEqual(selection.tap(word.cells.first!), .started)
        XCTAssertEqual(selection.first, word.cells.first)
        XCTAssertEqual(selection.tap(word.cells.last!), .found(word.text))
        XCTAssertNil(selection.first)
        XCTAssertEqual(selection.found, [word.text])
        XCTAssertEqual(selection.attempts, 1)
    }

    func testGivenTheLastLetterTappedThenTheFirstWhenCheckedThenTheWordIsFound() throws {
        var selection = selection()
        let word = try XCTUnwrap(selection.deal.words.last)
        _ = selection.tap(word.cells.last!)
        XCTAssertEqual(selection.tap(word.cells.first!), .found(word.text))
        XCTAssertEqual(selection.pick(from: word.cells.first!, to: word.cells.last!), .miss)
    }

    func testGivenTheSameLetterTappedTwiceWhenCheckedThenTheStartIsCancelledWithoutAMiss() {
        var selection = selection()
        _ = selection.tap(3)
        XCTAssertEqual(selection.tap(3), .cancelled)
        XCTAssertNil(selection.first)
        XCTAssertEqual(selection.attempts, 0)
        XCTAssertEqual(selection.tap(3), .started)
    }

    func testGivenALineThatIsNoWordWhenPickedThenAMissIsCountedAndNothingIsFound() throws {
        var selection = selection()
        let word = try XCTUnwrap(selection.deal.words.first)
        let wrongEnd = word.cells[word.cells.count - 2]
        _ = selection.tap(word.cells.first!)
        XCTAssertEqual(selection.tap(wrongEnd), .miss)
        XCTAssertEqual(selection.pick(from: word.cells.first!, to: wrongEnd), .miss)
        XCTAssertEqual(selection.attempts, 2)
        XCTAssertTrue(selection.found.isEmpty)
        XCTAssertFalse(selection.isComplete)
        for word in selection.deal.words { _ = selection.pick(from: word.cells.first!, to: word.cells.last!) }
        XCTAssertTrue(selection.isComplete)
        XCTAssertEqual(selection.attempts, 2 + selection.deal.words.count)
    }

    func testGivenTheShippedThemesWhenDealtThenEveryLevelHasUniqueSolutions() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("MenteViva/Localizable.xcstrings"))
        let catalog = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try XCTUnwrap(catalog["strings"] as? [String: Any])
        for language in ["en", "es"] {
            XCTAssertGreaterThanOrEqual(WordSearchDeal.themeNames.count, 6)
            for theme in WordSearchDeal.themeNames {
                let key = "game.wordsearch.\(theme)"
                let entry = try XCTUnwrap(strings[key + ".words"] as? [String: Any])
                let translations = try XCTUnwrap(entry["localizations"] as? [String: Any])
                let translation = try XCTUnwrap(translations[language] as? [String: Any])
                let unit = try XCTUnwrap(translation["stringUnit"] as? [String: Any])
                let text = try XCTUnwrap(unit["value"] as? String)
                let words = text.split(separator: ",").map(String.init)
                // Capitals with no accents; Spanish keeps Ñ.
                XCTAssertTrue(words.allSatisfy { $0.allSatisfy { "ABCDEFGHIJKLMNÑOPQRSTUVWXYZ".contains($0) } }, text)
                XCTAssertNotNil(strings[key] as? [String: Any], key)
                // A theme word holding a rude word, either way round, could never be dealt.
                let blocked = language == "es" ? WordSearchDeal.spanishBlocked : WordSearchDeal.englishBlocked
                for word in words {
                    XCTAssertFalse(
                        blocked.contains { word.contains($0) || String(word.reversed()).contains($0) }, word)
                }
                for tablet in [false, true] {
                    for level in 1...10 {
                        var random = Seeded(state: UInt64(level))
                        let deal = WordSearchDeal.make(
                            level: level, tablet: tablet, spanish: language == "es",
                            themes: [(key, words)], using: &random)
                        XCTAssertEqual(deal.words.count, [4, 4, 5, 5, 6, 6, 7, 7, 8, 8][level - 1])
                        for word in deal.words {
                            XCTAssertEqual(deal.occurrences(of: word.text), [word.cells])
                        }
                        if language == "es" {
                            XCTAssertTrue(deal.grid.allSatisfy { "ABCDEFGHIJKLMNÑOPQRSTUVWXYZ".contains($0) })
                        }
                    }
                }
            }
        }
    }
}
