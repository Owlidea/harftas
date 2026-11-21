#!/usr/bin/env bash
# Creates the Android upload key and android/key.properties (both git-ignored).
# keytool asks for the passwords itself; keep the .jks file and passwords in a
# password manager — losing them means you cannot update the app (unless Play
# App Signing resets the upload key).
set -euo pipefail
cd "$(dirname "$0")/.."
store="${1:-$HOME/harftas-upload-keystore.jks}"
if [[ -f "$store" ]]; then echo "Zaten var: $store" >&2; exit 1; fi
keytool -genkey -v -keystore "$store" -storetype JKS -keyalg RSA -keysize 2048 -validity 10000 -alias upload
read -r -s -p "Az önce girdiğiniz anahtar deposu parolası: " pw; echo
cat > android/key.properties <<PROPS
storePassword=$pw
keyPassword=$pw
keyAlias=upload
storeFile=$store
PROPS
chmod 600 android/key.properties
echo "Tamam: android/key.properties yazıldı → $store"
