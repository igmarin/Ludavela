# Docs — Ludavela

Where each doc lives and what question it answers. Product brief and conventions first.
If a doc grows past one screen of real content, split it.

| Doc | Question it answers | Status |
|---|---|---|
| [product-brief.md](product-brief.md) | What are we building, for whom, and why | Current |
| [conventions.md](conventions.md) | Rules every commit must follow | Current |
| [how-it-works.md](how-it-works.md) | How the app works: a day in it, the pieces, how games are chosen, how to add one | Current |
| [jev-integration.md](jev-integration.md) | History: the optional Jev integration, removed from the app 2026-10-26 | Historical |
| [decision-model-spike-2026-09-30.md](decision-model-spike-2026-09-30.md) | Nimble and Laya tested as Jev replacements, with numbers | Snapshot |
| [jev-revisit.md](jev-revisit.md) | Jev judgments 001–015: early decisions, audience, games, segments, progress, Card Table | Living, to 2026-10-13 |
| [jev-json/](jev-json/) | Raw Jev request/response archive (audit trail); 011 is the app's real daily request | Growing |
| [mvp.md](mvp.md) | MVP definition of done + phase gates | September plan; current release checklist is #194 |
| [playtest.md](playtest.md) | How to run a playtest and record it (#6, #33) | Living |
| [profiling.md](profiling.md) | Signposts + Instruments: how to time the hot paths | Living |
| [playtest-session-1.md](playtest-session-1.md) | Printable session sheet for dad's playtest (#6) — findings map to #44/#46/#47 | Done |
| [playtest-session-2.md](playtest-session-2.md) | Printable session sheet for playtest #2: the Card Table redesign and Jev 015's open questions | Current |
| [playtest-session-3.md](playtest-session-3.md) | Printable session sheet for playtest #3: Sudoku, Up or Down and Finish the Saying (#179–#181) | Current |
| [playtest-session-4.md](playtest-session-4.md) | Printable session sheet for playtest #4: a week alone on TestFlight — levels, onboarding and the four new games (#231) | TestFlight active (#229 closed); sheet available |
| [playtest-session-5.md](playtest-session-5.md) | Printable session sheet for playtest #5: the new look (#578) on devices and with players: device matrix, VoiceOver pass, three tasks (#586) | #586 closed by owner; [dated evidence and remaining limits](issue-evidence/586/README.md) |
| [playtest-outside.md](playtest-outside.md) | Kit for testers outside the family: invite (EN + ES), sheet per tester, findings template (#33) | Current |
| [install-runbook.md](install-runbook.md) | TestFlight for testers; free Apple ID installs for development (7-day expiry) | Current |
| [testflight-beta.md](testflight-beta.md) | How to archive, upload and invite TestFlight testers, with the beta review text (#229) | Current |
| [device-support.md](device-support.md) | What hardware/OS we claim and what we verified | Living |
| [decisions.md](decisions.md) | Every significant decision, with date and reason: an index of month files in [decisions/](decisions/), plus the entry template | Living log |
| [handoffs/](handoffs/) | Notes one agent session left for the next: what was done, what's open | Snapshots, newest by file name |
| [superpowers/](superpowers/) | Design specs (`specs/`) and step-by-step build plans (`plans/`) for bigger features: the reminiscence game and the three new games | Shipped |
| [design/](design/) | Card Table history and the [Sobremesa direction](design/2026-11-03-sobremesa.md) with its [interactive study](design/2026-11-03-sobremesa.html) | Owner choice recorded 2026-11-03; mockups are not validation |
| [design/art-style.md](design/art-style.md) | Approved retro illustration direction, palette, fixed prompt and picture checks | Batches [#325](https://github.com/igmarin/Ludavela/issues/325), [#326](https://github.com/igmarin/Ludavela/issues/326), [#327](https://github.com/igmarin/Ludavela/issues/327), [#328](https://github.com/igmarin/Ludavela/issues/328) closed; rights limits in [ip-clearance.md](ip-clearance.md) |
| [art-prompts.md](art-prompts.md) | Exact prompts and actual tool disclosures for selected art | Living |
| [research-2026-09.md](research-2026-09.md) | Evidence + market scan behind the decisions | Snapshot |
| [research-2026-09-22.md](research-2026-09-22.md) | Market and segment numbers (60+, caregivers, iOS floor) | Snapshot |
| [statistics-rationale.md](statistics-rationale.md) | What our numbers support, and what copy may say | Current |
| [why-these-games.md](why-these-games.md) | The "Why these games" copy, EN + ES, with a source per line (#210) | Owner-approved 2026-10-27 |
| [jev-sounds.md](jev-sounds.md) | Sound and haptics design choices | Current |
| [audit-2026-11-04.md](audit-2026-11-04.md) | Post-Sobremesa source audit: findings, baseline commit and verification limits | Dated snapshot; existing #610 reused |
| [a11y-audit-2026-09.md](a11y-audit-2026-09.md) | Accessibility audit vs conventions §4, with addendum | Snapshot + addendum |
| [es-review-packet.md](es-review-packet.md) | Spanish strings for the native-speaker review (#12) | Current |
| [question-audit.md](question-audit.md) | The real questions, checked (against wrong questions) | Living |
| [roadmap.md](roadmap.md) | What happens next, in order | Living |
| [languages.md](languages.md) | Which language next, and who validates it (#40) | Waiting on validators |
| [review-2026-10-gamefeel.md](review-2026-10-gamefeel.md) | Game feel and UX of the nine games, against the gamedev skills (#230) | Snapshot |
| [ip-clearance.md](ip-clearance.md) | Can we use this game, name or asset? The per-game checklist | Living |
| [name-screening-2026-11-02.md](name-screening-2026-11-02.md) | Ludavela name-search evidence, limits and release handoff | Dated review |
| [lawyer-brief.md](lawyer-brief.md) | Questions and facts prepared for an IP lawyer | Draft; no attorney review recorded (#194) |
| [store-listing.md](store-listing.md) | App Store copy + screenshots (EN/ES), drafted early | Draft |
| [privacy-policy.md](privacy-policy.md) | Privacy policy: what stays on the device (#34) | Live on Cloudflare Pages from `site/` (EN + ES); linked from Settings |
| [support.md](support.md) | Support page: 7-day expiry, language, progress (#34) | Live on Cloudflare Pages from `site/` (EN + ES); linked from Settings |
| [agent-setup.md](agent-setup.md) | Which coding agent reads which rules, MCP and skills, and what the owner sets up once | Living |

## Writing rules for these docs

1. One idea per sentence. No filler ("It's important to note that…").
2. Every claim that isn't our own decision gets a source URL.
3. Decisions say **who decided, when, and why** — so future-us can reverse them.
4. No boilerplate sections. A section with nothing to say gets deleted.
5. Spanish summaries land when the product copy stabilizes — YAGNI for now.
