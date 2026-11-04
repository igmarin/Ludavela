# Simulator results for the new-look validation (#586, Part C and Known gaps)

Refs #586, epic #578. This is the simulator half of `docs/playtest-session-5.md`. It records what was seen and nothing else: no
preferences, no claim that anything got easier. Part D (players), the physical VoiceOver pass and Part E judgements are the owner's.

## Setup

- **Build:** `cfa269f` (main, "Add the playtest #5 sheet", after the epic's last PR `2932f86`), local-only Debug build with a
  temporary launch fixture (below). Baseline for Part E: `d53c28f`.
- **Devices:** iPhone SE (3rd generation) simulator and iPad Air 11-inch (M4) simulator, iOS 27.0 (24A434). No physical device.
- **Date:** 2026-11-03.
- **Conditions:** `xcrun simctl ui` for appearance and content size (`large`, `accessibility-extra-extra-extra-large` = AX5);
  language by launch argument `-appLanguage en|es`.
  Column "SE AX5" is English, light. Column "iPad ES dark AX5" is Spanish, dark, AX5.
- **Host load was very high** (load average above 200 at times). The app was reinstalled before every capture and each capture was
  looked at; one batch of three iPad captures (EN light welcome and two Home states) showed a stale screen and was taken again.

## What was seeded

**Every capture except the welcome screen is seeded, not played through the UI.** A temporary fixture in `LudavelaApp.swift`
(never committed; the diff against `origin/main` for `Ludavela/` and `LudavelaTests/` is empty in this PR) did, per launch:

- saved today's plan as Memory Lane, Sudoku, Up or Down (level 4 each);
- inserted sessions: none (new day), Memory Lane (partly played, and the mid-day celebration), all three (day done, end-of-day
  celebration), a 10-of-10 Memory Lane game (level offer), and six sessions over four days (My Week, My progress);
- mounted the screen directly (a game, `CelebrationView`, `HistoryView`, `MyProgressView`, `SettingsView`) or `HomeView`;
- for some AX5 captures only, set the scroll position (`defaultScrollAnchor` bottom or center) because the simulator cannot
  scroll without a tap or drag. Where that was used it is said below. No scrolling gesture was performed.

Also set by launch argument: `-hasSeenOnboarding YES`, first-play guides marked seen (`-guide.seen.<game> YES`) so a guide card did not
cover the game, and for the Home week-board checks `-games.hidden` (the three plan games visible, or all games hidden, as in the #586 comment).
The welcome row is a fresh install with no fixture. The Memory Lane, Sudoku and other deals are random, so boards differ between captures.

## Part C matrix

Legend: **ok** = nothing wrong seen on what was visible; **issue** = see the finding; **—** = not reached. "Top of screen only" means
the first screen was seen and the rest of the page was not. `[m]` = a size estimate is in "Sizes" below.

| Screen | SE, EN light | SE, ES dark | SE, AX5 (EN light) | iPad, EN light | iPad, ES dark, AX5 |
|---|---|---|---|---|---|
| Welcome (fresh install) | ok | ok (language button "Igual que el teléfono" wraps to 3 lines, not cut) | — (first screen only: text runs past the fold, "Let's play" not seen) | ok | ok |
| Home, new day | ok | ok | ok (week board: see Known gaps) | ok | ok |
| Home, day partly played | ok | ok | ok | ok | ok |
| Home, day done | ok | ok | **issue F2** ("Up…" on the stacked card) | ok | **issue F3** ("Su…", and "Com-partir" broken mid-word) |
| Memory Lane | ok | ok | ok [m] | ok | ok |
| Sudoku | ok [m] | ok | ok (keys seen with scroll position forced to bottom) | ok | ok |
| Word Search | ok (table reaches the screen edges: designed in #599) | ok | ok (top of screen only) | ok | ok |
| Tile Pairs | ok | ok | ok (top of screen only) | ok | ok |
| Sliding Blocks | ok (controls below the first screen, not scrolled to) | ok (button "Mués-trame un paso" wraps to 3 lines) | **issue F1** (button labels break letter by letter) | ok | ok (same 3-line wrap as SE ES) |
| Up or Down | ok [m] | ok | ok | ok | ok |
| Celebration, mid-day | ok | ok | ok (main button wraps to "Next: / Sudoku") | ok | **issue F5** ("Siguiente: Sud…") |
| Celebration, end of day | ok | ok | ok (seen with scroll position forced to bottom) | ok | ok |
| Celebration, level offer | ok | ok | ok (forced scroll position, see gaps) | ok | ok |
| My Week | ok | ok | ok | ok | ok |
| My progress / Settings | ok | ok | ok (first screen of each) | ok | ok |

Also looked for and not seen in any reached cell: a colour carrying meaning alone (Home ticks, week slots and the Sudoku "done number" key
all also carry a shape or text), and hard-to-read text on the jade table. The red-on-tan "No card fits" line on Up or Down in light mode is readable
in the captures; I did not measure contrast.

### Findings (each is an "issue" cell; no GitHub issues were opened)

- **F1. Sliding Blocks, SE, AX5, English.** The three bottom buttons share one row and their labels break letter by letter:
  "Und/o", "Star/t/ove/r", "Sho/w/me/a/mov/e". Seen with the scroll position forced to the bottom. Screenshot `01`.
  Same screen at default text (SE, ES dark) and on iPad at AX5 does not do this (it wraps by syllable over 3 lines).
- **F2. Home, day done, SE, AX5.** The stacked card shows "Up…" instead of "Up or Down". Screenshot `02`.
- **F3. Home, day done, iPad, ES dark, AX5.** The stacked card shows "Su…" (Sube o baja), and the share button wraps to five lines with "Com-" / "partir"
  broken mid-word. Screenshot `03`.
- **F5. Celebration mid-day, iPad, ES dark, AX5.** The main action reads "→ Siguiente: Sud…" (the game name is cut). Screenshot `04`.

### Sizes (estimated from the screenshots, not measured on device)

- SE, default text: Sudoku keys about 76 x 95 pt (four across 343 pt); Up or Down cards about 62 x 95 pt (five across).
- SE, AX5: Memory Lane cards about 80 pt wide (four columns, three rows seen); Up or Down cards about 61 pt wide.
- These are below the 100 pt that conventions §4 asks of game controls; they are listed as facts for the lead, not marked as issues.

## Known gaps

| Gap | Result (observed) |
|---|---|
| My Week at AX5, SE, Spanish: no weekday label ends in "…" (#595) | Observed: no ellipsis. "Dom Lun Mar Mié Jue Vie Sáb" all complete, My Week at AX5 on SE, ES dark (`09`). The Home week board at AX5 on SE also shows complete labels in EN light with three games visible (`07`) and ES dark. |
| The #586 comment (SE, EN, dark, AX5, all games hidden: six labels cut) | Not reproduced on `cfa269f`: same condition, all labels complete (`08`). Seen at three scroll positions. Not tried: a fresh install with hidden games set through Set up rather than launch argument. |
| Sudoku and Tile Pairs in dark, in Spanish and at AX5 (#599) | Seen: SE ES dark (default text), SE ES dark AX5 (`10`, top of screen), SE EN light AX5, iPad ES dark AX5. Nothing cut or unreadable in what was visible. |
| Sliding Blocks: is the amber exit arrow easy to see? | Described, not decided. A small amber arrow, roughly 20 pt, sits in the gap of the board's bottom edge, beside the bottom-left block. On light jade it is amber on pale green (`01`); on dark jade it is amber on dark green (`05`). It is much smaller than the blocks. In the iPad captures the mark is smaller still. |
| Celebration with Reduce Motion on | — Not reached: `simctl ui` has no Reduce Motion option here, and a screenshot taken seconds after launch cannot tell a skipped animation from a finished one. |
| The level offer at AX5: both answers reachable by scrolling, main button still below (#583) | Partly observed. At AX5 on SE (EN light, and ES dark) with the scroll position forced to the bottom, "Yes, let's try", "Keep it as it is" and the main button "Next: Sudoku" are all in the page, answers above the button (`06`). I did not drag the page, so "reachable by scrolling" is inferred from that. On iPad at AX5 all of it is on the first screen. |
| VoiceOver items (Home heading, next-game name, "played today", day slot, found pair, celebration main action) | pending (owner, device) |

A card travelling to the week slot was caught mid-flight in one iPad ES dark AX5 capture of the level offer (a small card over the slot). The screenshot was taken during the
celebration's arrival animation, under heavy host load. Not treated as a finding.

## Part E, simulator side

Only the baseline condition (Spanish, default text, light) matches, and only on an iPhone SE: the baseline captures are iPhone 17-sized (1206 x 2622 px), so the
layouts differ in height too. Seeded states are not the baseline's states (see "Home" and "Celebration"). Descriptions only.

- **Home** (baseline `baseline-home-iphone.png`, mine `11`): baseline shows a table with a green-to-amber gradient, three fanned cards with a coloured name band, and
  one cream button "Empezar los juegos de hoy" below them. Mine shows a flat pale-green table, a cream card with a jade border above the cards reading
  "Jugar: Camino de Memoria" with the game's picture, and three cream cards with the name in dark text under the picture and no band. The greeting is "Buenas noches"
  (baseline "Buenas tardes", a time-of-day difference). The week card is below the first screen on the SE, and is in the first screen of the baseline.
- **Game card** (baseline `baseline-card-iphone.png`, an isolated card): the card is not captured in isolation in this pass. In the Home fan of `11` the name is dark text on cream, where the baseline card
  has cream text on a jade band. Names "Camino de / Memoria" and "Sube / o baja" break over two lines on the SE.
- **Celebration** (baseline `baseline-celebration-iphone.png`, mine `12`): baseline has a gradient behind a "Hoy: 0 de 3" capsule, a headline, a line "Encontraste todas las parejas." and the jade button on two
  lines ("Siguiente: Camino de Memoria"). Mine has a flat pale-green top, "Hoy: 1 de 3", the headline, no line under it, and the jade button on one line ("Siguiente: Sudoku"); the week slot for Tuesday is filled
  because one session is seeded.

## Observed, preferred, pending

- **Observed:** everything above. All on simulators, all seeded except the welcome row.
- **Preferred:** nothing recorded. No one was asked.
- **Pending:** Part D (players); VoiceOver on a device; Reduce Motion on screen; physical iPhone SE and iPad; dragging the page at AX5 on the welcome, level offer and Sliding Blocks screens; the
  Home week board at AX5 with the fixture removed (real played day); Part E judgements ("same, better, worse"); the iPad baseline comparisons; the first-play guide cards (suppressed here, seen only on the first pass
  of the SE EN light column, not catalogued).

## Screenshots (12, resized with `sips -Z 1200`)

`01` SE AX5 EN Sliding Blocks buttons (F1) · `02` SE AX5 EN Home day done (F2) · `03` iPad ES dark AX5 Home day done (F3) · `04` iPad ES dark AX5 celebration (F5) ·
`05` SE ES dark Sliding Blocks, exit arrow · `06` SE AX5 EN level offer, scrolled to bottom by the fixture · `07` SE AX5 EN Home week board ·
`08` SE AX5 EN dark, all games hidden, week board · `09` SE ES dark AX5 My Week · `10` SE ES dark AX5 Sudoku · `11` SE ES light Home, new day · `12` SE ES light celebration, mid-day.
