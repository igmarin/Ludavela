# Ludavela — preliminary name screen and release handoff (#565)

The owner selected **Ludavela**, spelled the same in EN and ES, on 2026-11-02,
subject to checking the candidate. The public brand replaces MenteViva. This is
a record of a limited search, not a legal opinion, registration or reservation.

## Searches observed on 2026-11-02

These results were read in the registries' browser interfaces, not inferred from
search-engine snippets. No class restriction was applied to these queries.

| Source | Query and filters | Observed result | Limit |
|---|---|---|---|
| [USPTO Trademark Search](https://tmsearch.uspto.gov/) | Wordmark: `Ludavela`; live and dead checked | `No results found` | This query does not establish absence of confusingly similar marks or common-law use. |
| [IMPI MARCia](https://marcia.impi.gob.mx/marcas/search/quick) | Advanced options: `Exacta`, name `LUDAVELA` | `No hay resultados. Considera realizar una nueva búsqueda con otros criterios.` | The initial `Similar Plus` query returned 346 approximate results; their individual records were not reviewed. Exact absence is not a similarity clearance. |
| [EUIPO eSearch](https://euipo.europa.eu/eSearch/#basic/1+1+1+1/100+100+100+100/Ludavela) | Basic search: `Ludavela` | `Trade marks (0)` and no results | Covers this EUIPO query, not every EU national register or all similar names. |
| Public web search | `"Ludavela"`, `"Luda Vela" game app trademark`, exact name with app-store/game-store domains | No directly matching app or game surfaced in this pass; unrelated textual occurrences appeared | An indexed-web search does not prove store availability, first use or ownership. |

**Assessment:** no direct exact-name conflict surfaced in these checks, so the
owner's candidate can be prepared for review. Commercial availability worldwide
has not been established. In particular, the approximate IMPI results, similar
spellings/sounds, relevant launch territories, and App Store Connect name
availability remain unverified. No conclusion that a new name is “without issues”
is asserted. [USPTO clearance guidance](https://www.uspto.gov/trademarks/search/comprehensive-clearance-search-similar-trademarks)
includes similar marks, related goods/services and common-law use.

## What the rename reaches

- Home-screen display name and localized app copy, including About, sharing and
  the personal story: Ludavela in both languages.
- Current public website, privacy/support copy, README and store-listing draft.
- The claims checker retains its exact personal-story exception with the new name.

The bundle ID remains `com.igmarin.MenteViva`, the project/scheme remain
`MenteViva`, and the source folders, stored keys, model identities and hosted URLs
keep their existing identifiers. This is a display-brand change; it requires no
data migration or new app record. Dated release/decision history retains the old
name. [Apple's app-information reference](https://developer.apple.com/help/app-store-connect/reference/app-information/app-information)
distinguishes the editable name from the bundle identifier, which cannot change
after a build has been uploaded.

## Owner's App Store Connect steps

1. Open the existing app record, then App Information. Set the name to `Ludavela`
   in the English and Spanish localizations. Saving there checks Apple's name
   availability; this search has not reserved it.
2. Use the updated text in `docs/store-listing.md`. The support/privacy URL host
   may still say `menteviva-e4s.pages.dev`; keep the working URLs until a separate
   hosting change provides verified replacements. Deploy the updated `site/`
   content and confirm the policy/support pages are publicly reachable.
3. Use the next unused build number and upload a new build from this change to
   the same app record. Verify the
   Home-screen name, Home, About and a shared summary in EN and ES.
4. Capture/upload final store screenshots after the name and artwork are settled.
   Finish the remaining privacy, availability and submission checks in #194.

This rename does not resolve #194's separate game-name findings or the usage-rights
basis of the eight Muse-generated pictures. It does not claim trademark ownership
or alter the recorded provenance of existing artwork.
