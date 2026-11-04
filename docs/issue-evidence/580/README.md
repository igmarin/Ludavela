# Game-card proposal (#580)

The owner selected the current cream, flat jade table, titles on cream and the existing fan on
2026-11-03. This implements the card and table tokens; #581 implements the Home layout.
Base: `d53c28f042ef8c0ae1563619eaa32a1af036139c`.

## Change

One outer espresso frame; the game ink stays as a 12% picture wash. Names use
espresso on paper; grid/row titles grow vertically rather than truncate. Compact hand cards retain
their existing 164pt height, two-line limit and 0.7 minimum text scale so the
existing fan and completion pile keep their geometry. Picture
sizes are 112pt grid / 80pt full-width hand. GameRow's emblem is 60pt. The existing
played check, accessible name/value and Reduce Motion behavior are unchanged.
The production cream remains `#FFF1D0`. `Color.tableSurface` is a separate flat
surface for #581; the celebration gradient is unchanged.

## Evidence

The PNGs are actual SwiftUI `ImageRenderer` output on the isolated iPhone 17e
simulator `B2BF8620-F5CB-4DDE-8AD9-B49FE2F8E298`, iOS 27.0, at 2× scale.
They are component renders, not full-screen screenshots or a device playtest.
`renderer.swift.txt` preserves the temporary renderer appended to ContrastTests;
it is not included in the test target or shipping app.

- `cards-{en,es}-{light,dark}.png`: grid 150pt, hand 112pt, row 300pt, standard text.
- `cards-{en,es}-{light,dark}-ax5.png`: grid and row 343pt, accessibility5 text,
  app locale explicitly set, matching a 375pt screen minus 16pt page margins.
- `*-ax5-300pt.png`: earlier stress render at 300pt with system locale. Spanish
  “deslizantes” leaves the final s on its own line at this artificial width;
  preserved as a limitation found, not a passing screenshot. At the actual
  343pt page width with the ES locale, both long titles fit without splitting words.
- `hand-before-fit-fix.png`: the exploratory natural-height hand split the last
  s of “deslizantes”. The final implementation retains the hand’s old fit rules
  to prevent that regression; the normal sheets show the corrected result.

## Validation and limits

- Generic iOS Simulator build passed.
- Full suite with temporary renderer: 874 tests, 0 failures. The first attempt
  was cancelled by a build database lock; the sequential retry passed.
- Existing ContrastTests checks espresso on paper in both modes; no text is
  placed directly on the new table surface. No new text pairing needs a mirror test.
- Lint, claims, signposts and project-file checks passed before evidence capture.
- Interaction behavior, VoiceOver navigation and actual device comfort still
  require integrated verification. These renders prove neither touch navigation
  nor user preference. #581 owns the real Home layout and its integration checks.
- Celebration also uses GameCard at 190pt as a floating overlay that reserves no
  space. `celebration-card-before-ax5.png` renders Spanish Sliding Blocks at
  accessibility5: the card reports 413pt high and its title is clipped at the
  bottom. `celebration-card-after-ax5.png` applies the celebration-only text-size
  cap and reports 204pt high. The separately supplied VoiceOver label remains
  the full game name and stamp; catalogue titles retain Dynamic Type. These are
  component renders, not a full celebration or VoiceOver test. The temporary
  fixture is in `celebration-renderer.swift.txt`; add the cap shown in the
  celebration view to reproduce the after image.

No game mechanics, daily plan, saved data, new strings, third-party assets or
app network calls were changed.
