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
# Brand art: app icon, adaptive layers, splash mark, wordmark, feature graphic.
# Afterwards: dart run flutter_launcher_icons && dart run flutter_native_splash:create
# (the splash tool rewrites AndroidManifest.xml: restore it with git checkout).
"$BLENDER" -b --factory-startup -P tool/blender/render_brand.py -- "$PWD"
# Celebration and board-effect sprite sheets (needs cwebp: brew install webp). ~20 minutes.
"$BLENDER" -b --factory-startup -P tool/blender/render_anims.py -- "$PWD"
# Board surface textures (needs cwebp).
"$BLENDER" -b --factory-startup -P tool/blender/render_boards.py -- "$PWD"
