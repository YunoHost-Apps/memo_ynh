#!/usr/bin/env bash
#
# Point the manifest at another memo revision.
#
#   dev/update-source.sh          # the newest tag
#   dev/update-source.sh v0.9.0   # a particular tag
#   dev/update-source.sh main     # the tip of a branch
#
# A tag is pinned by name, which is what YunoHost's autoupdate bot expects to
# find and rewrite. Anything else is resolved to the commit it points at,
# because Codeberg serves the same bytes for a tag or a commit archive forever,
# while a branch archive changes under the checksum's feet.
#
# This does not touch the version in the manifest. Bump that by hand: the
# upstream half to the new tag, or the ~ynhN suffix when only the packaging
# changed.

set -euo pipefail

cd "$(dirname "$0")/.."

repo="https://codeberg.org/mrflos/memo"
api="https://codeberg.org/api/v1/repos/mrflos/memo"
ref="${1:-}"

if [[ -z "$ref" ]]; then
    ref=$(curl -fsSL "$api/tags?limit=1" | jq -r '.[0].name // empty')
    [[ -n "$ref" ]] || { echo "No tags in $repo, name a branch or a commit" >&2; exit 1; }
fi

if curl -fsSL -o /dev/null "$api/tags/$ref" 2> /dev/null; then
    revision="$ref"
else
    revision=$(curl -fsSL "$api/commits?sha=$ref&limit=1" | jq -r '.[0].sha // empty')
    [[ -n "$revision" ]] || { echo "Could not resolve $ref in $repo" >&2; exit 1; }
fi

url="$repo/archive/$revision.tar.gz"
sum=$(curl -fsSL "$url" | sha256sum | cut -d' ' -f1)

python3 - "$url" "$sum" <<'PY'
import re
import sys

url, checksum = sys.argv[1:]

manifest = open("manifest.toml").read()
head, sep, rest = manifest.partition("[resources.sources.main]")
if not sep:
    sys.exit("No [resources.sources.main] block in manifest.toml")
main, sep2, tail = rest.partition("[resources.sources.bun]")

for pattern, value in ((r'(url = ").*(")', url), (r'(sha256 = ").*(")', checksum)):
    main, count = re.subn(pattern, lambda m: m.group(1) + value + m.group(2), main, count=1)
    if count != 1:
        sys.exit(f"Could not find {pattern} in the main source block")

open("manifest.toml", "w").write(head + sep + main + sep2 + tail)
PY

echo "memo $revision"
echo "$sum"
