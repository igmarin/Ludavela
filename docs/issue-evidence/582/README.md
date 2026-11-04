# Memory Lane pilot (#582)

Memory Lane (and Names and Faces, the same view with `variant: .captions`) carries the look the owner approved
in #578: cream paper, the flat jade table (`Color.tableSurface`, as on Home), espresso text on cream and one
2pt espresso outline per card. Nothing else from the mockups was applied. Rules, levels, scoring and deals are untouched.

## What changed

- **Board:** sits on a rounded `tableSurface` panel (12pt inside, radius 30 like Home's table). The grid is sized to
  what is left inside the panel, so cards are dealt and fitted exactly as before (`gridFit`, `cappedPairs`, `minCard` unchanged).
- **Header:** the instruction is `.title2` semibold in espresso. Gaps between header and board went from 24pt to 12pt,
  which pays for the new line below.
- **Progress:** one line, "Pairs found: 2 of 6" / "Parejas encontradas: 2 de 6", in the game's ink. It is words, not a
  row of progress cards: the cards already show found pairs, and a progress row would have cost about 30pt more of board.
  At accessibility sizes it is left out (it would take two more lines of the board's room); the checkmarks and VoiceOver's
  "Pair found" announcement remain. `MemoryBoard.pairsFound` / `pairCount` feed it (tested).
- **Found pairs:** the card keeps its checkmark and jade wash, now drawn over paper. Before, the wash replaced the paper
  and the new table showed through the card. The checkmark is capped at `.xxxLarge` text scaling: at AX5 it grew to
  cover the whole card, hiding the picture (same cap as Category Fluency's badge).
- **Photos:** family photos and captions render as before (photo-captions screenshot below).
- New string `game.memory.found %lld %lld`, EN + ES.

## Captures

Own iPhone 17 simulator (iOS 27, 402x874 pt), driven by a temporary launch fixture (removed before commit) that
mounts `MemoryMatchView` and plays the first matching pairs. Photos in the captions capture are art samples copied
into the simulator's own album, with invented names; not part of the repo or the app.

- `memory-lane-en-light.png`: English, light, default text, two pairs found.
- `memory-lane-es-dark.png`: Spanish, dark, default text, two pairs found.
- `memory-lane-en-light-ax5.png`: English, light, accessibility 5 (largest text). The instruction wraps to three lines,
  the progress line is left out, the board keeps six pairs.
- `names-and-faces-en-light.png`: Names and Faces with a photo card and its caption found, both with the checkmark.

A baseline capture before the change (English, light, default text; board on bare cream, instruction `.title2` regular,
no count) was taken but is not committed, to stay under four images.

Card sizes read from the captures (points): level with six pairs, default text, 109 x 140 (was 116 x 151 on bare cream);
AX5, 109 x 105 here. The panel costs about 7pt of card width. Cards stay at or above the 60pt floor of conventions §4 and
the 100pt aim in both captures. On a small phone, a level with many pairs can still deal fewer pairs than before, by
`cappedPairs`' existing rule that cards never go under 60pt; not measured on a small device (see Gaps).

## Checks against the acceptance list

- Pair recognition and selection: unchanged code path (`flip`, `MemoryBoard`); the fixture matched pairs through it.
- Large text: instruction readable at AX5 (`.title2` or larger); cards at least 100pt in the AX5 capture.
- Dark mode: captured (ES). Light: captured (EN).
- Reduce Motion: the code paths are the ones that existed (`reduceMotion` in `face`); the only new views, a panel
  and a text line, have no motion. Not toggled in the simulator.
- VoiceOver: card labels, hints and the announcements on each tap are unchanged; the new line is plain text that reads
  itself and is hidden before the deal. Not listened to (no device); a physical VoiceOver pass is still pending (#586).

## Inventory: how the other games differ (not changed here)

All 18 games already share `gameHeader` (cream page, ink tint, read-aloud button), `LevelExplainBanner`, `AnswerTileStyle`
(paper + wash + 3pt ink edge + hard shadow), `CheckBadge`, `MissCue`, `AnswerBeat`/`answerMark`, `RoundCounter`/`ProgressCards`
and `PictureView`. What differs, by file in `Ludavela/Games/`:

| Aspect | Memory Lane now | Others today | Reusable as is |
|---|---|---|---|
| Table behind the play area | `tableSurface` panel | None: content on bare cream. Own surfaces: ColorClash question card `systemBackground`; PegSolitaire amber 35% board; NumberSlide wood tray (`Wood.tray`); TilePairs `Color.primary` 8% field; Tangram/UpOrDown paper cards | `Color.tableSurface` + `.padding(12).background(..., in: .rect(cornerRadius: 30))`. Needs a ticket per game that has its own surface (colour-as-stimulus or wood art must be kept) |
| Instruction | `.title2` semibold, espresso | `.title2` regular, default colour in nearly all (ColorClash, MathStreak, Peg, Sudoku, Tangram, TilePairs, UpOrDown, WordSearch, QuickEyes, SlidingBlocks, NumberSlide, RepeatSequence); Riddles serif italic; Reminiscence `.largeTitle` | The same two modifiers: `.font(.title2.weight(.semibold)).foregroundStyle(Color.espresso)` |
| Progress | "Pairs found" line | `RoundCounter` / `ProgressCards` in ColorClash, MathStreak, QuickEyes, RepeatSequence, Sayings, Riddles, Reminiscence, CategoryFluency; none in Sudoku, SlidingBlocks, Tangram, TilePairs, Peg, UpOrDown, WordSearch, NumberSlide | `ProgressCards` as is. TilePairs is the closest twin of Memory Lane and has no pairs line: a candidate |
| Found / correct mark | `CheckBadge`, capped | `CheckBadge` uncapped via `answerMark` (ColorClash, MathStreak, QuickEyes, Riddles); CategoryFluency caps it like here; WordSearch uses a plain check glyph and strikethrough | Cap in `CheckBadge` itself (one line) instead of at each call site: a separate ticket, since it changes every game |
| Answer buttons | n/a (cards) | `AnswerTileStyle(minHeight: 100)` almost everywhere; Riddles' "Give me a clue" button is 72 (a secondary action), ColorClash tiles 110 | Already shared. The 72pt clue button is above the 60pt floor but below the 100pt aim: a decision for its own ticket |
| Card/tile outline | 2pt espresso | `AnswerTileStyle` 3pt tint edge; Lotería 4pt tint; UpOrDown 2pt ink; Tangram `.secondary` | Spec says one 2pt espresso outline per card: decide whether answer tiles follow (separate ticket) |
| Secondary text colour | `inkSoft` not used here | `.secondary` in Reminiscence, Tangram, UpOrDown, ColorClash, SlidingBlocks fallback text (3.3:1 on cream, #527) | `Color.inkSoft` |
| Page background | `gameHeader` paper | Same everywhere | Already shared |

Candidate follow-up tickets (none opened by this PR): (1) table panel and espresso instruction in the games that have no surface
of their own (Sudoku, WordSearch, SlidingBlocks, UpOrDown, TilePairs); (2) cap `CheckBadge` scaling in the shared view;
(3) Riddles clue button at 72pt; (4) `.secondary` to `inkSoft` in five games; (5) a pairs line for TilePairs.
No new abstraction is proposed: each item reuses a component that already has several users.

## Gaps (not verified)

- No small phone (iPhone SE) or iPad capture; board size there follows `cappedPairs`, whose inputs now lose about 30pt of
  height to the new line and 24pt of width to the panel.
- Reduce Motion and VoiceOver not exercised on the simulator or a device.
- The tint colour of the progress line is the game's ink; its contrast is the one `ContrastTests` already checks for game inks on paper.
