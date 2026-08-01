#!/bin/bash
# winecx.sh — manage the vendored CrossOver Wine source in this repository.
#
#   ./winecx.sh add    <cxver>   fetch a CrossOver release and stage it as a branch
#   ./winecx.sh verify [cxver]   prove sources/wine is byte-identical to the tarball
#
# Why a script and not instructions: prose drifts from what actually happens, and
# the steps that matter here are the ones a human skips — replacing the tree
# wholesale so files deleted upstream really disappear, refusing to run on a dirty
# tree, and recording the sha256 of what was downloaded.
#
# THE INVARIANT: sources/ is byte-identical to CodeWeavers' tarball. Nothing of ours
# ever goes inside it. Everything of ours lives beside it, at the repository root.
set -euo pipefail

BASE_URL=https://media.codeweavers.com/pub/crossover/source
REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

die()  { echo "error: $*" >&2; exit 1; }
info() { echo "==> $*"; }

usage() { sed -n '3,6p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 1; }

# Download a release tarball into $1 and echo its sha256.
fetch() {
    local ver="$1" dest="$2" tarball="crossover-sources-$1.tar.gz"
    if [ -f "$REPO/$tarball" ]; then
        info "using local $tarball" >&2
        cp "$REPO/$tarball" "$dest/$tarball"
    else
        info "downloading $tarball" >&2
        curl -fL --progress-bar -o "$dest/$tarball" "$BASE_URL/$tarball" \
            || die "download failed — does CrossOver $ver exist?"
    fi
    shasum -a 256 "$dest/$tarball" | awk '{print $1}'
}

cmd_add() {
    local ver="${1:-}"; [ -n "$ver" ] || usage
    local branch="release/$ver"

    [ -z "$(git -C "$REPO" status --porcelain)" ] || die "working tree is not clean"
    git -C "$REPO" rev-parse -q --verify "refs/tags/winecx-$ver" >/dev/null \
        && die "tag winecx-$ver already exists"

    local tmp; tmp=$(mktemp -d); trap 'rm -rf "$tmp"' RETURN
    local sha; sha=$(fetch "$ver" "$tmp")
    info "sha256 $sha"

    tar xzf "$tmp/crossover-sources-$ver.tar.gz" -C "$tmp" sources/wine \
        || die "tarball has no sources/wine — layout changed?"
    [ -f "$tmp/sources/wine/VERSION" ] || die "extracted tree looks wrong (no VERSION)"
    local wine_ver; wine_ver=$(sed -n 's/^Wine version //p' "$tmp/sources/wine/VERSION")

    git -C "$REPO" checkout -q -b "$branch" || die "cannot create branch $branch"

    # Wholesale replacement, not a merge: a file deleted upstream must disappear
    # here too, or "byte-identical" quietly stops being true.
    info "replacing sources/wine"
    rm -rf "$REPO/sources/wine"
    mkdir -p "$REPO/sources"
    cp -a "$tmp/sources/wine" "$REPO/sources/wine"

    printf '| %s | %s | crossover-sources-%s.tar.gz | `%s` | %s |\n' \
        "$ver" "$wine_ver" "$ver" "$sha" "$(date -u +%Y-%m-%d)" >> "$REPO/RELEASES.md"

    git -C "$REPO" add -A
    git -C "$REPO" commit -q -m "WineCX $ver (CrossOver $ver / Wine $wine_ver)

sources/wine replaced wholesale with the unmodified extraction of:
  crossover-sources-$ver.tar.gz
  sha256 $sha
  $BASE_URL/crossover-sources-$ver.tar.gz

Nothing of ours is in sources/. Verify with: ./winecx.sh verify $ver"

    info "committed on $branch"
    local prev; prev=$(git -C "$REPO" tag --sort=-v:refname | head -1)
    [ -n "$prev" ] && info "changed since $prev: $(git -C "$REPO" diff --name-only "$prev" HEAD -- sources/ | wc -l | tr -d ' ') files under sources/"
    echo
    info "next: open a PR for $branch; after merging, tag it:"
    echo "    git tag -a winecx-$ver -m 'WineCX $ver (CrossOver $ver / Wine $wine_ver)' && git push --tags"
}

cmd_verify() {
    local ver="${1:-}"
    if [ -z "$ver" ]; then
        ver=$(git -C "$REPO" describe --tags --abbrev=0 2>/dev/null | sed 's/^winecx-//') \
            || die "no tag found; pass a version explicitly"
        info "verifying against the current tag: winecx-$ver"
    fi
    [ -d "$REPO/sources/wine" ] || die "no sources/wine in this repository"

    local tmp; tmp=$(mktemp -d); trap 'rm -rf "$tmp"' RETURN
    local sha; sha=$(fetch "$ver" "$tmp")
    info "sha256 $sha"
    tar xzf "$tmp/crossover-sources-$ver.tar.gz" -C "$tmp" sources/wine || die "extraction failed"

    info "diffing sources/wine against the tarball"
    if diff -r "$tmp/sources/wine" "$REPO/sources/wine" > "$tmp/diff.txt" 2>&1; then
        info "IDENTICAL — sources/wine matches crossover-sources-$ver.tar.gz exactly"
    else
        echo
        echo "DIFFERENCES FOUND ($(wc -l < "$tmp/diff.txt" | tr -d ' ') lines):"
        head -40 "$tmp/diff.txt"
        die "sources/wine does NOT match the tarball — the invariant is broken"
    fi
}

case "${1:-}" in
    add)    shift; cmd_add "$@" ;;
    verify) shift; cmd_verify "$@" ;;
    *)      usage ;;
esac
