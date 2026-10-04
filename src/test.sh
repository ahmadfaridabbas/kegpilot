#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
mkdir -p build
xcrun swiftc -swift-version 5 Sources/KegPilot/CommandRunner.swift Sources/KegPilot/InstalledPackage.swift Sources/KegPilot/PackageUpdate.swift Sources/KegPilot/SearchResult.swift Sources/KegPilot/PackageInfo.swift Sources/KegPilot/DownloadProgress.swift Sources/KegPilot/TerminalEmulator.swift Sources/KegPilot/AppUpdate.swift Sources/KegPilot/RecoveryHint.swift Sources/KegPilot/AskpassBroker.swift Tests/RunnerTests.swift -o build/RunnerTests
build/RunnerTests
xcrun swiftc -swift-version 5 Sources/KegPilot/CommandRunner.swift Sources/KegPilot/InstalledPackage.swift Sources/KegPilot/PackageUpdate.swift Sources/KegPilot/SearchResult.swift Sources/KegPilot/PackageInfo.swift Sources/KegPilot/DownloadProgress.swift Sources/KegPilot/TerminalEmulator.swift Sources/KegPilot/AppUpdate.swift Sources/KegPilot/RecoveryHint.swift Sources/KegPilot/AskpassBroker.swift Sources/KegPilot/Theme.swift Sources/KegPilot/BrewModel.swift Tests/UninstallTests.swift -o build/UninstallTests
build/UninstallTests
