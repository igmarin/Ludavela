# Pilot look on Sudoku, Word Search and Tile Pairs (#599)

Same change as Memory Lane (#582) in three more games: the play area sits on the flat jade table
(`Color.tableSurface`, radius 30), drawn outside the board's own space (`.padding(n).background(...).padding(-n)`),
and the instruction is `.title2` semibold in espresso. Nothing else changed: rules, levels, deals, stimulus colours.

## Decisions

- **Sudoku:** table 8pt outside the board (the grid, not the keys). The pad and "Show me one" stay on cream.
- **Word Search:** table 4pt outside the grid, not 8. On an iPhone SE the grid is 367pt wide with 4pt side margins
  (`WordSearchDeal.sideMargin`, from #560), so 4pt is the most that stays on screen; the table touches the screen edges there.
  The word list and the theme title stay on cream.
- **Tile Pairs:** table 8pt outside the board's space. Tile Pairs has no board surface of its own: the "8% field" in the
  inventory of #582 is the hatching drawn on covered tiles (`HatchOverlay`), which stays. So the table is the first surface, not a
  replacement. It fills the offered space; tiles are fitted to that space as before.
- No `.secondary` text exists in these three games, so nothing moved to `inkSoft`. No new strings.

## Size proof: main (6be10f2) vs this branch

A temporary launch fixture (removed before commit) mounted each game at a forced level and logged what the layout computed.
Simulators at their default text size, English, light.

| Device | Game | Level 1 / 5 / 10 on main | Level 1 / 5 / 10 on this branch |
|---|---|---|---|
| iPhone SE 3 (play area 343 x 561) | Sudoku | 4x4 at 84.25pt / 4x4 / 4x4 (all 84.25pt) | identical |
| iPhone SE 3 (grid space 367) | Word Search | 6x6, 61.17pt squares at every level | identical |
| iPhone SE 3 (board 343 x 320) | Tile Pairs | 8 / 24 / 44 tiles | identical |
| iPhone 17, 6.1" class (play area 370 x 692) | Sudoku | 4x4 at 91pt / 4x4 at 91pt / 6x6 at 60pt | identical |
| iPhone 17 (grid space 394) | Word Search | 6x6, 64pt squares at every level | identical |
| iPhone 17 (board 370 x 477.67) | Tile Pairs | 8 / 24 / 60 tiles | identical (same board height, 477.67) |

The iPhone SE Tile Pairs board is held at its 320pt minimum height; a first comparison on the iPhone 17 at a different
simulator text size showed a 3pt height difference, which was the text size, not the change: rerun at the same size the
heights match.

Unit tests pin the pure parts, and pass on main and on this branch: `SudokuPuzzleTests` (layout and side at 343 and 370),
`WordSearchDealTests` (side and cell at 367 and 394), `TilePairsDealTests` (8 / 24 / 44 tiles at 343 x 320).
The "view is offered the same space" part can only be checked on a simulator, which is the table above.

## Captures

- `iphone-se-word-search-es-dark.png`: iPhone SE 3, Spanish, dark, level 5: grid on the table, 4pt out, 6x6 at 61pt.
- `iphone-se-sudoku-en-light.png`: iPhone SE 3, English, light, level 5.
- `iphone-17-tile-pairs-en-light.png`: iPhone 17, English, light, level 5.
- `iphone-17-word-search-ax5.png`: iPhone 17, English, light, accessibility 5: the instruction wraps to two lines, the grid keeps its squares.

## Not verified

- No iPad. No dark capture of Sudoku or Tile Pairs, no Spanish capture of them (strings did not change).
- AX5 was captured for Word Search only (and Tile Pairs in a scratch run, not kept: instruction on three lines, board still
  fits). Sudoku at AX5 was not captured.
- Reduce Motion and VoiceOver not exercised (no behaviour changed); a physical VoiceOver pass is pending (#586).
