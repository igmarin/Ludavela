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
    func testGivenTheShippedThemesWhenDealtThenEveryLevelHasUniqueSolutions() throws {
        let root = URL(fileURLWithPath: #filePath).deletingLastPathComponent().deletingLastPathComponent()
        let data = try Data(contentsOf: root.appendingPathComponent("MenteViva/Localizable.xcstrings"))
        let catalog = try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
        let strings = try XCTUnwrap(catalog["strings"] as? [String: Any])
        for language in ["en", "es"] {
            for theme in ["animals", "garden", "music"] {
                let key = "game.wordsearch.\(theme)"
                let entry = try XCTUnwrap(strings[key + ".words"] as? [String: Any])
                let translations = try XCTUnwrap(entry["localizations"] as? [String: Any])
                let translation = try XCTUnwrap(translations[language] as? [String: Any])
                let unit = try XCTUnwrap(translation["stringUnit"] as? [String: Any])
                let text = try XCTUnwrap(unit["value"] as? String)
                let words = text.split(separator: ",").map(String.init)
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
