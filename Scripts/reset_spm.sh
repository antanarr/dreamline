#!/bin/bash
# Reset Swift Package Manager caches to fix dependency graph errors

set -e

echo "🧹 Cleaning SPM caches..."

# Close Xcode if running
osascript -e 'quit app "Xcode"' 2>/dev/null || true
sleep 2

# Remove all SPM-related caches
rm -rf ~/Library/Developer/Xcode/DerivedData/Dreamline-*
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf ~/Library/org.swift.swiftpm
rm -rf .build
rm -rf DerivedData

# Clean workspace state
rm -rf ~/Library/Developer/Xcode/DerivedData/*/SourcePackages/workspace-state.json

echo "✅ Caches cleared"

# Resolve packages
echo "📦 Resolving packages..."
xcodebuild -project Dreamline.xcodeproj -scheme Dreamline -resolvePackageDependencies

echo "🎉 Done! Now open Xcode and build (⌘B)"

