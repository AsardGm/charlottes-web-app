#!/bin/sh

# Xcode Cloud CI script - runs after cloning the repository
# This script installs Flutter and generates necessary files for iOS build

set -e

echo "=== Flutter CI Post Clone Script ==="
echo "CI_PRIMARY_REPOSITORY_PATH: $CI_PRIMARY_REPOSITORY_PATH"
echo "CI_WORKSPACE: $CI_WORKSPACE"

# Navigate to the Flutter project root (the repo root IS the Flutter project)
cd "$CI_PRIMARY_REPOSITORY_PATH"

echo "Current directory: $(pwd)"
echo "Contents:"
ls -la

# Check if pubspec.yaml exists (verify we're in Flutter project)
if [ ! -f "pubspec.yaml" ]; then
    echo "ERROR: pubspec.yaml not found. Not in Flutter project root."
    echo "Listing CI_PRIMARY_REPOSITORY_PATH contents:"
    ls -la "$CI_PRIMARY_REPOSITORY_PATH"
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

# Generate iOS files (this creates Generated.xcconfig and other necessary files)
echo "Generating iOS build files..."
flutter build ios --config-only --no-codesign

# Navigate to iOS folder
cd ios

echo "iOS directory contents:"
ls -la

echo "Flutter directory contents:"
ls -la Flutter/

# Install CocoaPods dependencies
echo "Installing CocoaPods dependencies..."
pod install --repo-update

echo "Pods directory check:"
ls -la "Pods/Target Support Files/Pods-Runner/" || echo "Pods directory not found"

echo "=== CI Post Clone Complete ==="
