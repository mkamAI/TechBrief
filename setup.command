#!/bin/bash
# TechBrief iOS — one-click setup
set -e

cd "$(dirname "$0")"
echo "📦 Checking for xcodegen..."

if ! command -v xcodegen &>/dev/null; then
  echo "🍺 Installing xcodegen via Homebrew..."
  brew install xcodegen
fi

echo "⚙️  Generating Xcode project..."
xcodegen generate

echo "✅ Done! Opening in Xcode..."
open TechBrief.xcodeproj
