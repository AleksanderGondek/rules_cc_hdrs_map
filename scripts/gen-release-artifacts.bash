#! /usr/bin/env bash
set -euo pipefail
set -x

# Heavily inspired by: https://releases.nixos.org/nix/nix-2.20.1/install
oops() {
    echo "$0:" "$@" >&2
    exit 1
}

require_util() {
    command -v "$1" > /dev/null 2>&1 ||
        oops "you do not have '$1' installed, which I need to $2"
}

require_util cat "print out contents of files"
require_util cog "get release version and notes"
require_util git "interact with the svc"
require_util gzip "gzip files"
require_util popd "ensure the commands are run in appropriate working dir"
require_util pushd "ensure the commands are run in appropriate working dir"
require_util tar "tar files"

# Author's soap box:
# Between gh-action job steps, the directory
# used by default by mktemp ($TMPDIR) is purged!
# However the dedicated $RUNNER_TEMP is not!
# Why TMPDIR is not set to RUNNER_TEMP?
# Quite unexected
OUT_DIR=$(mktemp -d -p ${RUNNER_TEMP:-"/tmp"})
pushd $(git rev-parse --show-toplevel) >/dev/null

# obtain the current version
echo "v$(cog get-version 2>/dev/null)" >${OUT_DIR}/version
# generate release note
cog changelog --at "$(cat ${OUT_DIR}/version)" >${OUT_DIR}/release-notes.md 2>/dev/null

# create tar.gz archive
## logic lifted from:
## https://www.gnu.org/software/tar/manual/html_node/Reproducibility.html

function get_commit_time() {
  TZ=UTC0 git log -1 \
    --format=tformat:%cd \
    --date=format:%Y-%m-%dT%H:%M:%SZ \
    "$@"
}

## Set each source file timestamp to that of its latest commit.
git ls-files | while read -r file; do
  commit_time=$(get_commit_time "$file")
  commit_time=${commit_time:-$(TZ=UTC0 date -r $file "+%Y-%m-%dT%H:%M:%SZ")}
  touch -md $commit_time "$file"
done

## create $ARCHIVE.tgz from $FILES, pretending that
## the modification time for each newer file
## is that of the most recent commit of any source file.
SOURCE_EPOCH=$(get_commit_time)
TARFLAGS="
  --sort=name --format=posix
  --pax-option=exthdr.name=%d/PaxHeaders/%f
  --pax-option=delete=atime,delete=ctime
  --clamp-mtime --mtime=$SOURCE_EPOCH
  --numeric-owner --owner=0 --group=0
  --mode=go+u,go-w
"
GZIPFLAGS="--no-name --best"
LC_ALL=C tar $TARFLAGS -c --to-stdout $(git ls-files) |
  gzip $GZIPFLAGS > "${OUT_DIR}/rules_cc_hdrs_map-$(cat ${OUT_DIR}/version).tar.gz"

## end of logic from GNU org

popd >/dev/null
# 'return the output dir with results'
echo ${OUT_DIR}
