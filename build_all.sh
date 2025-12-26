#!/bin/bash
set -e

echo "Building for Linux..."
flutter build linux

echo "Building for Web..."
flutter build web

echo "Building for Android (APK)..."
flutter build apk

echo "Building for Android (App Bundle)..."
flutter build appbundle

echo "Building for Windows..."
flutter build windows

echo "All builds completed successfully."
