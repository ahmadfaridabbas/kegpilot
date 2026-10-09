#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build/KegPilot.app/Contents/MacOS
xcrun swiftc -swift-version 5 -O -target arm64-apple-macosx13.0 -parse-as-library Sources/KegPilot/*.swift -o build/KegPilot.app/Contents/MacOS/KegPilot
cp Info.plist build/KegPilot.app/Contents/Info.plist
mkdir -p build/KegPilot.app/Contents/Resources
cp Resources/AppIcon.icns Resources/AppIcon.png Resources/MenuBarTemplate.png Resources/MenuBarTemplate@2x.png Resources/AppIconLight.png Resources/AppIconDark.png build/KegPilot.app/Contents/Resources/
codesign --force --sign - build/KegPilot.app
printf 'Built build/KegPilot.app\n'
