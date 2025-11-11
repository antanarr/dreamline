# Fix Swift Package Manager Cache Issue

## Problem
```
Could not compute dependency graph: unable to load transferred PIF:
The workspace contains multiple references with the same GUID
'PACKAGE:1WQ3KYH1L6AO7AKNUT613GN9XT05CXQ03::MAINGROUP'
```

## Root Cause
Swift Package Manager cache corruption (common after package updates or Xcode version changes).

## Solution

Run these commands in Terminal:

```bash
cd /Users/vidau/Desktop/Dreamline

# 1. Clean derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/Dreamline-*

# 2. Clean SPM caches
rm -rf ~/Library/Caches/org.swift.swiftpm
rm -rf .build

# 3. Reset package cache in project
rm -rf ~/Library/Developer/Xcode/DerivedData/*/SourcePackages

# 4. Resolve packages fresh
xcodebuild -project Dreamline.xcodeproj -scheme Dreamline -resolvePackageDependencies

# 5. Build
xcodebuild -project Dreamline.xcodeproj -scheme Dreamline -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 16' build
```

## Alternative: Use Xcode GUI
1. **File → Packages → Reset Package Caches**
2. **Product → Clean Build Folder** (⇧⌘K)
3. **Product → Build** (⌘B)

## Verification
Build should succeed with only benign AppIntents warnings:
```
** BUILD SUCCEEDED **
```

The `appintentsnltrainingprocessor` errors about `extract.actionsdata` are **normal and can be ignored**.

## Why This Happened
- Package dependency graph got corrupted (likely after xcodegen regenerated the project)
- Multiple packages had conflicting cached state
- Common issue with Firebase SDK's complex dependency tree

## Prevention
- Run `xcodebuild -resolvePackageDependencies` after any `xcodegen generate`
- Periodically clean SPM caches: `rm -rf ~/Library/Caches/org.swift.swiftpm`

