# Installing on Android

## Prerequisites
1. Enable Developer Mode on your Android device
2. Enable USB Debugging in Developer Options
3. Have ADB installed (Android Debug Bridge)

## Quick Install

### Using ADB (recommended)
```bash
# Connect your phone via USB
adb devices  # Verify device is connected

# Install the signed APK
adb install builds/android/TheBestLaidSingularityPlan-signed.apk
```

### Manual Install
1. Copy `builds/android/TheBestLaidSingularityPlan.apk` to your phone
2. Open it from a file manager on your device
3. Allow installation from unknown sources if prompted
4. Install and open the app

## Testing Tips
- Test on different screen sizes and orientations
- Check touch/mouse input works properly
- Verify city buttons are clickable
- Check that map scaling works correctly
- Test info panel visibility

## Troubleshooting
- If installation fails: Check USB debugging is enabled
- If app crashes: Check logcat with `adb logcat | grep -i godot`
- If buttons don't work: Check touch input emulation in project settings
