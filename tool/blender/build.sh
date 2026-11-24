#!/bin/sh
# Re-renders every Blender-made asset (tile layers, 3D icons, streak medals,
# celebration animations).
#   tool/blender/build.sh            all
#   BLENDER=/path/to/blender tool/blender/build.sh
set -e
cd "$(dirname "$0")/../.."
BLENDER="${BLENDER:-/Applications/Blender.app/Contents/MacOS/Blender}"
"$BLENDER" -b --factory-startup -P tool/blender/render_tiles.py -- "$PWD/assets/images/tiles"
"$BLENDER" -b --factory-startup -P tool/blender/render_icons.py -- "$PWD"
# Celebration sprite sheets (needs cwebp: brew install webp). ~12 minutes.
"$BLENDER" -b --factory-startup -P tool/blender/render_anims.py -- "$PWD"
