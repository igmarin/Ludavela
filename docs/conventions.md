# Conventions

Lazy-senior rules. Read before writing code.

1. **Zero third-party dependencies.** SwiftUI/SwiftData/Foundation only. If you think you need a package, you're wrong or we discuss it first.
2. **One file per game** in `Games/`, following `MemoryMatchView.swift`: a `View`, `@State` game state, `modelContext.record(GameSession(...))` on finish (inserts and saves, #106). No game engine, no base classes, no protocol ceremony until the 3rd game proves a pattern.
3. **Localization is not optional.** Every user-facing string goes in `Localizable.xcstrings` with EN + ES in the same commit. Hardcoded strings = rejected PR.
4. **Accessibility floor:** touch targets ≥ 60pt (we aim for 100pt), VoiceOver labels on every interactive element, Dynamic Type friendly fonts (`.title2` minimum for instructions). The one logged exception is Peg Solitaire's holes on phones, about 52pt ([decision, #615](decisions/2026-11.md)).
5. **Tone of failure:** the app never says "wrong/error/failed". Copy is warm: "Almost — try again" / "Casi — inténtalo de nuevo".
6. **After adding a `.swift` file**, run `swift tools/generate_project.swift` and commit the regenerated pbxproj.
7. **No keys, no network:** never commit keys; the app makes no network calls and holds no key. The dev-machine classifier uses `TYPESAFE_API_KEY` (see AGENTS.md); it never enters the repo, plist or binary.
8. **Review flow:** PRs to `main`. Before opening: build, tests and lint pass (AGENTS.md Workflow 5), strings in EN + ES (§3), `CHANGELOG.md` updated, no keys (§7), no medical claims.
9. **Tests: TDD for logic, BDD for flows.** New pure logic (scoring, policy,
   plan composition, adaptivity) is written test-first in `LudavelaTests/`,
   with Given/When/Then method names (`testGivenXWhenYThenZ`). User-flow tests
   (XCUITest, when they exist) read as Given/When/Then steps. Do **not** test
   SwiftUI layout trivia or Codable wire shapes. Verify with
   `xcodebuild test -scheme Ludavela -destination 'platform=iOS Simulator,name=<device>'`
   (a simulator name alone may not resolve — pass `id=<UDID>` from
   `xcrun simctl list devices available` when in doubt).

