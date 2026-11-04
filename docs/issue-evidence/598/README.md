# Game instructions in espresso (#598)

The instruction line of ten games is espresso semibold (`.title2.weight(.semibold)` with `Color.espresso`), the same pair Memory Lane uses (#582). Rules, layouts, sizes and colours of anything else are unchanged.

## Changed

| File | Change |
|---|---|
| `ColorClashView.swift` | `game.colorclash.instruction` |
| `MathStreakView.swift` (Number Trail) | `game.math.instruction` |
| `PegSolitaireView.swift` | `instruction` (`game.peg.instruction`) |
| `QuickEyesView.swift` | `game.quickeyes.instruction` / `.paced` (shown while not at accessibility text sizes) |
| `NumberSlideView.swift` | `instruction` (`game.numberslide.instruction`) |
| `RepeatSequenceView.swift` | `game.sequence.instruction` (the title3 status line below it is not changed) |
| `SayingsView.swift` (Finish the Saying) | `game.sayings.instruction` in `instructionRow` |
| `CategoryFluencyView.swift` | `game.category.instruction` |
| `TangramView.swift` | `instruction` (`game.tangram.instruction`) |
| `RiddleView.swift` (Riddles) | `game.riddles.instruction` in `instructionRow` |

No `.secondary` text was found in these files. `ReminiscenceView` already uses `Color.inkSoft` for its question line.

## Skipped (and why)

- **Quick Eyes prompt** (`game.quickeyes.prompt`, `.title2`): a question at the choice step, not the instruction key. Left as is; the owner can say if it should match.
- **Quick Eyes invite buttons, "almost" note:** buttons and feedback, not the instruction.
- **Finish the Saying endings and Next button:** answers and buttons.
- **Repeat the Sequence status line** (`instruction` computed property, `.title3.weight(.semibold)`): the watch / your turn / miss status, title3, not title2.
- **Riddles riddle text** (serif, title2 semibold): deliberate style.
- **Riddles clue** (`.title2.italic()`, tint): deliberate style.
- **Riddles solved line** (`.title2.weight(.semibold)`, tint) and answer names: answers, not the instruction. Next button: button.
- **Tangram hint line** (`hintLine`, `.title2`): a hint shown after a miss, not the instruction.
- **Tangram control labels:** buttons.
- **Tangram tile border** (`Color.secondary.opacity(0.4)`) and **QuietTileStyle border** (`Color.secondary.opacity(0.7)`): non-text strokes, not text colour.
- **Reminiscence caption** (`.largeTitle`): deliberate style.
- **Reminiscence prompt** (`.font(.title)`, default colour): not title2, not the instruction line.
- **Reminiscence placeholder icons** (`Image(systemName:)` with `.secondary`, lines for the object picture and the photo placeholder): images, not text.
- **Category Fluency category name** (`.largeTitle`): the answer, not the instruction.
- **Color Clash word and shape, Number Trail sum:** game stimulus, colour and size are part of the game.

## Not captured

Screenshots (one light, one dark) were not taken: the host load was about 320 during the session, and the simulator taps needed to reach a game were not reliable at that load. The change is text styling only and builds; a visual check is still open.
