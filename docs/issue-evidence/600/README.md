# Sliding Blocks and Up or Down on the table (#600)

Both games get the look piloted on Memory Lane (#582): the play area on Home's flat jade table
(`Color.tableSurface`, radius 30), the instruction `.title2` semibold in espresso. Nothing else changed.

- **Sliding Blocks:** the table is behind the board only (`.padding(8).background(...).padding(-8)` on the board, inside the
  `GeometryReader`), so `SlidingBoardLayout.cellSize` sees the same area. Block colours, stripes, selection and arrows are untouched.
- **Up or Down:** the table is behind the pile row, the open card and the deck, drawn the same way. Suit symbols and red / black
  are untouched. The empty-pile outline, which was `.secondary`, is `Color.inkSoft` (the only `.secondary` in either game).
  The note ("almost") and the instruction stay on the cream above the table.
- No new strings, no new files, no change to rules, levels, deals, scoring or `DailyPolicy`.

## Same board as main

Method: a temporary launch fixture (not committed) mounts the game at a chosen level and logs what it was laid out with;
the same fixture was built on main (`6be10f2` views) and on this branch. Settled values, English, light, default text
(`large`), no level note, first-play guide hidden.

| Device | Game | Level | main | this branch |
|---|---|---|---|---|
| iPhone SE 3 (375 pt) | Up or Down | 1 | 3 piles, card 109.0 pt wide, row 343 | same |
| iPhone SE 3 | Up or Down | 5 | 5 piles, card 62.2 pt, row 343 | same |
| iPhone SE 3 | Up or Down | 10 | 5 piles (7 asked, 5 fit), card 62.2 pt, row 343 | same |
| iPhone SE 3 | Sliding Blocks | 1 | area 343 x 340, cell 85.0 pt (3 x 4) | same |
| iPhone SE 3 | Sliding Blocks | 5 | area 343 x 340, cell 68.0 pt (4 x 5) | same |
| iPhone SE 3 | Sliding Blocks | 10 | area 343 x 340, cell 68.0 pt (4 x 5) | same |
| iPhone 17 (402 pt) | Up or Down | 1 / 5 / 10 | 3 / 5 / 5 piles, cards 118.0 / 67.6 / 67.6 pt, row 370 | same |
| iPhone 17 | Sliding Blocks | 1 | area 370 x 417.7, cell 104.4 pt | same |
| iPhone 17 | Sliding Blocks | 5 / 10 | area 370 x 417.7, cell 83.5 pt | same |

The whole sequence of logged sizes was identical on iPhone 17. On the SE, main logged one extra transient first layout
(343 x 360.5) in the Sliding Blocks runs that the branch did not; the settled sizes are the same. The 5-pile cards on an SE
(62.2 pt) are above the 60 pt floor and that is main's number too.

`UpOrDownDealTests.testGivenIPhoneSEWidthWhenPileCountAtLevelsOneFiveTenThenThreeFiveFive` pins 3 / 5 / 5 piles at 343 pt (written
before the view change; it passes on main too, because the fitting code is untouched). Sliding Blocks' fitting depends on the
space SwiftUI offers, so that part is only checked on the simulator (table above).

## Captures (iPhone 17 unless noted, temporary fixture)

- `iphone-se-up-or-down-level-10.png`: iPhone SE 3, English, light, level 10: five piles, 62 pt cards.
- `iphone-se-sliding-blocks-level-10.png`: iPhone SE 3, English, light, level 10 (4 x 5 board, 68 pt cells; the controls scroll under it, as on main).
- `sliding-blocks-es-dark-level-5.png`: Spanish, dark, level 5.
- `up-or-down-en-light-ax5-level-10.png`: English, light, accessibility 5: the instruction wraps to three lines, the cards keep their size.

## Not verified

- No iPad capture; no level note forced on screen.
- Reduce Motion and VoiceOver not exercised (no code path in them changed; the table is a background); a physical VoiceOver pass is #586.
- Sliding Blocks' amber exit chevron is as faint on the table as it was on cream (it is a mark on top of the open gap in the frame, not the only cue); not changed, since it is a stimulus colour.
- The "6.1-inch" check used an iPhone 17 (6.3 inch, 402 pt wide).
- Names of the captures are the only record: the fixture is not in the repo.
