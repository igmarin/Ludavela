# End-of-game screen (#583): proposal captures

iPhone 17 simulator (iOS 27), local-only debug build of this branch. **All five states are seeded, not played through the UI**: a temporary launch fixture (not committed) cached a three-game plan for today, inserted Memory Lane (and, for the end of the day, Sudoku and Up or Down) sessions, and showed `CelebrationView` directly. The card had already landed on the week when each was taken.

- `midday-en-light-first-of-day.jpg`: English, light. First game of the day (1 of 3): today's picture, message, filled "Next: Sudoku", quiet "Home".
- `done-en-light.jpg`: English, light. Third of three (the game closes the day): "That's today's table. Lovely!", filled "Home", quiet "Play again". No next game is offered.
- `level-offer-en-light.jpg`: English, light. A strong Memory Lane game with the level offer: outlined 64pt answers above the filled "Next".
- `done-es-dark.jpg`: Spanish, dark, end of the day.
- `midday-en-ax5.jpg`: English, light, maximum accessibility text, mid-day (no offer): the next action is in the first screen. The week-day labels truncate here; that is the existing WeekBoard issue recorded in #586. The offer at this size was seen only on its first screen; I did not scroll it.

Not checked: VoiceOver, a physical device, Reduce Motion on screen (code path only), a smaller phone, iPad.
