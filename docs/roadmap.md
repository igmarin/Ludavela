# Roadmap

Ordered. Finish one before starting the next. Dates are added when work
starts, not before — no fantasy deadlines.

## Now — v1.0 App Store (status checked 2026-11-04)

The Apple Developer Program is paid ([#224](https://github.com/igmarin/Ludavela/issues/224), closed;
[decision, 2026-10-27](decisions/2026-10.md)). TestFlight is running
([#229](https://github.com/igmarin/Ludavela/issues/229), closed); tester builds last 90 days.
The local-only app still decides daily picks and levels on the device.

- **App Store submission remains open:** [#194](https://github.com/igmarin/Ludavela/issues/194)
  tracks current release requirements and unresolved screening/account-side work. Closed tasks are
  not proof of legal clearance or submission.
- **Post-Sobremesa follow-up:** the [2026-11-04 source audit](audit-2026-11-04.md) records its baseline,
  findings and limits. Preserve the [owner-selected cream, flat jade and card fan](design/2026-11-03-sobremesa.md).
  [#586's dated report](issue-evidence/586/README.md) separates old captures, later fixes and owner testing.
- **Earlier audit:** [#423](https://github.com/igmarin/Ludavela/issues/423) is closed as completed.
- **Contest:** [#422](https://github.com/igmarin/Ludavela/issues/422) was closed as not planned on
  2026-10-31. Its Nov 4 deadline is historical, not an active submission commitment.

## Before — v0.2.0 Polish + Speed (G1b, G2)

Shipped and off this list: app icon and launch screen, home screen (#27), sound
and haptics (#26), first-run onboarding (#31), Memory Lane warmth (#43),
progress instead of points (#45).

1. **Dad playtest #1 (#6)** — ran; findings on #6, decisions in `decisions.md` 2026-10-01
   (Jev 012). Color Clash / Number Trail retired from dad's library (#47, closed).
2. **Built from the playtest, in order (one PR each):** finished games always saved (#106),
   weekly progression for dad and the family (#107), Family settings — manual difficulty and
   hide games (#108), adult Memory Lane (#109), Memory Lane with his own photos (#110).
3. **Watch the daily picks** — decided on the device by `DailyPolicy` (#101). Re-tune the
   game weights once the family screen shows a few weeks.
4. **Done 2026-09-30:** VoiceOver and 100pt-target check on the iPad (#64),
   History/day-grouping tests and plumbing dedupe (#65, #57).

Quick Eyes became player-paced (#46, closed).

**Three new games (decided 2026-10-19), shipped one PR each:** Sudoku (#179), Up or Down
(#180), Finish the Saying (#181). Left: a native ES review of the refranes, and a week with dad.
Spec: `superpowers/specs/2026-10-19-three-new-games-design.md`.

Exit criteria: dad picks it up unprompted, twice in one week (docs/mvp.md G1b).

## Validation follow-up

- Portrait/landscape check. Progress stays pressure-free: no streaks or leaderboards
  ([decision, 2026-10-03](decisions/2026-10.md)).
- Spanish review [#12](https://github.com/igmarin/Ludavela/issues/12) is closed. [#194](https://github.com/igmarin/Ludavela/issues/194)
  records owner acceptance of Spanish after the 2026-11-02 TestFlight round, with no full packet read.
- Structured player tasks and physical VoiceOver remain unverified in [#586](issue-evidence/586/README.md).
  The [device accessibility checklist](a11y-audit-2026-09.md) remains available.

## Distribution — current paths

- Testers use [TestFlight](testflight-beta.md); development installs through a free Apple ID still
  expire after 7 days. See the [install runbook](install-runbook.md).
- App Store work is tracked in [#194](https://github.com/igmarin/Ludavela/issues/194). v1.0 is free;
  this roadmap does not schedule StoreKit purchases or paid services.
- CloudKit and real family sharing are not the current local-only build. They require a separately
  provisioned mode and are not promised here.

## Historical distribution plan — superseded

The 2026-09-19 polish-before-distribution gate and September's free/paid tiers described the period
before enrollment. The [2026-10-27 decision](decisions/2026-10.md) superseded the payment blocker;
[#224](https://github.com/igmarin/Ludavela/issues/224) and
[#229](https://github.com/igmarin/Ludavela/issues/229) are closed. The old plan's non-expiring beta
and StoreKit assumptions are not current guidance.

## Historical public release checklist — use #194 for current status

- [ ] Medical-claims review: copy stays "games for an active mind",
      never "prevents/treats dementia" (research §1, App Store 1.4.1).
- [ ] Privacy policy page (drafted, #34; the app makes no network calls).
- [ ] Age rating + positioning decision.
- [x] Business model: v1.0 is free; support links live outside the app (decisions.md 2026-10-27, #228).
- [ ] ES/EN native review sign-off.
- [ ] App Store screenshots + description in both languages.

## Superseded

- **Jev in the app (2026-10-26, #195):** the Jev proxy on Cloudflare (#63) and redeploying the Jev
  worker for new games are gone; `DailyPolicy` decides on the device and `proxy/` is deleted.
  History: `jev-integration.md`.

## Historical parking lot (not current commitments)

- ~~New user segments~~ — resolved 2026-09-22 (Jev 009): 60+ leads, mental-health
  and wellness users are spillover of the same product; no forks, copy ceiling holds.
- Android, watchOS, clinician dashboard, more games (blocked by #18 gate; reminiscence #44 is the first candidate).

