# Post-redesign performance baseline — 2026-11-04 (#618)

**Simulator evidence, not a device speed verdict.** No code was optimised. The physical-device step is
still pending: no personal hardware was installed to or operated.

Codex started this ticket (cold launches only, on `d81fef0`) and ran out of tokens before the replay or a
report. Everything below was re-recorded on the commit named here; Codex's fixture and approach were kept.

## Setup

| | |
|---|---|
| Source | `aafaee5` (`main`, after #623) |
| Build | Release, `-O`, whole-module, local-only, `CODE_SIGNING_ALLOWED=NO` |
| Simulator | iPhone SE (3rd generation), iOS 27.0, on an Apple Silicon Mac, macOS 27.2 |
| Xcode | 27.2 (27B52) |
| Conditions | English, default text, light; onboarding marked seen; no saved plan, no family photos, no history |
| Recorder | `NO_OPEN=1 tools/profile.sh --launch <seconds> <udid>` (Time Profiler + Points of Interest) |
| Repeats | 3 cold launches (10 s each), then 3 replays (26 s each), one at a time under `lockf -k /private/tmp/ludavela-sim.lock` |
| Traces | 6 `.trace` files, about 4 MB each, kept on the recording machine only (not committed) |

The replay used a temporary fixture, archived here as [replay.patch](replay.patch) and removed before
committing. It drives Home's real navigation (Quick Eyes, back to Home, then Sliding Blocks). It imports
three generated 4032 × 3024 JPEGs (267 KB each) through `FamilyPhotoImport.run`, with an immediate loader
in place of PhotosPicker. It deals Sliding Blocks' largest level-10 board, `BBoo/BB<>/<>^o/o^vo/.v.o`.
It does not finish Quick Eyes, drag a block, tap a hint, or use the picker, real photos, captions or
permissions.

## Results

Signpost intervals as printed by `tools/signpost_budget.swift` (budget 100 ms):

| Interval | Cold 1 | Cold 2 | Cold 3 | Replay 1 | Replay 2 | Replay 3 | Runs on |
|---|---:|---:|---:|---:|---:|---:|---|
| `plan.today` | 5.69 ms | 0.44 ms | 0.41 ms | 3.86 ms | 0.46 ms | 0.44 ms | main actor, Home's first appear |
| `photo.import`, median of 3 photos | — | — | — | 15.06 ms | 15.14 ms | 15.73 ms | detached task |
| `photo.import`, worst (first photo) | — | — | — | 170.33 ms | 127.26 ms | 41.76 ms | detached task |
| `photo.downscale`, worst | — | — | — | 170.31 ms | 127.23 ms | 41.74 ms | detached task, inside `photo.import` |
| `sliding.hints` | — | — | — | 351.11 ms | 363.96 ms | 358.40 ms | detached task |

The replay's own timeline (seconds from the fixture start, all three runs within 0.15 s of each other):
Quick Eyes at 3.0, back on Home at 6.1, the 3-photo import from 9.3 to 9.4–9.55, Sliding Blocks at 11.5.
`plan.today` ran once per replay, so returning from Quick Eyes did not plan again. There is no
return-to-Home signpost, so navigation latency itself is not measured.

## Reading them

- **`plan.today` (main actor) is well inside the budget:** 5.7 ms on the first launch after install,
  0.4 ms after. This is the only interval here that blocks the main thread. The 2026-10-04 "known miss"
  (~300 ms on an iPhone 18 Pro simulator) is not reproduced on this source; it was measured on older
  code, a different simulator and with history, so this is a re-measurement, not a speed-up claim.
- **`photo.import` / `photo.downscale` go over 100 ms only on the first photo** of a cold process
  (170 and 127 ms), then sit at about 15 ms. Both run in a detached task: this is how long the family
  waits for a thumbnail to appear, not a frozen screen. The first-photo cost looks like a one-off
  (ImageIO and file-cache warm-up), but that is a hypothesis; the trace was not read call by call.
- **`sliding.hints` is about 355 ms on the largest board,** in line with 2026-10-31's 300–320 ms from an
  optimised test build on an iPhone simulator. It runs off the main thread; "Show me a move" stays disabled until it finishes,
  and the board stays playable meanwhile. The earlier ~10× rule of thumb puts an old device at about
  3.5 s before the button turns on. That is an estimate, not a measurement.
- **The script's `OVER` lines are not main-thread stalls here.** Every interval over 100 ms is detached
  work. Nothing in these traces argues for a localisation cache or a `fitOrScroll` rewrite, and
  neither was changed.

## Still open

1. A device trace, ideally on the slowest compatible device the owner authorises (dad's iPad on iOS 17),
   for cold launch, photo import with real photos, and the level-10 hint wait.
2. Whether players wait on "Show me a move" at levels 5–10 on that device: if they do, the hint build
   time (move generation, per 2026-10-31) is the thing to look at.
3. A drag trace in Sliding Blocks, to check frame times, which nothing here measures.
