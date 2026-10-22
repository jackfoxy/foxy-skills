#!/usr/bin/env bash
# Compile and run the qik-chk-* executable examples against a pinned QuickCheck.
#
# Usage:
#   run-examples.sh --setup            # build the package environment once
#   run-examples.sh                    # run every qik-chk-*/examples/*.hs
#   run-examples.sh qik-chk-shrinking  # run one skill's examples
#   run-examples.sh path/to/Example.hs # run one file
#
# Environment:
#   GHC              compiler to use (default: ghc)
#   CABAL            cabal-install to use for --setup (default: cabal)
#   QIK_CHK_ENV      GHC package environment file
#                    (default: ~/.cache/qik-chk/env-ghc-<version>)
#   QIK_CHK_TIMEOUT  seconds allowed per example run (default: 120)
#
# Every example imports QikChkHarness and declares, for each property it runs,
# whether it should pass, fail, or give up. A deliberately failing teaching
# example therefore exits 0; only a result that differs from its declared
# expectation (or a compile error or timeout) counts as a regression.
set -u

here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
root="$(cd "$here/../.." && pwd)"
ghc="${GHC:-ghc}"
cabal="${CABAL:-cabal}"
limit="${QIK_CHK_TIMEOUT:-120}"
qc_version="2.19.0.0"

if ! command -v "$ghc" >/dev/null 2>&1; then
  echo "run-examples: '$ghc' not found; install GHC (see qik-chk-workflow)" >&2
  exit 2
fi
ghc_version="$("$ghc" --numeric-version)"
envfile="${QIK_CHK_ENV:-$HOME/.cache/qik-chk/env-ghc-$ghc_version}"

if [ "${1:-}" = "--setup" ]; then
  mkdir -p "$(dirname "$envfile")"
  "$cabal" install --lib --package-env "$envfile" \
    --constraint="QuickCheck==$qc_version" \
    "QuickCheck-$qc_version" containers deepseq tasty tasty-quickcheck
  exit $?
fi

if [ ! -f "$envfile" ]; then
  echo "run-examples: package environment $envfile missing; run with --setup" >&2
  exit 2
fi

files=()
if [ "$#" -eq 0 ]; then
  for f in "$root"/qik-chk-*/examples/*.hs; do files+=("$f"); done
else
  for arg in "$@"; do
    if [ -d "$root/$arg/examples" ]; then
      for f in "$root/$arg"/examples/*.hs; do files+=("$f"); done
    elif [ -f "$arg" ]; then
      files+=("$(cd "$(dirname "$arg")" && pwd)/$(basename "$arg")")
    elif [ -f "$root/$arg" ]; then
      files+=("$root/$arg")
    else
      echo "run-examples: no such skill or file: $arg" >&2
      exit 2
    fi
  done
fi

work="$(mktemp -d "${TMPDIR:-/tmp}/qik-chk-examples.XXXXXX")"
trap 'rm -rf "$work"' EXIT

echo "ghc $ghc_version; QuickCheck $qc_version; env $envfile"
pass=0; bad=0; report=()
for f in "${files[@]}"; do
  rel="${f#"$root"/}"
  name="$(basename "$f" .hs)"
  out="$work/$name.out"
  bin="$work/bin-$name"
  if ! "$ghc" -package-env "$envfile" -i"$here" -outputdir "$work/obj-$name" \
       -O0 -v0 -o "$bin" "$f" >"$out" 2>&1; then
    report+=("COMPILE-ERROR $rel"); bad=$((bad + 1))
    sed 's/^/    /' "$out"; continue
  fi
  timeout "$limit" "$bin" >"$out" 2>&1
  code=$?
  if [ "$code" -eq 0 ] && grep -q '^QIK-CHK-EXAMPLE OK' "$out"; then
    report+=("ok            $rel  ($(grep '^QIK-CHK-EXAMPLE OK' "$out" | sed 's/.*OK: //'))")
    pass=$((pass + 1))
  elif [ "$code" -eq 124 ]; then
    report+=("TIMEOUT       $rel"); bad=$((bad + 1))
  else
    report+=("MISMATCH      $rel"); bad=$((bad + 1))
    grep -E '^(=== |!!! )' "$out" | sed 's/^/    /'
  fi
done

printf '%s\n' "${report[@]}"
echo "examples: $pass as expected, $bad problem(s)"
[ "$bad" -eq 0 ]
