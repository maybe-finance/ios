# Font Setup Instructions

The Geist fonts are not loading because they're not included in the app bundle's resources. This project uses Xcode's newer folder reference format (`PBXFileSystemSynchronizedRootGroup`), which requires explicit inclusion of resource files.

## Steps to Fix Font Loading:

### Option 1: Using Xcode GUI (Recommended)

1. Open `Maybe.xcodeproj` in Xcode
2. Select the "Maybe" target in the project navigator
3. Go to the "Build Phases" tab
4. Expand "Copy Bundle Resources"
5. Click the "+" button at the bottom
6. Navigate to `Maybe/Resources/Fonts/`
7. Select all `.otf` files (you can cmd+click to select multiple)
8. Click "Add"

The fonts should now appear in the Copy Bundle Resources list.

### Option 2: Add Folder Reference

1. In Xcode, right-click on the "Maybe" folder in the project navigator
2. Select "Add Files to 'Maybe'..."
3. Navigate to the `Resources` folder
4. Select the `Fonts` folder
5. Important: Check "Create folder references" (not "Create groups")
6. Make sure "Maybe" target is checked
7. Click "Add"

### Option 3: Modify Build Settings

If the above doesn't work, you may need to:

1. Select the project in Xcode
2. Select the "Maybe" target
3. Go to "Build Settings"
4. Search for "Resources"
5. Under "Copy Bundle Resources", ensure the font files are listed

## Verification

After adding the fonts, you can verify they're working by:

1. Building and running the app
2. The `FontTestView.swift` and `FontDebugView.swift` files can help debug font loading
3. Check the built app bundle (right-click on .app in Xcode's Products folder → Show in Finder → right-click → Show Package Contents) to ensure fonts are in the Resources folder

## Info.plist Configuration

The `Info.plist` has been updated to use the correct font file paths (without the `Fonts/` prefix). The font files should be copied directly to the app bundle's Resources folder.

## Troubleshooting

If fonts still don't load:

1. Clean build folder (Cmd+Shift+K)
2. Delete derived data
3. Ensure font file names in Info.plist exactly match the actual file names (case-sensitive)
4. Check Console.app for any font-related error messages when running the app