# winecx-sources

**CodeWeavers' published CrossOver Wine source, vendored in git — the build base for
[wine-workbench-macos](https://github.com/gilnoh/wine-workbench-macos).**

A *companion repository*, not a mirror. Read the next two sections before relying on it.

## Get the real thing from CodeWeavers

The authoritative source is published by CodeWeavers, freely and without an account:

```sh
CXVER=26.3.0
curl -O https://media.codeweavers.com/pub/crossover/source/crossover-sources-$CXVER.tar.gz
shasum -a 256 crossover-sources-$CXVER.tar.gz
tar xzf crossover-sources-$CXVER.tar.gz        # -> sources/wine
```

Prefer that. It is the original, it is always current, and it needs nothing from us.

## And buy CrossOver — seriously

If you use Wine on macOS, you are standing on CodeWeavers' work. Practically every hard
problem the workbench hit in its first days turned out to be **already solved in their
tree** — the WoW64 mode switch under Rosetta, the menu-latency paint fix, GPU-process
handling for Chromium. They fixed those long before we noticed them, and they publish the
source under the LGPL so anyone can use it.

CrossOver is a good product and it is what funds Wine-on-macOS development. Buying a
licence is the most direct way to keep this ecosystem alive — and if you do the kind of
work this repository supports, a version-matched CrossOver install is also the single most
useful debugging tool available: a known-good reference to compare against.

<https://www.codeweavers.com/crossover>

## What this is

A git history of CodeWeavers' release tarballs, kept for one practical reason:
**tarballs cannot be diffed, and git trees can.**

"What changed between CrossOver 26.0.0 and 26.3.0?" should take seconds, not two 300 MB
extractions. (For the record: about 35 files out of 12,439 — none in `winemac.drv`,
`wow64cpu`, `wined3d` or `dxgi`.) It also gives changes built on top of a release
somewhere sane to live: as commits against a tagged base, which is the form anything would
need to be in before someone else could review it.

```
├── README.md          this file
├── NOTICE             copyright and licence
├── RELEASES.md        every vendored release: version, sha256, date
├── winecx.sh          add a release, or verify one against the original
└── sources/
    └── wine/          ← byte-identical to the tarball. Nothing of ours, ever.
```

**The invariant: `sources/` is exactly what CodeWeavers shipped.** Everything of ours
lives beside it, never inside it. That is what keeps "byte-identical" a claim you can
check rather than one you have to trust:

```sh
./winecx.sh verify 26.3.0     # downloads the tarball and diffs it against sources/wine
```

Releases are tagged `winecx-<crossover version>` on `main`, so:

```sh
git diff --stat winecx-26.3.0 winecx-26.4.0 -- sources/      # what CodeWeavers changed
git checkout winecx-26.3.0                                   # a specific release
```

⚠️ **The version number is CrossOver's, not Wine's.** `winecx-26.3.0` = CrossOver 26.3.0
= **Wine 11.0**. Three version numbers are in play and confusing them wastes an afternoon.
"WineCX" is a community label, not CodeWeavers' — they ship
`crossover-sources-<ver>.tar.gz` and nothing else.

### Adding a release

```sh
./winecx.sh add 26.4.0     # branch release/26.4.0, replace sources/wine, record sha256
                           # then open a PR, merge, and tag winecx-26.4.0
```

The script replaces `sources/wine` **wholesale** rather than merging, so files removed
upstream actually disappear; it refuses to run on a dirty tree or over an existing tag;
and it records the tarball's sha256 in both the commit message and `RELEASES.md`. The
resulting PR diff is the interesting artefact — it is precisely what changed between two
CrossOver releases.

## What this is NOT

**Not a mirror, and no promise to track releases.** It serves one workbench; releases
appear when that workbench needs them, and it may sit at an old version indefinitely.

That matters because stale mirrors cost real time — searching for a git-tracked CrossOver
source turns up `Gcenx/winecx` (deleted), `PhoenicisOrg/winecx` (stopped at 25.1.0 in
September 2025), and MacPorts' `wine-crossover` (CrossOver 18). Each looks usable until
you check the date. This repository would rather state the same risk plainly: **if you
need current, go to CodeWeavers.**

## Using it with the workbench

[wine-workbench-macos](https://github.com/gilnoh/wine-workbench-macos) expects this
repository at `src/crossover`, which puts the Wine tree exactly where it looks for it:

```sh
git clone <this-repo> src/crossover
git -C src/crossover checkout winecx-26.3.0     # match the runtime you intend to build
```

Or skip it entirely and use CodeWeavers' tarball directly — the workbench documents that
path too, and it is the authoritative one.

## Licence and attribution

Everything under `sources/` is **Copyright © CodeWeavers, Inc. and the Wine authors**,
licensed under the **GNU Lesser General Public License, version 2.1 or later** — the same
terms Wine and CrossOver's published sources carry. `sources/wine/COPYING.LIB` is the
canonical text. Redistribution in source form is exactly what the LGPL permits, and that
is all this repository does.

The files outside `sources/` (this README, `NOTICE`, `RELEASES.md`, `winecx.sh`) are the
only original work here; take them under the MIT licence if they are useful.

**Not affiliated with, endorsed by, or supported by CodeWeavers.** CrossOver is their
trademark. Do not report problems with this repository to them — and do not report
problems found *through* it without first reproducing against the original tarball.
