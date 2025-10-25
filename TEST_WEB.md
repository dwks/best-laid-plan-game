# Testing on Web (Quick Alternative)

Since Android SDK setup can be complex, you can test the game in a browser first!

## Export for Web

1. In Godot: **Project → Export → Web**
2. Click **Export Project**
3. Save the files to `builds/web/`
4. The output will include an `index.html` file

## Running Locally

### Option 1: Open directly (simple)
```bash
cd builds/web
firefox index.html
# or
chromium index.html
```

### Option 2: Use a local server (recommended)
```bash
cd builds/web
python3 -m http.server 8000
# Then open http://localhost:8000 in your browser
```

## Testing Mobile Behavior

Modern browsers let you test mobile behavior:

### Chrome/Chromium
1. Open Developer Tools (F12)
2. Click the device toggle icon (or Ctrl+Shift+M)
3. Select a device profile (iPhone, Android, etc.)
4. Test touch behavior and screen sizes

### Firefox
1. Open Developer Tools (F12)
2. Click the responsive design mode (Ctrl+Shift+M)
3. Select device dimensions

## Advantages
- No Android SDK needed
- Fast iteration (just refresh the page)
- Easy to share (just send the HTML file)
- Works on any device with a browser

## Limitations
- Some mobile features might not work exactly the same
- File size larger than native apps
- Requires internet connection for initial load

For final testing on actual Android devices, you'll still need to set up the Android SDK.
