# Peg Solitaire target proposal (#615)

Status: **proposal for owner decision; no implementation or approval yet.** This
includes a temporary simulator fixture and a browser prototype, not a usability
test. Independent hit testing remains open, as detailed below; no production code has changed.

## Current geometry

At baseline `a3868d7`, `PegSolitaireView` wraps the entire screen in default
`.padding()` (normally 16pt each side), constrains the square board to 420pt,
and sets each button and rectangular hit shape to `min(60, boardWidth / 7)`.
The table assumes the board receives the full padded viewport width. Safe-area
insets, parent proposals, screen orientation, and SwiftUI layout must be measured
on devices; no runtime measurement is implied here. Dynamic Type does not enter
the cell formula, but the vertical `fitOrScroll` path and actual proposed width
must be verified at both text sizes.

| Viewport width | Assumed board width | Current hit square | Proposed hit square | Board hidden horizontally after change |
| --- | ---: | ---: | ---: | ---: |
| 320pt | 288pt | 41.14pt | 60pt | 132pt total |
| 375pt | 343pt | 49pt | 60pt | 77pt total |
| iPad window ≥452pt | 420pt cap | 60pt | 60pt | 0pt |

The same calculated figures apply at normal text and AX5 **only if** the width
proposal is unchanged. These are upper bounds for phones given the assumptions,
not actual measurements. Narrow iPad multitasking windows follow the same width
rule; the physical device name alone does not determine the result. Targets are
nonoverlapping cell rectangles; circles are smaller visual marks. Expanding
invisible hit regions over adjacent cells cannot give each cell 60pt without
ambiguous overlaps. Seven 60pt cells require 420pt; seven 100pt cells require
700pt. The proposal meets the strict 60pt floor, but not the stated 100pt
game-control goal. That conflict remains for the owner and real-player testing.

[Open the interactive browser comparison](prototype.html). It illustrates the tradeoff and
measures its own CSS rectangles; it is not an iOS or VoiceOver measurement.

## Simulator fixture evidence

A temporary copy of baseline `a3868d7` launched `PegSolitaireView` directly,
removed the first-play overlay, and displayed a `GeometryReader` width plus the
cell value passed to its existing `hole` view. The proposal wraps the same board
in a 420pt horizontal viewport and passes 60pt cells. It does not yet include the
proposed scroll cue, and each launch deals randomly, so board contents differ.
The [fixture patch](fixture.patch) records the temporary changes (`git apply
--unidiff-zero` against the baseline in a disposable copy); it was built for
the simulator and is not a production change. The
320pt case constrains the view to 320pt on an iPhone SE (3rd generation)
simulator; 375pt uses that simulator's full width. The iPad Air 11-inch (M4)
fixture uses an 820pt container. Spanish, light appearance. GeometryReader
measures the board viewport; the shown cell size is the value used to size each
button's content shape, not an independently measured accessibility hit frame.

| Fixture | Viewport / cell shown | Evidence |
| --- | --- | --- |
| 320pt, normal, current | 288 / 41.14pt | [Screenshot](320-normal-current.png) |
| 320pt, AX5, proposed | 288 / 60pt | [Screenshot](320-ax5-proposal.png) |
| 320pt, AX5, current | 288 / 41.14pt | [Screenshot](320-ax5-current.png) |
| 320pt, normal, proposed | 288 / 60pt | [Screenshot](320-normal-proposal.png) |
| 375pt, normal, current | 343 / 49pt | [Screenshot](375-normal-current.png) |
| 375pt, normal, proposed | 343 / 60pt | [Screenshot](375-normal-proposal.png) |
| 375pt, AX5, current | 343 / 49pt | [Screenshot](375-ax5-current.png) |
| 375pt, AX5, proposed | 343 / 60pt | [Screenshot](375-ax5-proposal.png) |
| iPad, normal, current | 420 / 60pt | [Screenshot](ipad-normal-current.png) |
| iPad, normal, proposed | 420 / 60pt | [Screenshot](ipad-normal-proposal.png) |
| iPad, AX5, current | 420 / 60pt | [Screenshot](ipad-ax5-current.png) |
| iPad, AX5, proposed | 420 / 60pt | [Screenshot](ipad-ax5-proposal.png) |

