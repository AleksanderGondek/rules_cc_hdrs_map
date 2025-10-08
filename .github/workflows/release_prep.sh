#! /usr/bin/env bash
set -euo pipefail

# This file is the explicit requirement of bazel-contrib/.github/workflows/release_ruleset workflow
# https://github.com/bazel-contrib/.github/blob/a841d62420f41a87a601fb331f3c2c2cc088506e/.github/workflows/release_ruleset.yaml#L41
#
# It's task is to provide release notes and adjust - if needed - the release artifacts.
# At the moment we can simply cat the release_notes.md prepared in previous steps.
#
# Why use the release_rulest?
# To ensure the release is attested (and thus have nice checkmarks)

cat ./dist/release_notes.md
