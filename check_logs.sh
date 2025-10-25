#!/bin/bash
# Check Android logs for Godot output

echo "Connecting to Android device..."
adb devices

echo ""
echo "Checking for Godot logs..."
adb logcat -d | grep -i "godot\|world map\|error" | tail -50

echo ""
echo "Live logcat (Ctrl+C to stop)..."
adb logcat -c  # Clear logs
adb logcat | grep -i "godot\|world map"
