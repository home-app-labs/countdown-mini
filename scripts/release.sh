#!/bin/bash
# Builds the downloadable files for the version in VERSION:
#   dist/Countdown-Mini.pkg   an installer that puts the app into /Applications
#   dist/Countdown-Mini.zip   the bare app, for people who prefer to move it themselves
# Pass --publish to also tag the commit and create the GitHub release with both files attached.
set -euo pipefail
cd "$(dirname "$0")/.."

VERSION="$(cat VERSION)"
APP="build/Countdown Mini.app"
DIST="dist"

UNIVERSAL=1 ./build.sh

rm -rf "$DIST"
mkdir -p "$DIST"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

# The installer payload: just the app, always installed to /Applications.
mkdir "$WORK/root"
cp -R "$APP" "$WORK/root/"
pkgbuild --analyze --root "$WORK/root" "$WORK/component.plist" >/dev/null
# Without this the installer would update a copy of the app found anywhere else on the disk.
/usr/libexec/PlistBuddy -c "Set :0:BundleIsRelocatable false" "$WORK/component.plist"
pkgbuild --root "$WORK/root" --component-plist "$WORK/component.plist" \
    --identifier local.countdownmini.pkg --version "$VERSION" --install-location /Applications \
    --scripts scripts/pkg "$WORK/app.pkg" >/dev/null

cat > "$WORK/distribution.xml" <<XML
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="2">
    <title>Countdown Mini</title>
    <welcome file="welcome.html" mime-type="text/html"/>
    <options customize="never" require-scripts="false" hostArchitectures="arm64,x86_64"/>
    <domains enable_localSystem="true"/>
    <volume-check><allowed-os-versions><os-version min="14.0"/></allowed-os-versions></volume-check>
    <choices-outline><line choice="default"/></choices-outline>
    <choice id="default" title="Countdown Mini"><pkg-ref id="local.countdownmini.pkg"/></choice>
    <pkg-ref id="local.countdownmini.pkg" version="$VERSION">app.pkg</pkg-ref>
</installer-gui-script>
XML
mkdir "$WORK/resources"
cat > "$WORK/resources/welcome.html" <<HTML
<html><body style="font-family: -apple-system, sans-serif; font-size: 13px;">
<p><b>Countdown Mini $VERSION</b></p>
<p>Desktop widgets that count down the days to your events.</p>
<p>This installer copies Countdown Mini to your Applications folder and opens it. Nothing else is installed.</p>
<p>Free and open source: github.com/home-app-labs/countdown-mini</p>
</body></html>
HTML
productbuild --distribution "$WORK/distribution.xml" --package-path "$WORK" \
    --resources "$WORK/resources" "$DIST/Countdown-Mini.pkg" >/dev/null

ditto -c -k --keepParent "$APP" "$DIST/Countdown-Mini.zip"

( cd "$DIST" && shasum -a 256 Countdown-Mini.pkg Countdown-Mini.zip > SHA256SUMS.txt )
# Leave one copy of the app on this Mac: the installed one. A second copy makes the system
# mix the two up and reject the widget.
LSREGISTER=/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister
for copy in "$PWD/$APP" "$PWD/.build/xcode/out/Countdown Mini.app"; do
    "$LSREGISTER" -u "$copy" >/dev/null 2>&1 || true
    rm -rf "$copy"
done
echo "Built version $VERSION:"
ls -lh "$DIST"

for arg in "$@"; do
    if [ "$arg" = "--publish" ]; then
        if [ -n "$(git status --porcelain)" ]; then echo "Commit your changes first." >&2; exit 1; fi
        git tag "v$VERSION"
        git push origin HEAD "v$VERSION"
        gh release create "v$VERSION" "$DIST/Countdown-Mini.pkg" "$DIST/Countdown-Mini.zip" "$DIST/SHA256SUMS.txt" \
            --title "Countdown Mini $VERSION" --notes-file "release-notes/$VERSION.md"
    fi
done
