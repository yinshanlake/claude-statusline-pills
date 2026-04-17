# Claude Code Statusline — Pills Edition

A polished, premium-feeling status line for [Claude Code](https://claude.com/claude-code) with:

- **Pill-style segments** with matched dark backgrounds + high-contrast foregrounds
- **Powerline chevron transitions** (`▶`) between segments
- **24-bit true color gradient** progress bar for context usage
- **Thinking-effort indicator** — Low / Medium / High / Max with color-coded semantics
- **Session cost, token count, lines changed** — all hidden when zero
- **Universal Unicode symbols** — works with any font (no Nerd Font required)

## Preview

```
❯ my-session ▶ ▸ ~/projects/mimir ▶ ⎇ main ▶ ◉ Opus 4.7 ▶ ⚡ Max ▶ ████▒▒▒▒▒▒ 42% ▶ Σ 142.0k ▶ ◆ $1.37 ▶ Δ +156/-23
```

Each segment has its own background color (deep violet / steel blue / amber / magenta / teal / green) with matched light foreground. See `screenshot.png` in the repo for the actual render.

## Requirements

- `bash` (tested on 5.x)
- `jq` — for JSON parsing
- `awk` — for number formatting
- Terminal with **24-bit true color** support
  - ✅ Windows Terminal, iTerm2, Alacritty, Kitty, WezTerm, GNOME Terminal, Konsole
  - ❌ `cmd.exe`, old PuTTY

## Install

### One-liner

**macOS / Linux / Windows (Git Bash / WSL)** — bash:

```bash
curl -fsSL https://raw.githubusercontent.com/yinshanlake/claude-statusline-pills/main/install.sh | bash
```

**Windows (PowerShell)** — also works on macOS/Linux if you have PowerShell 7:

```powershell
irm https://raw.githubusercontent.com/yinshanlake/claude-statusline-pills/main/install.ps1 | iex
```

> The PowerShell installer writes the same `~/.claude/statusline-command.sh` and patches `~/.claude/settings.json` natively — no `jq` dependency for the install step itself. The statusline script at runtime still needs `bash`, `jq`, and `awk` on PATH (all shipped with Git for Windows).

### Prerequisites

The installer checks for `bash`, `jq`, `awk`, `curl` and shows the right install command for your OS if any is missing. Quick reference:

| Platform | Install prerequisites |
|----------|----------------------|
| **macOS** | `brew install jq` (bash/awk/curl come pre-installed) |
| **Linux (Debian/Ubuntu)** | `sudo apt-get install -y jq` |
| **Linux (Fedora/RHEL)** | `sudo dnf install -y jq` |
| **Linux (Arch)** | `sudo pacman -S jq` |
| **Windows** | Install [Git for Windows](https://git-scm.com/download/win), then `winget install jqlang.jq` |

### Manual install

```bash
git clone https://github.com/yinshanlake/claude-statusline-pills.git
cd claude-statusline-pills
bash install.sh
```

Or with PowerShell:

```powershell
git clone https://github.com/yinshanlake/claude-statusline-pills.git
cd claude-statusline-pills
powershell -ExecutionPolicy Bypass -File .\install.ps1
```

### What the installer does

1. Detects your OS (macOS / Linux / Windows) and verifies dependencies
2. Copies `statusline-command.sh` to `~/.claude/statusline-command.sh`
3. Patches `~/.claude/settings.json` to wire up the `statusLine` hook
   - Existing settings are preserved via `jq` deep-merge
   - A timestamped backup is saved as `settings.json.bak.<timestamp>`
4. Prints next-step instructions

Open a new Claude Code session to see it take effect (or send any message in an existing session to trigger a refresh).

## What it shows

| Segment | When visible | Example |
|---------|-------------|---------|
| **Session name** | If you set one (`claude -n foo` or `/rename foo`) | `❯ my-session` |
| **CWD** | Always | `▸ ~/projects/mimir` |
| **Git branch** | In git repos | `⎇ main` |
| **Model** | Always | `◉ Opus 4.7` |
| **Effort level** | Read from `~/.claude/settings.json` `effortLevel` | `⚡ Max` |
| **Context bar** | When > 0% | `████▒▒▒▒▒▒ 42%` |
| **Tokens** | When > 0 | `Σ 142.0k` |
| **Cost** | When ≥ $0.01 | `◆ $1.37` |
| **Lines changed** | When code was modified | `Δ +156/-23` |

## Effort-level color coding

| Level | Color | Meaning |
|-------|-------|---------|
| `Low` | cool cyan | Minimal thinking |
| `Medium` | warm amber | Balanced |
| `High` | coral red | Deep thinking |
| `Max` | hot magenta | Maximum (Claude Code's `xhigh` internal value) |

> **Note**: Claude Code doesn't pass the current effort level to statusline commands via stdin JSON. This script reads it from `~/.claude/settings.json` — the file Claude Code writes when you use `/config set effortLevel` or select an effort from the `/model` picker. Changes are picked up on the next refresh (~300ms).

## Customization

Edit `~/.claude/statusline-command.sh` directly. Key knobs:

- **Palette** — search for `_BG=` and `_FG=` lines (all using `R G B` space-separated decimal, 0-255)
- **Icons** — search for `ICON_` variables; each uses `printf '\xHH\xHH\xHH'` to emit raw UTF-8 bytes (locale-proof)
- **Bar width** — `bar_width=10` in the context segment
- **CWD truncation** — change the `depth > 3` threshold in the CWD shortening block

## Nerd Font icons (optional upgrade)

If you have a [Nerd Font](https://www.nerdfonts.com/font-downloads) installed, replace the Unicode fallbacks with proper Nerd Font glyphs for a more refined look (folder icon, git branch icon, robot icon, etc.). See `statusline-nerdfont.sh` in the repo for a variant using Nerd Font codepoints.

## Troubleshooting

| Symptom | Cause / Fix |
|---------|-------------|
| All text renders as color blocks but icons look like `◆` diamonds or `▯` boxes | Your terminal font doesn't have the glyph at that codepoint. Install a Nerd Font or stick with this version's universal symbols. |
| Icons show as literal `\uF07B` text | Locale issue — the script already uses `\xHH` raw bytes to avoid this. Re-run `install.sh`. |
| No colors, just text | Your terminal lacks 24-bit color. Windows users: switch to Windows Terminal. Linux: set `TERM=xterm-256color`. |
| Effort level wrong / doesn't update | Make sure you're changing it via `/config set effortLevel <level>` or the `/model` picker — those write to `settings.json`. |
| `jq: error: Invalid escape at line 1` when testing | Use Unix-style paths (`/c/Users/...`) not Windows-style (`C:\Users\...`) when piping test JSON. |

## How it works

Claude Code invokes the configured `statusLine` command on every UI refresh (~300ms), piping a JSON object to stdin with fields like:

```json
{
  "cwd": "/path/to/project",
  "model": {"id": "...", "display_name": "Opus 4.7"},
  "context_window": {"used_percentage": 42, "current_usage": {...}},
  "cost": {"total_cost_usd": 1.37, "total_lines_added": 156, ...},
  "session_name": "optional",
  "transcript_path": "..."
}
```

The script parses this with `jq`, formats each field, and emits ANSI escape sequences to paint pills with 24-bit RGB backgrounds and Powerline-style chevron transitions.

See the Claude Code docs for the full schema: [statusLine reference](https://code.claude.com/docs/en/statusline.md).

## License

MIT — do whatever you want.

## Credits

Inspired by [taste-skill](https://github.com/Leonxlnx/taste-skill)'s emphasis on taste-driven design and the broader Powerline aesthetic. Built iteratively with Claude Code; see the [origin story](https://github.com/yinshanlake/claude-statusline-pills/blob/main/ORIGIN.md) for the debugging journey (locale-dependent `\u` escapes, Write-tool Unicode strip bugs, and more).
