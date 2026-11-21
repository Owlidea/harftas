#!/usr/bin/env bash
# Production builds. Usage:
#   tool/release.sh android   -> build/app/outputs/bundle/release/app-release.aab
#   tool/release.sh ios       -> build/ios/ipa/*.ipa   (needs full Xcode)
#   tool/release.sh web       -> build/web             (static site, no ads/IAP)
#   tool/release.sh all
# Needs config/prod.json (copy config/prod.example.json) and, for Android,
# android/key.properties (tool/create_upload_key.sh). See docs/yayin_rehberi.md.
set -euo pipefail
cd "$(dirname "$0")/.."

target="${1:-all}"
defines=()
if [[ -f config/prod.json ]]; then
  defines=(--dart-define-from-file=config/prod.json)
elif [[ "$target" != "web" ]]; then
  echo "HATA: config/prod.json yok (config/prod.example.json'u kopyalayıp doldurun)." >&2
  exit 1
fi

check() {
  flutter analyze
  flutter test
}

android() {
  if [[ ! -f android/key.properties ]]; then
    echo "HATA: android/key.properties yok. Önce: tool/create_upload_key.sh" >&2
    exit 1
  fi
  if grep -q "XXXX" config/prod.json; then
    echo "HATA: config/prod.json içinde doldurulmamış kimlik var." >&2
    exit 1
  fi
  flutter build appbundle --release --obfuscate --split-debug-info=build/symbols/android "${defines[@]}"
  echo "→ build/app/outputs/bundle/release/app-release.aab (Play Console'a yükleyin)"
  echo "  Hata ayıklama sembolleri: build/symbols/android (saklayın, Git'e koymayın)"
}

ios() {
  flutter build ipa --release --obfuscate --split-debug-info=build/symbols/ios "${defines[@]}"
  echo "→ build/ios/ipa (Transporter veya Xcode ile App Store Connect'e yükleyin)"
}

web() {
  # No FAKE_SERVICES: the web build has no ads or purchases.
  flutter build web --release "${defines[@]}"
  echo "→ build/web klasörünü herhangi bir statik barındırmaya yükleyin."
}

check
case "$target" in
  android) android ;;
  ios) ios ;;
  web) web ;;
  all) android; web; ios ;;
  *) echo "Kullanım: tool/release.sh [android|ios|web|all]" >&2; exit 2 ;;
esac
