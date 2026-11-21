#!/bin/bash
# Builds "build/Countdown Mini.app" (the app with its widget extension inside).
# Pass --install to copy it to /Applications, --run to launch it.
# Set UNIVERSAL=1 to build for both Apple Silicon and Intel Macs (used for releases).
set -euo pipefail
cd "$(dirname "$0")"

ICONSET="App/Assets.xcassets/AppIcon.appiconset"
if [ ! -f "$ICONSET/icon_512x512@2x.png" ]; then
    TMP="$(mktemp -d)"
    swift scripts/make-icon.swift "$TMP/icon.png"
    for s in 16 32 128 256 512; do
        sips -z $s $s "$TMP/icon.png" --out "$ICONSET/icon_${s}x${s}.png" >/dev/null
        sips -z $((s * 2)) $((s * 2)) "$TMP/icon.png" --out "$ICONSET/icon_${s}x${s}@2x.png" >/dev/null
    done
    rm -rf "$TMP"
fi

# A new build number every time: the system caches each widget's description (kind, whether
# it is configurable) per bundle version and ignores changes under the same one.
BUILD_NUMBER="$(date +%s)"

OUT="$PWD/.build/xcode/out"
ARCH_FLAGS=()
if [ "${UNIVERSAL:-0}" = "1" ]; then ARCH_FLAGS=(ARCHS="arm64 x86_64" ONLY_ACTIVE_ARCH=NO); fi

xcodebuild -project CountdownMini.xcodeproj -scheme CountdownMini -configuration Release \
    -derivedDataPath .build/xcode CONFIGURATION_BUILD_DIR="$OUT" \
    MARKETING_VERSION="$(cat VERSION)" CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
    CODE_SIGN_INJECT_BASE_ENTITLEMENTS=NO \
    ${ARCH_FLAGS[@]+"${ARCH_FLAGS[@]}"} -quiet build

APP="build/Countdown Mini.app"
rm -rf "$APP"
mkdir -p build
cp -R "$OUT/Countdown Mini.app" "$APP"
echo "Built $APP"

for arg in "$@"; do
    case "$arg" in
        --install)
            LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
            INSTALLED="/Applications/Countdown Mini.app"
            pkill -x "Countdown Mini" 2>/dev/null || true
            # The running widget extension would otherwise keep serving the old build.
            pkill -x CountdownMiniWidget 2>/dev/null || true
            rm -rf "$INSTALLED"
            cp -R "$APP" "$INSTALLED"
            # Keep exactly one copy of the app on disk and in LaunchServices. With several copies
            # the system mixes them up and rejects the widget ("Bundle version did not match").
            for copy in "$OUT/Countdown Mini.app" "$PWD/$APP"; do
                "$LSREGISTER" -u "$copy" 2>/dev/null || true
                rm -rf "$copy"
            done
            "$LSREGISTER" -f "$INSTALLED"
            APP="$INSTALLED"
            echo "Installed $APP"
            ;;
        --run) open "$APP" ;;
    esac
done
