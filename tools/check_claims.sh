#!/bin/bash
# Keep public copy at "exercises", never promised cognitive or medical outcomes.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

pattern='improve|boost|train your brain|sharpen|prevent|protect|delay|decline|dementia|alzheimer|memory loss|mejora|mejorar|potencia|entrena tu cerebro|previene|protege|retrasa|deterioro|demencia|pérdida de memoria'
files=(
    MenteViva/Localizable.xcstrings
    docs/store-listing.md
    docs/product-brief.md
    site/en
    site/es
    README.md
)

# Narrow exception (#552): about.why.p1 is the owner's personal story ("my dad was diagnosed
# with ..."), not a claim about the games. These two lines are exactly its EN and ES text.
# Never widen this for other strings. Each alternative is the whole catalog line, so any added
# word stops matching and the line is checked like any other.
story='^MenteViva/Localizable\.xcstrings:[0-9]+: +"value" : "(I made MenteViva mainly for my dad\. He was diagnosed with the early stages of dementia, and since then I have looked for activities he enjoys that keep his mind active\.|Hice MenteViva, sobre todo, para mi papá\. A él le diagnosticaron los inicios de una demencia, y desde entonces busco actividades que disfrute y que mantengan su mente activa\.)",?$'
hits="$(grep -RniE "$pattern" "${files[@]}" | grep -vE "$story")"
status=$?
if [ "$status" -eq 0 ]; then
    printf '%s\n' "$hits"
    echo "User-facing copy contains a prohibited claim." >&2
    exit 1
fi
if [ "$status" -ne 1 ]; then
    echo "Could not check user-facing copy." >&2
    exit "$status"
fi

echo "User-facing copy contains no prohibited claims."
