#!/usr/bin/env bash
# Uploads a built voice pack zip (from dist/) to its CurseForge project.
#
#   tools/voice/upload-pack.sh <zip> <project id> "<notes>"
#
# Reads CF_API_TOKEN from the environment, or from ~/.config/fireside/voice.env. The client
# version is release.yml's GAME_VERSION.
set -euo pipefail
zip_file="$1"
project="$2"
notes="$3"
if [ -z "${CF_API_TOKEN:-}" ]; then
	CF_API_TOKEN="$(sed -n 's/^CF_API_TOKEN=//p' "$HOME/.config/fireside/voice.env")"
fi
[ -n "$CF_API_TOKEN" ] || { echo "Set CF_API_TOKEN, or add it to ~/.config/fireside/voice.env." >&2; exit 1; }
root="$(cd "$(dirname "$0")/../.." && pwd)"
game_version="$(sed -n 's/^  GAME_VERSION: "\(.*\)"$/\1/p' "$root/.github/workflows/release.yml")"
api="https://wow.curseforge.com/api"
ids="$(curl -fsS -H "X-Api-Token: $CF_API_TOKEN" "$api/game/versions" |
	jq -c --arg name "$game_version" '[.[] | select(.name == $name) | .id]')"
if [ "$(jq length <<< "$ids")" != 1 ]; then
	echo "Expected one CurseForge game version named $game_version, found: $ids" >&2
	exit 1
fi
base="$(basename "$zip_file" .zip)"
name="$(sed -E 's/^FiresideTalesVoices_([A-Za-z]+)-(.*)$/Fireside Tales Voices: \1 \2/' <<< "$base")"
metadata="$(jq -n --arg notes "$notes" --arg name "$name" --argjson ids "$ids" \
	'{changelog: $notes, changelogType: "markdown", displayName: $name, gameVersions: $ids, releaseType: "release",
	  relations: {projects: [{slug: "fireside-tales", type: "requiredDependency"}]}}')"
curl -sS --fail-with-body -H "X-Api-Token: $CF_API_TOKEN" \
	--form-string "metadata=$metadata" -F "file=@$zip_file" \
	"$api/projects/$project/upload-file"
echo
