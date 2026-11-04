# Playtest protocol

How to run a playtest with family (#6) or with seniors outside the family (#33). Same method for
both; only the person holding the device changes. Each session has its own printable sheet:

| Sheet | Session |
|---|---|
| [playtest-session-1.md](playtest-session-1.md) | #1, dad's first playtest (#6); maps observations to #44, #46, #47 |
| [playtest-session-2.md](playtest-session-2.md) | #2, the Card Table redesign |
| [playtest-session-3.md](playtest-session-3.md) | #3, Sudoku, Up or Down and Finish the Saying |
| [playtest-session-4.md](playtest-session-4.md) | #4, a week alone on levels, onboarding and the four new games |
| [playtest-session-5.md](playtest-session-5.md) | #5, the new look (#586) |
| [playtest-outside.md](playtest-outside.md) | #33, testers outside the family: invite (EN + ES), sheet, findings template |

## The one rule

**Watch, don't help.** The moment you point at the screen, lean over, or say
"tap the puzzle thing", you've taught us what *you* know, not what the app
communicates. If he's stuck for 30 seconds, that's a finding. Write it down and
let him keep struggling a little — or hand him the device fresh later.

## Setup

- Real iPad, real lighting, volume at his normal level.
- App freshly installed: **onboarding shows on first launch only.** If he's
  already passed it, delete and reinstall to see his genuine first reaction.
  **Deleting the app erases My Week and all progress** (#106) — only do it
  before his first real week, never mid-way through.
- You sit beside, not across. Phone away.

## Watch for (in order of what we most need to know)

1. **First 30 seconds on onboarding** — does he read the lines? Does he find the
   language choice? Which language does he pick?
2. **The "Let's play" moment** — does he tap it without asking? If he asks "what
   do I do?", that's the most important finding of the session.
3. **Per game, first round only** — where does he hesitate, what does he tap
   first, does he look for instructions?
4. **When he gets one wrong** — reaction. Frustration? Amusement? Does he try
   again or stall? (Copy check: does the app feel kind?)
5. **End of a game** — does the celebration mean anything to him? Does he tap
   "Play again" or go home?
6. **My Week** — does he open it unprompted? Does he understand it?
7. **After 10 minutes** — put your phone away and just watch. Does he keep
   going? Did he ask a question nobody answered?

## Record

```
Date / who (relation, age, language, device, iOS):
Onboarding reaction:
Stuck where / how long:
Games played, in order:
Wrong-answer reaction:
Celebration: noticed / ignored
My Week: opened / ignored
Questions he asked:
Lasted (minutes) / came back later?:
Quote worth keeping:
Top 3 friction:
```

Top 3 friction goes into the issue. If a fix is obvious and small, fix it the
same day; if it needs a design decision, it becomes its own issue.

## Install

Testers install through TestFlight ([testflight-beta.md](testflight-beta.md)): builds last 90 days and
need no cable. A free-Apple-ID build from Xcode stops launching after 7 days; use it only on the
owner's development devices ([install-runbook.md](install-runbook.md)).

## Results

Findings go in the issue for the session (the Record block above, plus the top 3 friction).
#6 closed on 2026-10-05 with seven friction points, which became #106–#110. #33 closed on
2026-10-28 as not planned, with no outside sessions recorded.

## What counts as success

- **#6 (dad):** he plays twice in one week without being asked (docs/mvp.md G1b).
- **#33 (strangers):** they start a game without help and understand what the
  app is for afterwards.
