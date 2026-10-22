#!/usr/bin/env bash
# Dump the API of every exposed QuickCheck module with GHCi :browse, and
# check that each exported name appears in the qik-chk API index.
#
# Usage:
#   browse-api.sh [OUTFILE]        # default OUTFILE: ./quickcheck-api.txt
#
# Environment:
#   GHC          compiler (default: ghc); ghci is run as "$GHC --interactive"
#   QIK_CHK_ENV  GHC package environment containing QuickCheck
#                (default: ~/.cache/qik-chk/env-ghc-<version>, as built by
#                qik-chk-workflow/scripts/run-examples.sh --setup)
#
# Exit status: 0 if every name is indexed, 1 if some are missing, 2 on setup
# errors. Missing names are printed one per line as "MISSING Module name".
set -u

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
refs="$here/../references"
ghc="${GHC:-ghc}"
out="${1:-quickcheck-api.txt}"

if ! command -v "$ghc" >/dev/null 2>&1; then
  echo "browse-api: '$ghc' not found" >&2; exit 2
fi
ver="$("$ghc" --numeric-version)"
envfile="${QIK_CHK_ENV:-$HOME/.cache/qik-chk/env-ghc-$ver}"
[ -f "$envfile" ] || { echo "browse-api: no package environment $envfile" >&2; exit 2; }

modules="Test.QuickCheck Test.QuickCheck.Arbitrary Test.QuickCheck.Gen
Test.QuickCheck.Gen.Unsafe Test.QuickCheck.Monadic Test.QuickCheck.Monoids
Test.QuickCheck.Modifiers Test.QuickCheck.Property Test.QuickCheck.Test
Test.QuickCheck.Text Test.QuickCheck.Poly Test.QuickCheck.State
Test.QuickCheck.Random Test.QuickCheck.Exception Test.QuickCheck.Features
Test.QuickCheck.Function Test.QuickCheck.All Test.QuickCheck.Compat"

: >"$out"
for m in $modules; do
  echo "=== $m" >>"$out"
  # :browse lists what the module exports; names come out qualified, so
  # strip package and module qualifiers.
  echo ":browse $m" | "$ghc" --interactive -package-env "$envfile" -v0 \
    -ignore-dot-ghci 2>/dev/null |
    sed -E -e 's/[A-Za-z0-9_-]+-[0-9][0-9.]*://g' \
      -e 's/([A-Z][A-Za-z0-9_]*\.)+([A-Za-z_(:!#$%&*+.\/<=>?@^|~-])/\2/g' >>"$out"
done
echo "browse-api: wrote $out ($(grep -c '' "$out") lines)"

# Names: the identifier or operator that starts each declaration line.
missing=0
current=""
while IFS= read -r line; do
  case "$line" in
    "=== "*) current="${line#=== }"; continue ;;
    " "*|""|"type role "*) continue ;;
  esac
  # Declarations (class, data, ...) may carry a context; signatures may not
  # be stripped at "=>" because operators such as (==>) contain it.
  name="$(printf '%s\n' "$line" | sed -E \
    -e '/^(type family|data family|type|data|newtype|class|pattern) /{
          s/^(type family|data family|type|data|newtype|class|pattern) +//
          s/^.*=> *//
        }' \
    -e 's/^\(([^)]*)\).*/(\1)/' \
    -e 's/^([A-Za-z_][A-Za-z0-9_'"'"']*).*/\1/')"
  [ -n "$name" ] || continue
  escaped="$(printf '%s' "$name" | sed 's/|/\\|/g')"   # tables escape "|"
  if ! grep -qF -e "\`$name\`" -e "\`$escaped\`" "$refs"/*.md; then
    echo "MISSING $current $name"; missing=$((missing + 1))
  fi
done <"$out"

echo "browse-api: $missing exported name(s) not found in the index"
[ "$missing" -eq 0 ]
