#!/bin/sh

# Xcode Cloud CI script - runs after cloning the repository
# This script installs Flutter and generates necessary files for iOS build

set -e

echo "=== Flutter CI Post Clone Script ==="
echo "CI_PRIMARY_REPOSITORY_PATH: $CI_PRIMARY_REPOSITORY_PATH"
echo "CI_WORKSPACE: $CI_WORKSPACE"
echo "HOME: $HOME"

# Navigate to the Flutter project root (the repo root IS the Flutter project)
cd "$CI_PRIMARY_REPOSITORY_PATH"

echo "Current directory: $(pwd)"
echo "Contents:"
ls -la

# Check if pubspec.yaml exists (verify we're in Flutter project)
if [ ! -f "pubspec.yaml" ]; then
    echo "ERROR: pubspec.yaml not found. Not in Flutter project root."
    exit 1
fi

# Install Flutter
FLUTTER_PATH="$HOME/flutter"

if [ -d "$FLUTTER_PATH" ]; then
    echo "Flutter directory exists, using it..."
else
    echo "Installing Flutter (stable)..."
    git clone https://github.com/flutter/flutter.git --depth 1 -b stable "$FLUTTER_PATH"
fi

export PATH="$PATH:$FLUTTER_PATH/bin"

echo "Flutter version:"
flutter --version

# Disable analytics
flutter config --no-analytics

# Pre-cache iOS artifacts
echo "Precaching iOS artifacts..."
flutter precache --ios

# Get Flutter dependencies
echo "Running flutter pub get..."
flutter pub get

# IMPORTANT: Create .xcode.env.local to tell Xcode where Flutter is
echo "Creating .xcode.env.local for Xcode build phases..."
echo "FLUTTER_ROOT=$FLUTTER_PATH" > ios/.xcode.env.local
cat ios/.xcode.env.local

# Also update the main .xcode.env if it doesn't have the right path
echo "Checking ios/.xcode.env..."
if [ -f "ios/.xcode.env" ]; then
    cat ios/.xcode.env
fi

# Generate iOS files (this creates Generated.xcconfig and other necessary files)
echo "Generating iOS build files..."
flutter build ios --config-only --no-codesign

# Navigate to iOS folder
cd ios

echo "iOS directory contents:"
ls -la

echo "Flutter directory contents:"
ls -la Flutter/

# Verify Generated.xcconfig exists
if [ -f "Flutter/Generated.xcconfig" ]; then
    echo "Generated.xcconfig content:"
    cat Flutter/Generated.xcconfig
else
    echo "WARNING: Generated.xcconfig not found!"
fi

# Install CocoaPods dependencies
echo "Installing CocoaPods dependencies..."
pod install --repo-update

echo "Pods directory check:"
ls -la "Pods/Target Support Files/Pods-Runner/" || echo "Pods directory not found"

echo "=== CI Post Clone Complete ==="
