#!/bin/bash
# ClaudeProjects Installer

set -e

echo "Installing ClaudeProjects..."

# Create directories
mkdir -p "$HOME/claude-workspace/.claude/scripts"
mkdir -p "/Applications/ClaudeProjects.app/Contents/MacOS"
mkdir -p "/Applications/ClaudeProjects.app/Contents/Resources"

# Copy files
cp scripts/generate-dashboard.sh "$HOME/claude-workspace/.claude/scripts/"
cp app/Contents/Info.plist "/Applications/ClaudeProjects.app/Contents/"
cp app/Contents/MacOS/ClaudeProjects "/Applications/ClaudeProjects.app/Contents/MacOS/"
chmod +x "/Applications/ClaudeProjects.app/Contents/MacOS/ClaudeProjects"

# Copy icon if exists
if [ -f "app/Contents/Resources/AppIcon.icns" ]; then
    cp app/Contents/Resources/AppIcon.icns "/Applications/ClaudeProjects.app/Contents/Resources/"
fi

# Register URL scheme
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -f /Applications/ClaudeProjects.app 2>/dev/null || true

echo ""
echo "Installation complete!"
echo ""
echo "To launch: open /Applications/ClaudeProjects.app"
echo "Or find 'ClaudeProjects' in your Applications folder"
