#!/usr/bin/env bash
# Harftaş seslerini üretir: synth.py -> WAV -> assets/audio/*.ogg (44,1 kHz Vorbis).
# Gerekenler: python3 (numpy, scipy), oggenc (brew install vorbis-tools).  Kullanım: tool/sfx/build.sh [python]
set -euo pipefail
cd "$(dirname "$0")/../.."
PY="${1:-python3}"
TMP="$(mktemp -d)"
"$PY" tool/sfx/synth.py "$TMP" >/dev/null
mkdir -p assets/audio
for w in "$TMP"/*.wav; do
  n="$(basename "$w" .wav)"
  oggenc -Q -q 5 -o "assets/audio/$n.ogg" "$w"
done
rm -rf "$TMP"
ls assets/audio | wc -l | xargs echo "dosya:"
du -sh assets/audio
