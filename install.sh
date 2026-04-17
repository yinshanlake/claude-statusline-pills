#!/usr/bin/env bash
# Install script for claude-statusline-pills
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/yinshanlake/claude-statusline-pills/main/install.sh | bash
# or:
#   git clone ... && cd claude-statusline-pills && bash install.sh

set -e

CLAUDE_DIR="$HOME/.claude"
SETTINGS="$CLAUDE_DIR/settings.json"
SCRIPT_DEST="$CLAUDE_DIR/statusline-command.sh"
REPO_RAW="https://raw.githubusercontent.com/yinshanlake/claude-statusline-pills/main"

# ── 1. Detect OS for platform-appropriate guidance ───────────────
case "$(uname -s 2>/dev/null)" in
  Darwin)                    OS="mac"     ;;
  Linux)                     OS="linux"   ;;
  MINGW*|MSYS*|CYGWIN*)      OS="windows" ;;
  *)                         OS="unknown" ;;
esac

# ── 2. Dependency check ──────────────────────────────────────────
missing=()
for cmd in bash jq awk curl; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if [ ${#missing[@]} -gt 0 ]; then
  echo "ERROR: missing required tools: ${missing[*]}"
  echo ""
  echo "Install the missing tools and re-run this script:"
  case "$OS" in
    mac)
      echo "  brew install ${missing[*]}"
      ;;
    linux)
      if command -v apt-get >/dev/null 2>&1; then
        echo "  sudo apt-get install -y ${missing[*]}"
      elif command -v dnf >/dev/null 2>&1; then
        echo "  sudo dnf install -y ${missing[*]}"
      elif command -v pacman >/dev/null 2>&1; then
        echo "  sudo pacman -S ${missing[*]}"
      else
        echo "  (use your distro's package manager to install: ${missing[*]})"
      fi
      ;;
    windows)
      echo "  # In Git Bash / PowerShell:"
      for m in "${missing[@]}"; do
        case "$m" in
          jq)  echo "  winget install jqlang.jq" ;;
          *)   echo "  # ensure $m is in PATH (usually via Git for Windows)" ;;
        esac
      done
      ;;
    *)
      echo "  (use your system's package manager to install: ${missing[*]})"
      ;;
  esac
  exit 1
fi

# ── 2. Ensure ~/.claude exists ───────────────────────────────────
mkdir -p "$CLAUDE_DIR"

# ── 3. Install the statusline script ─────────────────────────────
if [ -f "./statusline-command.sh" ]; then
  cp "./statusline-command.sh" "$SCRIPT_DEST"
  echo "✓ Copied statusline-command.sh from local repo → $SCRIPT_DEST"
else
  echo "Downloading statusline-command.sh from GitHub…"
  curl -fsSL "$REPO_RAW/statusline-command.sh" -o "$SCRIPT_DEST"
  echo "✓ Downloaded → $SCRIPT_DEST"
fi
chmod +x "$SCRIPT_DEST"

# ── 4. Patch settings.json (create if missing, merge if exists) ──
STATUSLINE_JSON='{"statusLine":{"type":"command","command":"bash ~/.claude/statusline-command.sh"}}'

if [ ! -f "$SETTINGS" ]; then
  echo "$STATUSLINE_JSON" | jq '.' > "$SETTINGS"
  echo "✓ Created $SETTINGS"
else
  # Backup existing settings
  cp "$SETTINGS" "${SETTINGS}.bak.$(date +%s)"
  # Merge statusLine block into existing settings (preserves everything else)
  tmp=$(mktemp)
  jq --argjson patch "$STATUSLINE_JSON" '. * $patch' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
  echo "✓ Patched $SETTINGS (backup saved)"
fi

# ── 5. Done ──────────────────────────────────────────────────────
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║  Installation complete.                                    ║"
echo "║                                                            ║"
echo "║  Open a new Claude Code session to see the new statusline. ║"
echo "║  If you already have one running, send any message to      ║"
echo "║  trigger a refresh.                                        ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""
echo "Troubleshooting:"
echo "  • Icons show as '◆' or boxes → install a Nerd Font and set it in your terminal"
echo "  • Colors missing → your terminal needs 24-bit true color support"
echo "  • Effort not updating → see README, Claude Code writes it to ~/.claude/settings.json"
