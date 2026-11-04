# Ludavela

Warm, bilingual (EN/ES) fun mental exercise for older adults, built for one family first.

Add your family's photos in Set up, and Memory Lane and Names and Faces play with them.
Eighteen calm games, levels 1–10, offline and private. Big buttons, no countdown clocks,
no fail shame: "Almost, try again", never "wrong".

## Status

18 games playable (Lotería, the 19th, is hidden until its play makes sense, #573), offline-first,
EN and ES complete. Testers get builds through TestFlight; the App Store release is tracked in
[#194](https://github.com/igmarin/Ludavela/issues/194). See [CHANGELOG.md](CHANGELOG.md)
for what changed, [docs/roadmap.md](docs/roadmap.md) for what's next, and
[GitHub issues](https://github.com/igmarin/Ludavela/issues) for live work.

## The games

| Game | What you do |
|---|---|
| Memory Lane | Find the matching pairs of illustrated cards, or of your family's photos |
| Color Clash | Tap the colour of the ink, not the word |
| Name the Herd | Tap everything that belongs to the category |
| Number Trail | Quick sums in a row; the operations and numbers grow with the level |
| Quick Eyes | Look at a picture, then find it among the choices. Paced at levels 1–5; a quick flash at levels 6–10 |
| Photo Stories | Look at your family's photos one at a time and tell a story about each. Dealt once you have added photos. Nothing to get wrong |
| Sudoku | Fill the board, from 4×4 up to 9×9, each with one solution |
| Up or Down | Golf solitaire: play a card one higher or one lower |
| Finish the Saying | Pick the ending of a familiar saying |
| Repeat the Sequence | Watch the lit tiles, then repeat them in order |
| Tangram | Fill the silhouette with seven tiles |
| Tile Pairs | Find two free tiles that match |
| Sliding Blocks | Slide the blocks to free the big one |
| Number Slide | Rompecocos, the 15-number sliding puzzle: put the numbers in order on a 3×3 or 4×4 board |
| Names and Faces | Match each family photo to its caption |
| Peg Solitaire | Jump over pegs until one remains |
| Word Search | Find themed words hidden in a grid |
| Riddles | Read a few lines and pick the word they describe |

Home deals today's picks and each game opens at its level for the day. Both are
decided by a small rule policy on the device (no network, no cost).

## How it is built

- Zero third-party dependencies: SwiftUI, SwiftData and Foundation only.
- Daily picks and levels are decided on the device by `DailyPolicy`. Each level follows a staircase:
  at most one move per game a day, never mid-game.
- Every game except Photo Stories has levels 1–10.
- Deals are small pure types that take the random generator as a parameter, so tests can
  replay them. Sudoku boards are generated with exactly one solution.
- Every string is in one catalogue, `Ludavela/Localizable.xcstrings`, in English and Spanish.
- No network calls, no accounts and no analytics. Photos stay on the device.

## Built with AI

Several AI coding assistants, including Meta's Muse Code, have worked on tickets, and the owner
merges every pull request. Some game pictures were made with AI image tools, then cut out, cropped
and resized; each prompt is logged in [docs/art-prompts.md](docs/art-prompts.md). The app itself
uses no AI at runtime.

## Build

Requires Xcode 16+, iOS 17+ target, zero third-party dependencies.
The App Store bundle identifier remains `com.igmarin.MenteViva` so updates use
the existing App Store record. The CloudKit container also keeps its current
identifier for any existing data.

```sh
swift tools/generate_project.swift   # regenerate project (local-only, the default)
open Ludavela.xcodeproj             # pick a simulator, press ▶︎
```

Two build modes, chosen at generation time:

| Mode | Command | Use when |
|---|---|---|
| **Local-only** (default) | `swift tools/generate_project.swift` | Everything for now — free Apple ID, simulator, any device. Store is on-device. |
| **CloudKit** | `swift tools/generate_project.swift --cloudkit` | Later, with the paid Developer account + provisioned container (iCloud sync/`CKShare`) |

Local-only defines `LOCAL_ONLY` at compile time and drops the entitlements file,
so the store is on-device only and a free Apple ID can provision it. CloudKit
mode traps on launch if built without the entitlement — that is why it is not
the default (see `AGENTS.md`).

After adding a `.swift` file: regenerate and commit the updated
`project.pbxproj` (see docs/conventions.md §6).

## Structure

```
Ludavela/
  LudavelaApp.swift      # app entry
  HomeView.swift          # game picker
  Models/                 # GameSession (SwiftData), RoundProgress, GameID, Difficulty
  Games/                  # one file per game; MemoryMatchView is the reference
  Services/               # DailyPolicy (on-device plan), LevelPolicy, MemoryPhotos, SoundPlayer, ...
docs/                     # product & design docs — start at docs/README.md
tools/generate_project.swift
```

## Docs

Start at [docs/README.md](docs/README.md): product brief, decision log, research, roadmap.

## Honest scope

This is not a medical app. The research (see [docs/research-2026-09.md](docs/research-2026-09.md))
finds weak transfer from brain games alone to daily life; they work best as one part of an engaged,
active life. Our copy says "fun mental exercise" and never promises cognitive outcomes.

## License

The code and docs are licensed under the [Apache License 2.0](LICENSE); see [NOTICE](NOTICE).
You may use, change and redistribute them, keeping the copyright and licence notices.

The name **Ludavela** and the app icon are not covered by that licence (Apache-2.0 §6 grants
no trademark rights). If you ship your own build, give it a different name and icon.

Contributions are accepted under the same licence (Apache-2.0 §5).
