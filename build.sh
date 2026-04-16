#!/bin/bash

PLATFORM=$1

if [ -z "$PLATFORM" ]; then
    echo "Usage: ./build.sh [apk|ios|macos|all]"
    echo "Example: ./build.sh apk"
    exit 1
fi

echo ""
echo "=========================================="
echo "[1/4] Cleaning Project..."
echo "=========================================="
flutter clean

echo ""
echo "=========================================="
echo "[2/4] Getting Dependencies..."
echo "=========================================="
flutter pub get

echo ""
echo "=========================================="
echo "[3/4] Generating Launcher Icons..."
echo "=========================================="
dart run flutter_launcher_icons

echo ""
echo "=========================================="
echo "[4/4] Building Application..."
echo "=========================================="

case $PLATFORM in
    apk)
        echo "Building Android APK..."
        flutter build apk --release
        ;;
    ios)
        echo "Building iOS App..."
        flutter build ios --release --no-codesign
        ;;
    macos)
        echo "Building macOS Desktop..."
        flutter build macos --release
        ;;
    all)
        echo "Building Android APK..."
        flutter build apk --release
        if [[ "$OSTYPE" == "darwin"* ]]; then
            echo "Building iOS App..."
            flutter build ios --release --no-codesign
            echo "Building macOS Desktop..."
            flutter build macos --release
        fi
        ;;
    *)
        echo "Unknown platform: $PLATFORM"
        echo "Supported: apk, ios, macos, all"
        exit 1
        ;;
esac

echo ""
echo "=========================================="
echo "Build Process Completed Successfully!"
echo "=========================================="
