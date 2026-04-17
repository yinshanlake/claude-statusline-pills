---
name: claude-statusline-pills
description: Install the pill-style Claude Code statusline with effort-level indicator, context progress bar, cost, tokens, and code-change tracking. Use when the user wants a more polished or visually rich status line.
---

# Install Claude-Statusline-Pills

A polished pill-style statusline for Claude Code — pills with dark backgrounds + light foregrounds, Powerline chevrons, true-color gradient bar, and a thinking-effort indicator.

## What it replaces

The default Claude Code statusline or any existing custom one configured at `~/.claude/settings.json` under the `statusLine` key.

## Steps

1. **Check dependencies** — `bash`, `jq`, `awk` must be in PATH. If `jq` is missing on Windows, suggest `winget install jqlang.jq`. On macOS: `brew install jq`.

2. **Ensure `~/.claude/` exists** — `mkdir -p ~/.claude`

3. **Install the script** — download from the public repo:
   ```bash
   curl -fsSL https://raw.githubusercontent.com/yinshanlake/claude-statusline-pills/main/statusline-command.sh \
     -o ~/.claude/statusline-command.sh
   chmod +x ~/.claude/statusline-command.sh
   ```
   OR if the repo is cloned locally: `cp statusline-command.sh ~/.claude/`

4. **Patch `~/.claude/settings.json`** — *critically*, preserve existing settings. Use `jq` to merge:
   ```bash
   tmp=$(mktemp)
   jq '. * {"statusLine":{"type":"command","command":"bash ~/.claude/statusline-command.sh"}}' \
     ~/.claude/settings.json > "$tmp" && mv "$tmp" ~/.claude/settings.json
   ```
   If `~/.claude/settings.json` doesn't exist, create it with just the `statusLine` object.
   Always back up first: `cp ~/.claude/settings.json ~/.claude/settings.json.bak.$(date +%s)`

5. **Verify** — pipe a fake JSON into the script to confirm it renders:
   ```bash
   echo '{"cwd":"/tmp","model":{"display_name":"Test"},"context_window":{"used_percentage":50,"current_usage":{"input_tokens":1000}}}' \
     | bash ~/.claude/statusline-command.sh; echo
   ```
   The output should contain ANSI escape codes (`[38;2;...m`) and readable pill content.

6. **Tell the user**: open a new Claude Code session (or send any message to trigger a refresh) to see it. If the icons show as `◆` or boxes, they need a Nerd Font — but the default Unicode symbols should render in any modern terminal.

## Customization after install

Point the user at `~/.claude/statusline-command.sh` directly. Key knobs:
- Palette: `*_BG=` and `*_FG=` variables (format: `"R G B"` decimal)
- Icons: `ICON_*` variables using `printf '\xHH'` raw UTF-8 bytes
- Bar width: `bar_width=10`

## Uninstall

Remove the `statusLine` key from `~/.claude/settings.json` and delete `~/.claude/statusline-command.sh`.
