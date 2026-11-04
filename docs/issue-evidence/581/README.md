# Home visual checkpoint (#581)

Captured on the isolated 375 pt iPhone simulator with the #580 base and #581 Home change. The three-game plan is a new day, with Memory Lane next.

- `home-en-light-3-new.png`: English, light, default text. The next action and all three recommended cards are visible; the owner selected the cream background, flat jade table, cream title surfaces and retained fan; other mockup details are not blanket-approved.
- `home-ipad-en-light-3-new.png`: iPad Air 11-inch, English, light, default text, after the deal animation; the hand, week and catalogue are visible.
- `home-es-dark-ax5-3-new.png`: Spanish, dark, maximum accessibility text. The full action fits in the first viewport after omitting the decorative greeting at accessibility sizes. The page scrolls to the recommended cards.

The iPhone 17e captures `home-en-light-2-new.png`, `home-en-light-5-new-scrolled.png`, and `home-en-light-empty-scrolled.png` use disposable local plan fixtures with no sessions; the latter two are scrolled. They use the build immediately before the accessibility-only greeting change, which does not affect standard text. The empty fixture shows the week and catalogue; it does not establish the case where all games are unavailable.

## Additional simulator fixtures

- `home-en-partial.png` and `home-en-done.png`: isolated iPhone 17e, English/light, a temporary fixture build from `ac9ef41`. A cached three-game plan and today's SwiftData sessions were seeded: one session for partial, one per planned game for done. These depict simulated state, not games played through the UI. The fixture source is not in the app.
- `home-en-all-unavailable.png`: isolated iPhone SE (3rd generation), English/dark, maximum accessibility text, with all 19 GameID values supplied through the temporary `-games.hidden` launch argument. The corrected screen directs the player to Settings and omits the empty catalogue. `home-en-all-unavailable-before.png` records the previous state: six weekday labels truncate to ellipses in the unchanged WeekBoard, recorded in [#586](https://github.com/igmarin/Ludavela/issues/586#issuecomment-6618922624).
- `home-ipad-en-ax5.png`: iPad Air 11-inch (M4) simulator, English/light and maximum accessibility text, three-game new day. This is the initial viewport, not a full scrolling check.

A native UI test on an iPhone 17 simulator (iOS 27) tapped the next recommended card and verified its named game, returned, tapped the primary Play action and reached the same game, then opened My Week and Settings. This was run on the earlier `6096f14` build, before the all-hidden message change. Physical VoiceOver and full large-text scrolling remain unverified. These captures do not certify acceptance.
