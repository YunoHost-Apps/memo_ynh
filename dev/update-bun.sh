#!/usr/bin/env bash
#
# Point the manifest at another bun release.
#
#   dev/update-bun.sh            # the latest release
#   dev/update-bun.sh 1.4.2      # a specific one
#
# YunoHost's autoupdate bot follows the app's own sources, not the runtime
# underneath it, so this is the part nobody updates for you. Checksums come
# from the GitHub API rather than from a download: the release assets are 36 MB
# each and the API already publishes their digest.

set -euo pipefail

cd "$(dirname "$0")/.."

version="${1:-}"
if [[ -z "$version" ]]; then
    tag=$(curl -fsSL https://api.github.com/repos/oven-sh/bun/releases/latest | jq -r .tag_name)
else
    tag="bun-v${version#v}"
fi

release=$(curl -fsSL "https://api.github.com/repos/oven-sh/bun/releases/tags/$tag")

digest_of() {
    local asset="$1"
    local sum
    sum=$(jq -r --arg n "$asset" '.assets[] | select(.name == $n) | .digest' <<< "$release")
    if [[ "$sum" != sha256:* ]]; then
        echo "No sha256 published for $asset in $tag" >&2
        exit 1
    fi
    echo "${sum#sha256:}"
}

base="https://github.com/oven-sh/bun/releases/download/$tag"

# The baseline build on amd64 on purpose: it drops the AVX2 requirement, and a
# fair number of self-hosted boxes predate it.
amd64_asset="bun-linux-x64-baseline.zip"
arm64_asset="bun-linux-aarch64.zip"

amd64_sum=$(digest_of "$amd64_asset")
arm64_sum=$(digest_of "$arm64_asset")

python3 - "$tag" "$base/$amd64_asset" "$amd64_sum" "$base/$arm64_asset" "$arm64_sum" <<'PY'
import re
import sys

tag, amd64_url, amd64_sum, arm64_url, arm64_sum = sys.argv[1:]
version = tag.removeprefix("bun-v")

manifest = open("manifest.toml").read()
head, sep, bun = manifest.partition("[resources.sources.bun]")
if not sep:
    sys.exit("No [resources.sources.bun] block in manifest.toml")

replacements = {
    r'(amd64\.url = ").*(")': amd64_url,
    r'(amd64\.sha256 = ").*(")': amd64_sum,
    r'(arm64\.url = ").*(")': arm64_url,
    r'(arm64\.sha256 = ").*(")': arm64_sum,
    r'(\(currently ).*(\))': version,
}
for pattern, value in replacements.items():
    bun, count = re.subn(pattern, lambda m: m.group(1) + value + m.group(2), bun, count=1)
    if count != 1:
        sys.exit(f"Could not find {pattern} in the bun source block")

open("manifest.toml", "w").write(head + sep + bun)
print(f"bun {version}")
PY