Retries with longer startup waits produced the phone captures shown above.
At AX5 the first viewport shows only part of the board vertically; vertical
scrolling is needed. No VoiceOver, gesture, independent hit-testing, or
real-device session was performed.

## Candidate for decision

Keep the existing 7×7 cross, hole positions, cell labels, selection, directions,
controls, rules and deal. On a window whose padded width is below 420pt, render a
420pt board with 60pt cells in a horizontally scrollable viewport. At 420pt or
more, show the full board as today. Add a persistent, localized EN/ES cue and
visible edge indication that more board is available; neither color alone nor a
vanishing system indicator should be the only clue. The exact cue and edge
appearance need design and localization review. Let vertical scrolling continue
at large text and test diagonal gesture arbitration. Do not make this change
without the owner's decision.

Schematic (viewport boundaries `|`; ellipsis indicates the portion outside the
viewport, not missing holes):

```text
Current 320pt:  |      7 columns at ~41pt each       |
Proposed 320pt: |     4.8 columns at 60pt     | ... →
Whole board:    [      7 columns at 60pt = 420pt      ]
```

The candidate preserves a spatial board and makes no overlapping touch targets,
but part of the cross is off-screen and a player may need to pan between source
and landing. Discoverability, orientation, selection persistence while panning,
and the competing vertical scroll are material risks, not solved by geometry.
An alternative large directional selection interface could avoid sideways
panning but adds an unvalidated interaction and may obscure spatial context; a
700pt board meets the 100pt goal but leaves even less visible. Changing the
cross to a smaller puzzle changes the game and is out of scope.

VoiceOver already identifies each hole by row and column, announces occupancy,
and provides legal directional actions. Preserve the 33 cells in row-major order
and their existing custom actions; verify focus automatically reveals off-screen
cells, labels and actions remain correct, selection persists, and a complete
move works using swipes and custom actions. A visible cue must have an accessible
label without adding confusing duplicate stops. Test actual VoiceOver on-device;
none of these behaviors is established by this proposal.

## Advisory judgment and remaining evidence

[Jev request](../../jev-json/024-peg-targets.request.json) and
[response](../../jev-json/024-peg-targets.response.json) selected the scroll-board
prototype (confidence 1.0). Jev's judgment is advisory, not a user test or the
owner's approval. No decision entry has been made because no owner decision has
been received.

Before implementation acceptance, independently measure button hit frames at 320pt and 375pt, both normal and AX5,
and a named iPad window at both sizes; capture before/after evidence. Verify every cell is at least 60pt,
scrolling and instructions are discoverable in EN and ES, source/landing moves
remain comprehensible, vertical and horizontal gestures work together, and
VoiceOver traverses and operates the entire board. Exercise narrow multitasking
and rotation without resetting a deal. Validate with a real player and revisit
the 100pt goal. #610 celebration verification is separate.

## Owner decision and implementation (2026-11-04)

The owner chose neither the scroll board nor hiding the game: **the board grows to within 4pt of the
screen edge on a phone, and Peg Solitaire is the one logged exception to the 60pt floor**
([decisions 2026-11-04](../../decisions/2026-11.md)). Reason: the player needs the whole cross in view
to plan a jump, and sideways panning competes with the vertical scroll at large text.

Measured from simulator screenshots (hole centre to centre), Spanish, light, temporary fixture not committed:

| Device | Before | After | Evidence |
| --- | ---: | ---: | --- |
| iPhone SE 3rd gen, 375pt, default text | 49pt | 52.5pt | [375-normal-wider.png](375-normal-wider.png) |
| iPhone SE 3rd gen, 375pt, AX5 | 49pt | 52.5pt (page scrolls vertically, as before) | [375-ax5-wider.png](375-ax5-wider.png) |
| iPad Air 11-inch (M4) | 60pt | 60pt (unchanged, 420pt cap) | [ipad-normal-wider.png](ipad-normal-wider.png) |

Each hole's tap area is its full square cell. No iPhone on iOS 17 or later is narrower than 375pt;
320pt applies only to narrow iPad multitasking windows, where holes are about 44pt. VoiceOver labels,
values and jump actions are unchanged; not re-tested on a device.
