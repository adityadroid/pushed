# Plan: Update App Icons

## Context
The user wants to use `pushed.png` as the app icon for both `pushed_android` and `pushed_watch`.
`pushed.png` is provided in the root directory.

## Steps

### 1. Android (`pushed_android`)
The Android app uses adaptive icons (`mipmap-anydpi-v26`) pointing to XML vectors. To strictly use the provided PNG, we will remove the adaptive icon configuration and replace the legacy mipmap bitmaps. This ensures the PNG is displayed exactly as is.

- **Action**: Delete `pushed_android/app/src/main/res/mipmap-anydpi-v26`.
- **Action**: For each density bucket, remove existing icons and add resized `pushed.png`:
  - `mipmap-mdpi`: 48x48
  - `mipmap-hdpi`: 72x72
  - `mipmap-xhdpi`: 96x96
  - `mipmap-xxhdpi`: 144x144
  - `mipmap-xxxhdpi`: 192x192
  - Both `ic_launcher.png` and `ic_launcher_round.png` will be created.

### 2. WatchOS (`pushed_watch`)
The WatchOS app uses an Asset Catalog (`Assets.xcassets`). We will update it to use a single 1024x1024 app icon which works for modern Xcode projects.

- **Action**: Resize `pushed.png` to 1024x1024.
- **Action**: Save as `pushed_watch/pushed_watch/Assets.xcassets/AppIcon.appiconset/AppIcon.png`.
- **Action**: Update `Contents.json` to reference this file.

### 3. Validation
- Verify file existence and cleanup.
