#!/usr/bin/env bash
#
# Point the manifest at another memo release.
#
#   dev/update-source.sh          # the newest release
#   dev/update-source.sh v0.9.9   # a particular one
#
# A release carries three binaries and a .sha256 beside each. Those checksum
# files are what this reads, rather than downloading 280 MB to hash it again;
# they are made by the same job that compiles the binaries, in the same run.
#
# This does not touch the version in the manifest. Bump that by hand: the
# upstream half to the new tag, or the ~ynhN suffix when only the packaging
# changed.

set -euo pipefail

cd "$(dirname "$0")/.."

api="https://codeberg.org/api/v1/repos/mrflos/memo/releases"
tag="${1:-}"

if [[ -n "$tag" ]]; then
    release=$(curl -fsSL "$api/tags/${tag#v}" 2> /dev/null || curl -fsSL "$api/tags/$tag")
else
    release=$(curl -fsSL "$api?limit=1&draft=false&pre-release=false" | jq '.[0]')
fi

tag=$(jq -r .tag_name <<< "$release")
[[ -n "$tag" && "$tag" != "null" ]] || { echo "No such release" >&2; exit 1; }

# The asset whose name ends in $1, and the checksum published beside it.
asset_url() {
    jq -r --arg suffix "$1" \
        '.assets[] | select(.name | endswith($suffix)) | .browser_download_url' <<< "$release" \
        | grep -v '\.sha256$'
}

sum_of() {
    local url
    url=$(jq -r --arg name "$1.sha256" \
        '.assets[] | select(.name | endswith($name)) | .browser_download_url' <<< "$release")
    curl -fsSL "$url" | cut -d' ' -f1
}

declare -A url sum
for suffix in linux-amd64 linux-amd64-baseline linux-arm64; do
    url[$suffix]=$(asset_url "$suffix")
    sum[$suffix]=$(sum_of "$suffix")
    if [[ -z "${url[$suffix]}" || -z "${sum[$suffix]}" ]]; then
        echo "$tag publishes no $suffix binary with its checksum" >&2
        exit 1
    fi
done

python3 - "${url[linux-amd64-baseline]}" "${sum[linux-amd64-baseline]}" \
    "${url[linux-arm64]}" "${sum[linux-arm64]}" \
    "${url[linux-amd64]}" "${sum[linux-amd64]}" <<'PY'
import re
import sys

baseline_url, baseline_sum, arm64_url, arm64_sum, avx2_url, avx2_sum = sys.argv[1:]

manifest = open("manifest.toml").read()
head, sep, rest = manifest.partition("[resources.sources.main]")
if not sep:
    sys.exit("No [resources.sources.main] block in manifest.toml")
main, sep2, avx2 = rest.partition("[resources.sources.amd64_avx2]")
if not sep2:
    sys.exit("No [resources.sources.amd64_avx2] block in manifest.toml")


def pin(block, name, replacements):
    for pattern, value in replacements:
        block, count = re.subn(pattern, lambda m: m.group(1) + value + m.group(2), block, count=1)
        if count != 1:
            sys.exit(f"Could not find {pattern} in the {name} source block")
    return block


main = pin(main, "main", [
    (r'(amd64\.url = ").*(")', baseline_url),
    (r'(amd64\.sha256 = ").*(")', baseline_sum),
    (r'(arm64\.url = ").*(")', arm64_url),
    (r'(arm64\.sha256 = ").*(")', arm64_sum),
])
avx2 = pin(avx2, "amd64_avx2", [
    (r'(amd64\.url = ").*(")', avx2_url),
    (r'(amd64\.sha256 = ").*(")', avx2_sum),
])

open("manifest.toml", "w").write(head + sep + main + sep2 + avx2)
PY

echo "memo $tag"
for suffix in linux-amd64-baseline linux-arm64 linux-amd64; do
    echo "  ${sum[$suffix]}  $(basename "${url[$suffix]}")"
done
