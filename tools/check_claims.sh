#!/bin/bash
# Keep public copy at "exercises", never promised cognitive or medical outcomes.
set -uo pipefail
cd "$(dirname "$0")/.." || exit 1

pattern='improve|boost|train your brain|sharpen|prevent|protect|delay|decline|dementia|alzheimer|memory loss|mejora|mejorar|potencia|entrena tu cerebro|previene|protege|retrasa|deterioro|demencia|pérdida de memoria'
files=(
    Ludavela/Localizable.xcstrings
    docs/store-listing.md
    docs/product-brief.md
    site/index.html
    site/en
    site/es
    README.md
)

# Narrow exception (#552): the owner's personal story ("my dad was diagnosed with ...") is not a
# claim about the games. It is allowed only as these two exact sentences, as a whole catalog value
# or a whole homepage paragraph; any added word stops matching and the line is checked like any
# other. Never widen this for other strings.
en='I made Ludavela mainly for my dad\. He was diagnosed with the early stages of dementia, and since then I have looked for activities he enjoys that keep his mind active\.'
es='Hice Ludavela, sobre todo, para mi papá\. A él le diagnosticaron los inicios de una demencia, y desde entonces busco actividades que disfrute y que mantengan su mente activa\.'
story="^(Ludavela/Localizable\.xcstrings:[0-9]+: +\"value\" : \"($en|$es)\",?|site/index\.html:[0-9]+:<p( lang=\"es\")?>($en|$es)</p>)$"
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
