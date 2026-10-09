#!/bin/bash
# release-check.sh — pre-release gate for KegPilot.
#
# Verifies, and FAILS NONZERO on the first problem, that a release is internally
# consistent before it is tagged/published. Codifies the manual checklist in
# PUBLISHING.md and the by-hand verification done for 2.4.1, closing the process
# gaps that previously caused version drift (2.3 vs 2.4) and a lagging checksum
# manifest the fail-closed updater depends on.
#
# Checks:
#   1. Test suites pass (./test.sh).
#   2. Version consistency: Info.plist == <version>, and the same <version>
#      appears in docs/index.html (softwareVersion, both download hrefs, footer),
#      root README.md, and PUBLISHING.md — with NO stale KegPilot-X.Y(.Z).zip refs.
#   3. Package contents: a fresh build reports <version>, and the published
#      docs/downloads/KegPilot-<version>.zip contains KegPilot.app.
#   4. Checksum coverage: SHA256SUMS.txt has an entry for the exact asset and it
#      matches the zip's actual SHA-256.
#
# Usage:  ./release-check.sh            # auto-detect <version> from Info.plist
#         ./release-check.sh 2.4.1      # assert against an explicit <version>
set -euo pipefail
cd "$(dirname "$0")"                 # src/
REPO_ROOT="$(cd .. && pwd)"

red()  { printf '\033[31m%s\033[0m\n' "$*"; }
grn()  { printf '\033[32m%s\033[0m\n' "$*"; }
fail() { red "FAIL: $*"; exit 1; }
ok()   { grn "  ok: $*"; }

PLIST="Info.plist"
PLIST_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "$PLIST")"
VERSION="${1:-$PLIST_VERSION}"
ZIP_NAME="KegPilot-${VERSION}.zip"
ZIP_PATH="${REPO_ROOT}/docs/downloads/${ZIP_NAME}"
SUMS="${REPO_ROOT}/docs/downloads/SHA256SUMS.txt"

printf 'Release check for KegPilot %s\n\n' "$VERSION"

# 1. Tests ----------------------------------------------------------------------
printf '1. Running test suites…\n'
if ! ./test.sh >/tmp/kegpilot-release-tests.log 2>&1; then
  tail -20 /tmp/kegpilot-release-tests.log
  fail "test.sh did not pass (see /tmp/kegpilot-release-tests.log)"
fi
ok "test.sh passed"

# 2. Version consistency --------------------------------------------------------
printf '2. Version consistency (%s)…\n' "$VERSION"
[ "$PLIST_VERSION" = "$VERSION" ] || fail "Info.plist CFBundleShortVersionString is $PLIST_VERSION, expected $VERSION"
ok "Info.plist = $VERSION"

INDEX="${REPO_ROOT}/docs/index.html"
grep -q "\"softwareVersion\": \"${VERSION}\"" "$INDEX" || fail "docs/index.html softwareVersion is not $VERSION"
# Both download buttons (hero + install) must point at the current asset.
href_count="$(grep -c "downloads/${ZIP_NAME}" "$INDEX" || true)"
[ "$href_count" -ge 2 ] || fail "docs/index.html has $href_count download links to ${ZIP_NAME}, expected >= 2"
grep -q "Version ${VERSION}\." "$INDEX" || fail "docs/index.html footer does not say 'Version ${VERSION}.'"
ok "docs/index.html (softwareVersion, ${href_count} hrefs, footer)"

grep -q "${ZIP_NAME}" "${REPO_ROOT}/README.md"   || fail "root README.md does not reference ${ZIP_NAME}"
grep -q "${ZIP_NAME}" "${REPO_ROOT}/PUBLISHING.md" || fail "PUBLISHING.md does not reference ${ZIP_NAME}"
ok "README.md and PUBLISHING.md reference ${ZIP_NAME}"

# No stale KegPilot-<other>.zip references lingering in the user-facing files.
stale="$(grep -rhoE 'KegPilot-[0-9]+\.[0-9]+(\.[0-9]+)?\.zip' "$INDEX" "${REPO_ROOT}/README.md" "${REPO_ROOT}/PUBLISHING.md" \
         | sort -u | grep -v "^${ZIP_NAME}$" || true)"
[ -z "$stale" ] || fail "stale zip references in user-facing docs: $stale"
ok "no stale zip references in index.html / README.md / PUBLISHING.md"

# 3. Package contents -----------------------------------------------------------
printf '3. Package contents…\n'
./build.sh >/tmp/kegpilot-release-build.log 2>&1 || { tail -20 /tmp/kegpilot-release-build.log; fail "build.sh failed"; }
BUILT_VERSION="$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' build/KegPilot.app/Contents/Info.plist)"
[ "$BUILT_VERSION" = "$VERSION" ] || fail "built app reports $BUILT_VERSION, expected $VERSION"
ok "built app reports $VERSION"

[ -f "$ZIP_PATH" ] || fail "release zip not found at $ZIP_PATH (build & package it first)"
ZIP_LISTING="$(unzip -l "$ZIP_PATH")"
printf '%s\n' "$ZIP_LISTING" | grep -q 'KegPilot\.app/' || fail "$ZIP_NAME does not contain KegPilot.app"
ok "$ZIP_NAME contains KegPilot.app"

# 4. Checksum coverage ----------------------------------------------------------
printf '4. Checksum coverage…\n'
[ -f "$SUMS" ] || fail "SHA256SUMS.txt not found at $SUMS"
MANIFEST_HASH="$(grep -E "[[:space:]]${ZIP_NAME}\$" "$SUMS" | awk '{print $1}' | tr '[:upper:]' '[:lower:]')"
[ -n "$MANIFEST_HASH" ] || fail "SHA256SUMS.txt has no entry for ${ZIP_NAME}"
ACTUAL_HASH="$(shasum -a 256 "$ZIP_PATH" | awk '{print $1}')"
[ "$MANIFEST_HASH" = "$ACTUAL_HASH" ] || fail "checksum mismatch for ${ZIP_NAME}: manifest $MANIFEST_HASH != actual $ACTUAL_HASH"
ok "SHA256SUMS.txt entry matches ${ZIP_NAME} ($ACTUAL_HASH)"

printf '\n'; grn "All release checks passed for KegPilot ${VERSION}."
