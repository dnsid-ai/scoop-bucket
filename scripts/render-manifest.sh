#!/usr/bin/env bash
#
# Render bucket/dnsid.json for a released version of the dnsid CLI.
#
#   ./scripts/render-manifest.sh 2026.08.25-22f2882
#
# Reads SHA256SUMS and the Windows archive from $ARTIFACT_BASE/<version>/, and
# writes the manifest. Does not commit — the workflow does that, and running
# this locally leaves a diff you can inspect.
#
# Fails closed at every step. A manifest that points at an archive which is not
# there, or whose checksum we could not read, is worse than no update at all:
# Scoop would surface it to users as a broken install of a version that looks
# published.

set -euo pipefail

VERSION="${1:-}"
if [ -z "$VERSION" ]; then
  echo "usage: $0 <version>   e.g. $0 2026.08.25-22f2882" >&2
  exit 2
fi

# The one place the download host is stated. When dnsid moves to dnsid-ai and
# its release assets become public, point this at
# https://github.com/dnsid-ai/dnsid/releases/download — the path shape
# (<base>/<version>/<file>) is the same, so nothing else changes.
ARTIFACT_BASE="${ARTIFACT_BASE:-https://dnsid-prod-cli-binaries.s3.us-east-1.amazonaws.com/cli}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TEMPLATE="$REPO_ROOT/templates/dnsid.json.tmpl"
OUTPUT="$REPO_ROOT/bucket/dnsid.json"

# Windows amd64 only. There is no windows/arm64 archive to reference —
# .goreleaser.yaml in the CLI repo ignores that target.
ARCHIVE="dnsid_windows_amd64.zip"

die() { echo "error: $*" >&2; exit 1; }

echo "version:  $VERSION"
echo "base:     $ARTIFACT_BASE"

SUMS="$(curl -fsSL "$ARTIFACT_BASE/$VERSION/SHA256SUMS")" \
  || die "no SHA256SUMS for $VERSION at $ARTIFACT_BASE. Either the version is wrong, or the release never uploaded its artifacts."

# Confirm the archive is actually there. SHA256SUMS existing does not prove the
# archives beside it do — releases have been tagged with no artifacts behind
# them.
URL="$ARTIFACT_BASE/$VERSION/$ARCHIVE"
curl -fsSL -o /dev/null -r 0-0 "$URL" || die "$ARCHIVE is not downloadable at $URL"

SHA="$(printf '%s\n' "$SUMS" | awk -v f="$ARCHIVE" '$2 == f { print $1 }')"
[ -n "$SHA" ] || die "SHA256SUMS has no entry for $ARCHIVE"
printf '%s\n' "$SHA" | grep -Eq '^[0-9a-f]{64}$' \
  || die "checksum for $ARCHIVE is not a sha256 digest: $SHA"

mkdir -p "$(dirname "$OUTPUT")"

sed \
  -e "s|@VERSION@|$VERSION|g" \
  -e "s|@ARTIFACT_BASE@|$ARTIFACT_BASE|g" \
  -e "s|@SHA_WINDOWS_AMD64@|$SHA|g" \
  "$TEMPLATE" > "$OUTPUT"

# A leftover placeholder means the template grew a field the script does not
# fill, which would ship a manifest Scoop cannot use.
if grep -q '@[A-Z_]*@' "$OUTPUT"; then
  grep -n '@[A-Z_]*@' "$OUTPUT" >&2
  die "unsubstituted placeholders remain in $OUTPUT"
fi

# Unlike the cask, this is machine-parsed by Scoop before anything is
# downloaded, so a malformed file fails at the user rather than here.
jq empty < "$OUTPUT" || die "$OUTPUT is not valid JSON"

echo "wrote:    $OUTPUT"
