# Memory Lane pilot (#582)

Memory Lane (and Names and Faces, the same view with `variant: .captions`) carries the look the owner approved
in #578: cream paper, the flat jade table (`Color.tableSurface`, as on Home), espresso text on cream and one
2pt espresso outline per card. Nothing else from the mockups was applied. Rules, levels, scoring and deals are untouched.

## What changed

- **Board:** sits on a rounded `tableSurface` panel (radius 30, as Home's table). The panel is drawn 8pt outside the board's own
  space (`.padding(8).background(...).padding(-8)`), so the board is offered exactly the room it had before. Grid sizing
  (`gridFit`, `cappedPairs`, `minCard`) is untouched and every screen deals the same pairs as before (see the review below).
- **Header:** the instruction is `.title2` semibold in espresso; spacing is unchanged.
- **Found pairs:** the card keeps its checkmark and jade wash, now drawn over paper. Before, the wash replaced the paper
  and the new table showed through the card. The checkmark is capped at `.xxxLarge` text scaling: at AX5 it grew to
  cover the whole card, hiding the picture (same cap as Category Fluency's badge).
- **Photos:** family photos render as before (the captures use photo cards; Names and Faces shares the view).
- **Progress:** Memory Lane has no round counter. The found-pair signal (checkmark and wash on the card, "Pair found"
  spoken to VoiceOver) is kept as is. A first version added a "Pairs found: 2 of 6" line; it cost about 30pt of board and,
  with a level note showing, dealt fewer pairs on an iPhone SE than main, so it was removed (review of #592). It can come back
  if the board can give the room back.
- No new strings.

## Review: same pairs on iPhone SE (3rd generation)

Measured on the simulator with a temporary fixture (removed before commit) that logs the board's size and forces the level.
Final board size after layout settles, English, light, default text, no level note:

| Build | Board size (pt) | Pairs at level 1 / 5 / 10 |
|---|---|---|
| main (376c2c7) | 343 x 511 | 3 / 7 / 12 |
| first version of this PR (panel padding + count line) | 319 x 471 | 3 / 7 / 12 (but 10 at level 10 with a two-line level note: computed with `gridFit`, not run) |
| this version | 343 x 511 | 3 / 7 / 12 |

The first version already dealt the same pairs without a level note, but its margin was thin: with a two-line level note
the computation above gives 10 pairs where main gives 12, so it is not shipped. This version offers the board the same size as main
(same logged sequence of sizes, including the transient first layouts), so the pair count cannot differ on any screen.
`MemoryMatchLevelsTests.testGivenIPhoneSEBoardWhenPairCountAtLevelsOneFiveTenThenPairsAreNeverFewer` pins 3 / 7 / 12 at the
measured 343 x 511 and at 459 and 431 (one-line and two-line level note, `title2` at 28pt a line plus the 24pt gap; derived, not measured).
It passes on main too, because the fitting code is unchanged: the layout equality itself can only be checked on the simulator
(the table above), not by a unit test.

## Captures

Own iPhone 17 simulator (iOS 27, 402x874 pt) and the iPhone SE 3 simulator, driven by a temporary launch fixture (removed
before commit) that mounts `MemoryMatchView` and plays the first matching pairs. The photos are art samples copied into the
simulator's own album; not part of the repo or the app.

- `memory-lane-en-light.png`: English, light, default text, three pairs found (photo cards, checkmark and wash).
- `memory-lane-es-dark.png`: Spanish, dark, default text, two pairs found.
- `memory-lane-en-light-ax5.png`: English, light, accessibility 5 (largest text). The instruction wraps to three lines and the board keeps six pairs.
- `iphone-se-level-10.png`: iPhone SE 3, English, light, level 10: 12 pairs, same cards as main (about 77 x 75pt, 60pt floor).

Names and Faces was captured on an earlier build of this PR (with the count line), not on the final one; its layout is the same view.

Card sizes from the captures (points): 6-pair level on iPhone 17, about 116 x 151 at default text, the same as main (the table is
outside the board's space); AX5, about 116 x 109. Both stay above the 60pt floor of conventions §4, and the 100pt aim.

## Checks against the acceptance list

- Pair recognition and selection: unchanged code path (`flip`, `MemoryBoard`); the fixture matched pairs through it.
- Large text: instruction readable at AX5 (`.title2` or larger); cards at least 100pt in the AX5 capture.
- Dark mode: captured (ES). Light: captured (EN, SE).
- Reduce Motion: the code paths are the ones that existed (`reduceMotion` in `face`); the only new views are a panel and a
  colour, with no motion. Not toggled in the simulator.
- VoiceOver: card labels, hints and the tap announcements are unchanged. Not listened to (no device); a physical VoiceOver pass is still pending (#586).

## Inventory: how the other games differ (not changed here)

All 18 games already share `gameHeader` (cream page, ink tint, read-aloud button), `LevelExplainBanner`, `AnswerTileStyle`
(paper + wash + 3pt ink edge + hard shadow), `CheckBadge`, `MissCue`, `AnswerBeat`/`answerMark`, `RoundCounter`/`ProgressCards`
and `PictureView`. What differs, by file in `Ludavela/Games/`:

| Aspect | Memory Lane now | Others today | Reusable as is |
|---|---|---|---|
| Table behind the play area | `tableSurface` panel | None: content on bare cream. Own surfaces: ColorClash question card `systemBackground`; PegSolitaire amber 35% board; NumberSlide wood tray (`Wood.tray`); TilePairs `Color.primary` 8% field; Tangram/UpOrDown paper cards | `Color.tableSurface` + `.padding(12).background(..., in: .rect(cornerRadius: 30))`. Needs a ticket per game that has its own surface (colour-as-stimulus or wood art must be kept) |
| Instruction | `.title2` semibold, espresso | `.title2` regular, default colour in nearly all (ColorClash, MathStreak, Peg, Sudoku, Tangram, TilePairs, UpOrDown, WordSearch, QuickEyes, SlidingBlocks, NumberSlide, RepeatSequence); Riddles serif italic; Reminiscence `.largeTitle` | The same two modifiers: `.font(.title2.weight(.semibold)).foregroundStyle(Color.espresso)` |
| Progress | none added (checkmark and wash on found cards) | `RoundCounter` / `ProgressCards` in ColorClash, MathStreak, QuickEyes, RepeatSequence, Sayings, Riddles, Reminiscence, CategoryFluency; none in Sudoku, SlidingBlocks, Tangram, TilePairs, Peg, UpOrDown, WordSearch, NumberSlide | `ProgressCards` as is. TilePairs is the closest twin of Memory Lane and also has no pairs line |
| Found / correct mark | `CheckBadge`, capped | `CheckBadge` uncapped via `answerMark` (ColorClash, MathStreak, QuickEyes, Riddles); CategoryFluency caps it like here; WordSearch uses a plain check glyph and strikethrough | Cap in `CheckBadge` itself (one line) instead of at each call site: a separate ticket, since it changes every game |
| Answer buttons | n/a (cards) | `AnswerTileStyle(minHeight: 100)` almost everywhere; Riddles' "Give me a clue" button is 72 (a secondary action), ColorClash tiles 110 | Already shared. The 72pt clue button is above the 60pt floor but below the 100pt aim: a decision for its own ticket |
| Card/tile outline | 2pt espresso | `AnswerTileStyle` 3pt tint edge; Lotería 4pt tint; UpOrDown 2pt ink; Tangram `.secondary` | Spec says one 2pt espresso outline per card: decide whether answer tiles follow (separate ticket) |
| Secondary text colour | `inkSoft` not used here | `.secondary` in Reminiscence, Tangram, UpOrDown, ColorClash, SlidingBlocks fallback text (3.3:1 on cream, #527) | `Color.inkSoft` |
| Page background | `gameHeader` paper | Same everywhere | Already shared |

Candidate follow-up tickets (none opened by this PR): (1) table panel and espresso instruction in the games that have no surface
of their own (Sudoku, WordSearch, SlidingBlocks, UpOrDown, TilePairs); (2) cap `CheckBadge` scaling in the shared view;
(3) Riddles clue button at 72pt; (4) `.secondary` to `inkSoft` in five games; (5) a pairs-found line for Memory Lane and TilePairs, if a layout can give the room back.
No new abstraction is proposed: each item reuses a component that already has several users.

## Gaps (not verified)

- No iPad capture; other iPhone sizes follow from the same size equality with main.
- Level notes (the banner above the board) were not forced on the simulator; the two-line case is computed.
- Reduce Motion and VoiceOver not exercised on the simulator or a device.
