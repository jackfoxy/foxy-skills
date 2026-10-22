# Source and version manifest

Companion to [qik-chk-overview](../SKILL.md). Everything in the qik-chk
pack is grounded in the sources below. Access date for all network
sources: **2026-10-20**. Research copies were kept in a scratch area
outside the skill library and are not part of the pack.

## Pinned upstream

| Item | Value |
|---|---|
| Repository | `https://github.com/nick8325/quickcheck` (cloned with full history) |
| Commit | `3d8fe8686024760006ca1ca656cbdd82cd71f11e` ("Bump version to 2.19.0.0 ...", #487, 2026-09-16) |
| Tag | `2.19`; `master` pointed at the same commit at access |
| Package version | `QuickCheck` 2.19.0.0 (`QuickCheck.cabal`) |
| Cabal `Tested-with` | `GHC >= 8.10 && < 9.15, hugs` |
| Known inconsistency | `source-repository this` in the cabal file names tag `2.18` |
| History | 1218 commits, first 2006-11-14; tags `2.4.1` to `2.19` |
| License | BSD-3-Clause (`License: BSD3`, `LICENSE`: Koen Claessen, Björn Bringert, Nick Smallbone); no upstream code is copied into the pack beyond short identifiers, signatures, and quoted messages |
| Permalink form | `https://github.com/nick8325/quickcheck/blob/3d8fe8686024760006ca1ca656cbdd82cd71f11e/<path>#L<line>` |

## Toolchain used for execution

| Tool | Version | Notes |
|---|---|---|
| OS | Linux Mint 21, Linux 6.8.0 x86_64 | |
| ghcup | 0.2.6.2 | binary verified against `https://downloads.haskell.org/~ghcup/0.2.6.2/SHA256SUMS`; installed under `~/.ghcup`, no shell rc changes |
| GHC | 9.10.3 | |
| cabal-install | 3.16.1.0 | |
| libgmp | system `libgmp.so.10`; no `-dev` symlink, so `LIBRARY_PATH` pointed at a directory with `libgmp.so -> libgmp.so.10` |

Dependency versions chosen by cabal:

| Build | Packages |
|---|---|
| Upstream `cabal build all --enable-tests` | random 1.3.1, splitmix 0.1.3.2, containers 0.7, deepseq 1.5.0.0, template-haskell 2.22.0.0, transformers 0.6.1.1, base 4.20.2.0 (plus `hint`, `split`, `process` for the instances suite) |
| Pack examples environment (`run-examples.sh --setup`) | QuickCheck 2.19.0.0, containers 0.8.1, deepseq, tasty 1.5.4, tasty-quickcheck 0.11.1 |
| Separate hspec environment (manual example) | QuickCheck 2.19.0.0, hspec 2.11.18 (hspec-core 2.11.18) |

## Sources

### Upstream repository (read)

| Path | Use |
|---|---|
| `src/Test/QuickCheck.hs` and the 17 modules under `src/Test/QuickCheck/` (18 files, 7614 lines) | API, semantics, line references |
| `QuickCheck.cabal` | flags, exposed modules, test suites, `Tested-with` |
| `changelog.md` | release history 2.5 to 2.19 |
| `README` | companion packages |
| `examples/` (7 files) | compiled and run (see validation report) |
| `tests/` (16 files) | 13 cabal suites run; `ShrinkMap.hs`, `TestRandom.hs` run separately; `Weird.hs` read only |
| `.github/workflows/` (3 files), `make-hugs`, `test-hugs`, `test-mhs` | CI and portability |
| git log, tags, remote branch names | history; branches not examined |

### Chalmers QuickCheck page (`https://www.cse.chalmers.se/~rjmh/QuickCheck/`)

| URL (relative to the page) | Status | SHA-256 of copy (first 16 hex) |
|---|---|---|
| `index.html` (the page itself) | read | `44cc3788aaaa0c87` |
| `manual.html` + frames `manual_title.html`, `manual_contents.html`, `manual_body.html` | read | `5ed10617a8ccb0f5` (frameset) |
| `QuickCheck.hs` (QuickCheck 1) | read | `5ebd2399568b7ec6` |
| `QuickCheckM.hs` | read | `95630b7fde9f7238` |
| `ShowFunctions.hs` | read | `cedb53dc0305277a` |
| `randoms.html` | read | `94bcee9f70a9a916` |
| `../Papers/QuickCheckST.ps` (Haskell Workshop 2002 paper) | read (converted to text) | `0b131add4f14fb34` |
| `quickcheck` (script to run all properties) | **inaccessible**: HTTP 404 | - |
| `http://www.md.chalmers.se/~koen/Papers/quick.ps` (ICFP 2000 paper) | **inaccessible**: host did not resolve | - |
| `http://www.ellium.com/~thor/icfp2001/k5-icfp.html` (Moertel's story) | **inaccessible**: domain parked | - |
| `http://quviq.com` | not followed (commercial product page) | - |

### Papers obtained elsewhere

| Work | URL | Status | SHA-256 (first 16) |
|---|---|---|---|
| Claessen, Hughes, ICFP 2000 | `https://www.cs.tufts.edu/~nr/cs257/archive/john-hughes/quick.pdf` | read (mirror of the paper) | `bfddcaa648f836e5` |
| Hughes, *How to Specify It!* (LNCS 12053) | `https://research.chalmers.se/publication/517894/file/517894_Fulltext.pdf` | read | `c339028bfa1c4c4c` |
| Claessen, *Shrinking and showing functions* (Haskell Symposium 2012) | ACM Digital Library | **inaccessible**: HTTP 403 | - |

### Package archives and tools

| Source | Use |
|---|---|
| Hackage index via `cabal update` | dependency resolution for all builds |
| `https://downloads.haskell.org/~ghcup/0.2.6.2/` | ghcup binary and checksums |

## Separation of sources

The pack labels every claim's provenance: current Haskell QuickCheck
2.19 (source, tests, execution); historical QuickCheck 1 (Chalmers);
research (papers); third-party Haskell packages (tasty-quickcheck and
hspec run, others not); ports and Quviq (mentioned only). See
[qik-chk-history](../../qik-chk-history/SKILL.md).
