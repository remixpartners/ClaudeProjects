# ClaudeProjects

A macOS dashboard app for tracking all your Claude Code sessions across directories.

![ClaudeProjects Screenshot](screenshot.png)

## Features

- **Session Tracker**: View all Claude Code sessions organized by project
- **Cross-Directory**: Shows sessions from ANY directory, not just your workspace
- **Session Counter**: See how many sessions each project has
- **Favorites & Renaming**: Star important sessions and rename them for easy reference
- **Plugins & Skills**: View which plugins and skills are installed per project
- **Quick Commands**: Copy resume commands with one click

## Installation

```bash
# Clone the repo
git clone https://github.com/justinmassa/ClaudeProjects.git
cd ClaudeProjects

# Run the installer
./install.sh
```

## Usage

1. Click the **ClaudeProjects** app in your Applications folder (or Dock)
2. The dashboard opens in your browser showing all sessions
3. Click any session's **Copy** button to copy the resume command
4. Paste in Terminal to resume that session

## How It Works

ClaudeProjects scans `~/.claude/projects/` for all session files and generates an HTML dashboard. The app is a simple launcher that runs `generate-dashboard.sh` and opens the result.

## Project Structure

```
ClaudeProjects/
├── scripts/
│   └── generate-dashboard.sh   # Main dashboard generator
├── app/
│   └── Contents/               # macOS .app bundle contents
├── install.sh                  # Installer script
└── README.md
```

## Requirements

- macOS 10.13+
- Claude Code CLI installed
- A browser (Safari, Chrome, etc.)

## License

MIT

---

Built with Claude Code
