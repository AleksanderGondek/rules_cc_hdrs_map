#! /usr/bin/env nix-shell
#! nix-shell --quiet ../non-nixos-shell.nix
#! nix-shell -i bash

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
require_util cut "split sha256sum outputs"
require_util git "interact with the svc"
require_util gzip "gzip files"
require_util popd "ensure the commands are run in appropriate working dir"
require_util pushd "ensure the commands are run in appropriate working dir"
require_util sha256sum "calculate the hash of the created archive"
require_util tar "tar files"

# Author's soap box:
# Between gh-action job steps, the directory
# used by default by mktemp ($TMPDIR) is purged!
# However the dedicated $RUNNER_TEMP is not!
# Why TMPDIR is not set to RUNNER_TEMP?
# Quite unexpected
OUT_DIR=$(mktemp -d -p ${RUNNER_TEMP:-"/tmp"})
pushd $(git rev-parse --show-toplevel) >/dev/null

# Obtain and save the current version of the ruleset
echo "v$(cog get-version 2>/dev/null)" >${OUT_DIR}/version
VERSION="$(cat ${OUT_DIR}/version)"

# Generate release notes for the current version of the ruleset
RELEASE_NOTES="${OUT_DIR}/release_notes.md"
cog changelog --at "${VERSION}" >${RELEASE_NOTES} 2>/dev/null

# === Creation of the *.tar.gz file ===
ARCHIVE_NAME="rules_cc_hdrs_map-${VERSION}.tar.gz"

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
  gzip $GZIPFLAGS > "${OUT_DIR}/${ARCHIVE_NAME}"

ARCHIVE_SHA=$(sha256sum "${OUT_DIR}/${ARCHIVE_NAME}" | cut -f 1 -d' ')

## end of logic from GNU org
# === End of creation of the *.tar.gz file ===

# Extend the release_notes.md with usage example
cat <<EOF >> ${RELEASE_NOTES}
## Usage example

### Bzlmod

Paste this snippet into your \`MODULE.bazel\` file:

\`\`\`starlark
bazel_dep(name = "rules_cc_hdrs_map", version = "${VERSION}")
\`\`\`

### WORKSPACE (deprecated)

Paste this snippet into your \`WORKSPACE.bazel\` file:

\`\`\`starlark
load("@bazel_tools//tools/build_defs/repo:http.bzl", "http_archive")
http_archive(
    name = "rules_cc_hdrs_map",
    sha256 = "${ARCHIVE_SHA}",
    url = "https://github.com/AleksanderGondek/rules_cc_hdrs_map/releases/download/${VERSION}/${ARCHIVE_NAME}",
)

load("@rules_cc_hdrs_map//cc_hdrs_map:workspace_deps.bzl", "cc_hdrs_map_workspace_deps")
cc_hdrs_map_workspace_deps()

load("@rules_cc//cc:extensions.bzl", "compatibility_proxy_repo")
compatibility_proxy_repo()
\`\`\`
EOF

popd >/dev/null

# 'return the output dir with results'
echo ${OUT_DIR}
