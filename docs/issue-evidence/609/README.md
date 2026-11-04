# Evidence for #609: Sliding Blocks buttons at the largest text

iPhone SE (3rd generation) simulator, iOS 27.0, local-only Debug build, light, no physical device.

- `01-se-ax5-en-before.png`: before, from #586 evidence (build cfa269f): labels break letter by letter.
- `02-se-ax5-en-after.png`, `03-se-ax5-es-after.png`: after, AX5, EN and ES: buttons stacked, full width, whole words.
- `04-se-default-en-unchanged.png`: after, default text (large): the row as before.

Seeded: a temporary launch fixture (not committed) mounted `SlidingBlocksView` directly with the scroll anchored to the bottom;
launch arguments `-appLanguage`, `-hasSeenOnboarding YES`, `-guide.seen.sliding_blocks YES`. The deal is random. No scroll or tap was performed.
Number Slide already stacks its controls at accessibility sizes, so it needed no change.
