# Session sheet — playtest #5 (the new look, on devices and with players)

Print this. Part A is for the player: one page, large type, no marks. Parts B–F stay with you; never hand
them over and never read their wording aloud ("task", "check", "error" are for you; ask "How was that?"
instead). Method and the one rule ("watch, don't help") live in [playtest.md](playtest.md). Issue: #586,
epic #578. It checks two things:

1. **On devices (you, alone, about 45 minutes):** does the new look hold on a small iPhone and an iPad, in
   English and Spanish, light and dark, at the largest text, with VoiceOver and Reduce Motion?
2. **With players (about 15 minutes each):** can someone start a game, tell which game is next, and get
   back to Home, without help?

Write down only what you saw. A preference ("I like the green") is not a finding about ease of use, and
no session here can show that the app got easier: say what happened, not how much better it is.

## Before you start

1. **Write down both builds.** Baseline: `d53c28f` (before the new look; its captures are in
   `docs/design/sobremesa-579/baseline-*.png`). Final: the commit you install (`git rev-parse --short HEAD`
   on `main`; the epic finished at `2932f86`). Every row in Parts C and D names the build it was seen on.
2. **Install over the existing app, never delete it.** Deleting erases the player's week and photos.
3. **Same conditions as the baseline** for the comparison rows: Spanish, default text, light mode,
   the same device model where you have one.
4. **Leave Set up alone** for the player sessions: no hidden games, no pinned level.
5. **Have one played day ready** on your own device for Part C: at least one finished game today, so the
   week board, the check marks and the celebration all have something to show.

## Part A — for the player (print on its own page, large type)

> **A few minutes with Ludavela**
>
> Thank you for trying the new look.
>
> There is nothing to get right and nothing to pass. If something makes you
> stop and wonder, that is exactly what we want to hear.
>
> Play the way you like. You can stop whenever you want.

Print at 24 pt or larger. Warm words only. No scores, no "tasks", nothing to fill in.

## Part B — header (fill in)

```
Date:                    Build (commit):            Baseline: d53c28f
Device / iOS:            Language:                  Text size:
Player (no names, e.g. "P1, 70s, plays daily"):
Who else was there:
```

## Part C — devices (you, alone)

Mark each cell **ok**, **issue** (open a ticket and write its number) or **—** (not checked). Leave a
cell empty rather than guess.

| Screen | iPhone SE, EN light | iPhone SE, ES dark | iPhone SE, largest text (AX5) | iPad, EN light | iPad, ES dark, AX5 |
|---|---|---|---|---|---|
| Welcome (fresh install) | | | | | |
| Home, new day | | | | | |
| Home, day partly played | | | | | |
| Home, day done | | | | | |
| Memory Lane | | | | | |
| Sudoku | | | | | |
| Word Search | | | | | |
| Tile Pairs | | | | | |
| Sliding Blocks | | | | | |
| Up or Down | | | | | |
| Celebration, mid-day | | | | | |
| Celebration, end of day | | | | | |
| Celebration, level offer | | | | | |
| My Week | | | | | |
| My progress / Settings | | | | | |

In each cell, look for: text cut off or "…", a button under its size (game controls should feel like a big
target), anything hard to read on the jade table, and a colour carrying meaning alone.

### Known gaps to close (from the PRs, not yet seen by anyone)

- [ ] My Week at AX5 on an iPhone SE, Spanish: no weekday label ends in "…" (#595).
- [ ] Sudoku and Tile Pairs in dark mode, in Spanish and at AX5 (#599).
- [ ] Sliding Blocks: is the amber exit arrow easy to see on the jade table? (owner decision pending)
- [ ] Celebration with Reduce Motion on: the daily picture shows face up, no turn or slide (#583).
- [ ] The level offer at AX5: both answers reachable by scrolling, the main button still below (#583).

### VoiceOver pass (one device is enough)

- [ ] Home at AX5: the first heading (rotor, Headings) is at the top of the screen (#597).
- [ ] Home: the next-game button reads the game's name; each recommended card reads its name and
      "played today" when it is.
- [ ] A day slot on the week reads the full weekday name.
- [ ] Memory Lane: a found pair is announced.
- [ ] Celebration: the main action is named ("Next: …", or Home at the end of the day).

## Part D — with players (three tasks)

Hand over the device on Home. Say only the line in quotes, then watch. Don't point, don't help, don't
explain. If the player asks, say "Do what feels natural." Help only if they are stuck for a full minute,
and write down that you did.

| | Say | Done without help? | Hesitations (where, how long) | Mis-taps | What they said |
|---|---|---|---|---|---|
| 1 | "Would you start a game?" | yes / with help / no | | | |
| 2 | "Which game comes next today?" (after one game) | yes / with help / no | | | |
| 3 | "Could you go back to the start?" | yes / with help / no | | | |

Then ask, once, at the end: "Was anything uncomfortable to read or to tap?" Write the answer in their
words.

Repeat the table per player. Two or three players is enough; if no one is available, write "pending" in
Part F. Never fill this part from your own guess of what a player would do.

## Part E — comparison with the baseline

Only where you ran the same condition on both builds (Before you start, step 3):

| Moment | Baseline (`d53c28f`) | Final | Same, better, worse — and why, in one line |
|---|---|---|---|
| Home: can you tell the next game at a glance? | | | |
| Game card: name readable without squinting? | | | |
| Celebration: obvious what to do next? | | | |

## Part F — after the session

1. Copy Parts C–E into `docs/issue-evidence/586/README.md`, with the builds and devices, and up to
   six screenshots resized with `sips -Z 1200`.
2. Every **issue** cell becomes a GitHub issue linked from that README. A serious one (an action that
   can't be reached, text that can't be read) is fixed before #586 closes.
3. Keep three lists apart in the README: what you **observed**, what people **preferred**, and what is
   still **pending** (devices or players you didn't have).
4. Comment on #586 with the README link. Close it only when Part C has no empty cells for the iPhone SE
   column and Part D has at least one real player, or says plainly why not.
