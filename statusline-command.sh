#!/usr/bin/env bash
# ╔══════════════════════════════════════════════════════════════════╗
# ║  Claude Code Status Line v3 — Pill design, Powerline, Premium  ║
# ╚══════════════════════════════════════════════════════════════════╝
# Requires: jq, Nerd Font, terminal with 24-bit true color support.
# Design: each segment is a colored "pill" with bg+fg; Powerline
# chevrons () create smooth bg→bg transitions between pills.

input=$(cat)

# ── Extract fields ───────────────────────────────────────────────
cwd=$(echo "$input"           | jq -r '.workspace.current_dir // .cwd // ""')
model=$(echo "$input"         | jq -r '.model.display_name // ""')
used_pct=$(echo "$input"      | jq -r '.context_window.used_percentage // empty')
session_name=$(echo "$input"  | jq -r '.session_name // empty')
cost_usd=$(echo "$input"      | jq -r '.cost.total_cost_usd // empty')
lines_add=$(echo "$input"     | jq -r '.cost.total_lines_added // empty')
lines_del=$(echo "$input"     | jq -r '.cost.total_lines_removed // empty')
total_tokens=$(echo "$input"  | jq -r '
  (.context_window.current_usage.input_tokens  // 0) +
  (.context_window.current_usage.cache_read_input_tokens // 0) +
  (.context_window.current_usage.output_tokens // 0)
  | if . == 0 then empty else . end
')

# ── Read effort level (from settings — not in stdin JSON) ────────
effort=""
if command -v jq >/dev/null 2>&1; then
  transcript=$(echo "$input" | jq -r '.transcript_path // empty')
  if [ -n "$transcript" ]; then
    proj_settings="$(dirname "$transcript")/settings.json"
    [ -f "$proj_settings" ] && effort=$(jq -r '.effortLevel // empty' "$proj_settings" 2>/dev/null)
  fi
  [ -z "$effort" ] && [ -f "$HOME/.claude/settings.local.json" ] && \
    effort=$(jq -r '.effortLevel // empty' "$HOME/.claude/settings.local.json" 2>/dev/null)
  [ -z "$effort" ] && [ -f "$HOME/.claude/settings.json" ] && \
    effort=$(jq -r '.effortLevel // empty' "$HOME/.claude/settings.json" 2>/dev/null)
fi

# ── Shorten CWD ──────────────────────────────────────────────────
home_dir="$HOME"
if [ -n "$home_dir" ] && [[ "$cwd" == "$home_dir"* ]]; then
  cwd="~${cwd#$home_dir}"
fi
if [[ "$cwd" != "~" ]]; then
  depth=$(echo "$cwd" | tr -cd '/' | wc -c)
  if [ "$depth" -gt 3 ]; then
    cwd="…/$(echo "$cwd" | rev | cut -d'/' -f1-2 | rev)"
  fi
fi

# ── Git branch ───────────────────────────────────────────────────
git_branch=""
if command -v git >/dev/null 2>&1; then
  raw_cwd=$(echo "$input" | jq -r '.workspace.current_dir // .cwd // ""')
  if [ -n "$raw_cwd" ] && [ -d "$raw_cwd" ]; then
    git_branch=$(GIT_OPTIONAL_LOCKS=0 git -C "$raw_cwd" rev-parse --abbrev-ref HEAD 2>/dev/null)
  else
    git_branch=$(GIT_OPTIONAL_LOCKS=0 git rev-parse --abbrev-ref HEAD 2>/dev/null)
  fi
fi

# ── Token display ────────────────────────────────────────────────
token_display=""
if [ -n "$total_tokens" ] && [ "$total_tokens" -gt 0 ] 2>/dev/null; then
  if [ "$total_tokens" -ge 1000000 ]; then
    token_display="$(awk "BEGIN { printf \"%.1fM\", $total_tokens/1000000 }")"
  elif [ "$total_tokens" -ge 1000 ]; then
    token_display="$(awk "BEGIN { printf \"%.1fk\", $total_tokens/1000 }")"
  else
    token_display="$total_tokens"
  fi
fi

# ── Cost display ─────────────────────────────────────────────────
cost_display=""
if [ -n "$cost_usd" ] && [ "$cost_usd" != "0" ]; then
  cost_cents=$(awk "BEGIN { printf \"%d\", $cost_usd * 100 }")
  if [ "$cost_cents" -gt 0 ] 2>/dev/null; then
    cost_display=$(awk "BEGIN { printf \"\$%.2f\", $cost_usd }")
  fi
fi

# ── Lines changed ────────────────────────────────────────────────
lines_display=""
lines_add=${lines_add:-0}
lines_del=${lines_del:-0}
if [ "$lines_add" -gt 0 ] 2>/dev/null && [ "$lines_del" -gt 0 ] 2>/dev/null; then
  lines_display="+${lines_add}/-${lines_del}"
elif [ "$lines_add" -gt 0 ] 2>/dev/null; then
  lines_display="+${lines_add}"
elif [ "$lines_del" -gt 0 ] 2>/dev/null; then
  lines_display="-${lines_del}"
fi

# ══════════════════════════════════════════════════════════════════
#  Professional Palette (Radix/Tailwind-inspired dark pills)
# ══════════════════════════════════════════════════════════════════
reset=$'\033[0m'
bold=$'\033[1m'

# True color helpers
fg() { printf '\033[38;2;%d;%d;%dm' "$1" "$2" "$3"; }
bg() { printf '\033[48;2;%d;%d;%dm' "$1" "$2" "$3"; }

# Pill palette — each segment has matched bg (dark, saturated) + fg (light, high-contrast)
# Format: "R G B" for splitting with read

# Session (deep violet)
SESS_BG="56 44 82";      SESS_FG="220 200 245"
# CWD (deep steel blue)
CWD_BG="34 52 82";       CWD_FG="170 210 245"
# Git (slate blue-grey)
GIT_BG="46 58 74";       GIT_FG="180 200 225"
# Model (deep amber)
MOD_BG="72 52 32";       MOD_FG="255 215 165"
# Effort variants
EFF_LOW_BG="26 68 80";   EFF_LOW_FG="130 220 240"
EFF_MED_BG="78 58 22";   EFF_MED_FG="255 220 130"
EFF_HIGH_BG="82 36 36";  EFF_HIGH_FG="255 155 130"
EFF_MAX_BG="80 30 62";   EFF_MAX_FG="255 150 215"
# Context bar
CTX_BG="30 44 54"
# Tokens (deep teal)
TOK_BG="28 58 56";       TOK_FG="150 230 215"
# Cost (deep forest green)
COST_BG="32 58 40";      COST_FG="175 230 175"
# Lines (neutral slate)
LINES_BG="42 44 56";     LINES_FG="210 215 225"

# ── Icons — universal BMP symbols, no Nerd Font required.
# Raw UTF-8 bytes via printf \xHH for locale-proof rendering.
# Picked from Geometric Shapes / Misc Symbols / Greek blocks that
# every modern monospace font supports (DejaVu, Cascadia, Consolas…).
SEP_RIGHT=$(printf '\xE2\x96\xB6')                   # U+25B6 ▶ black right triangle
ICON_SESSION=$(printf '\xE2\x9D\xAF ')               # U+276F ❯ heavy right angle
ICON_FOLDER=$(printf '\xE2\x96\xB8 ')                # U+25B8 ▸ small right triangle
ICON_GIT=$(printf '\xE2\x8E\x87 ')                   # U+2387 ⎇ alternative key
ICON_MODEL=$(printf '\xE2\x97\x89 ')                 # U+25C9 ◉ fisheye
ICON_EFFORT=$(printf '\xE2\x9A\xA1 ')                # U+26A1 ⚡ lightning
ICON_TOKENS=$(printf '\xCE\xA3 ')                    # U+03A3 Σ greek sigma
ICON_COST=$(printf '\xE2\x97\x86 ')                  # U+25C6 ◆ black diamond
ICON_LINES=$(printf '\xCE\x94 ')                     # U+0394 Δ greek delta

# ── Segment collection (parallel arrays) ─────────────────────────
seg_bgs=()
seg_contents=()

# Helper: push a pill — args: bg_rgb(3 space-separated), fg_rgb, icon, text
push_pill() {
  local bg_rgb="$1" fg_rgb="$2" icon="$3" text="$4"
  [ -z "$text" ] && return
  read -r br bg_ bb <<< "$bg_rgb"
  read -r fr fg_ fb <<< "$fg_rgb"
  local content
  content="$(bg $br $bg_ $bb)$(fg $fr $fg_ $fb) ${icon}${text} ${reset}"
  seg_bgs+=("$bg_rgb")
  seg_contents+=("$content")
}

# ── Effort resolution ────────────────────────────────────────────
eff_bg="" eff_fg="" eff_text=""
if [ -n "$effort" ]; then
  case "$effort" in
    low)         eff_bg="$EFF_LOW_BG";  eff_fg="$EFF_LOW_FG";  eff_text="Low"    ;;
    medium)      eff_bg="$EFF_MED_BG";  eff_fg="$EFF_MED_FG";  eff_text="Medium" ;;
    high)        eff_bg="$EFF_HIGH_BG"; eff_fg="$EFF_HIGH_FG"; eff_text="High"   ;;
    xhigh|max)   eff_bg="$EFF_MAX_BG";  eff_fg="$EFF_MAX_FG";  eff_text="Max"    ;;
    *)           eff_bg="$EFF_MED_BG";  eff_fg="$EFF_MED_FG"
                 eff_text="$(echo "$effort" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')" ;;
  esac
fi

# ── Build pills in order ────────────────────────────────────────
[ -n "$session_name" ]  && push_pill "$SESS_BG" "$SESS_FG" "$ICON_SESSION" "$session_name"
[ -n "$cwd" ]           && push_pill "$CWD_BG"  "$CWD_FG"  "$ICON_FOLDER"  "$cwd"
[ -n "$git_branch" ]    && push_pill "$GIT_BG"  "$GIT_FG"  "$ICON_GIT"     "$git_branch"

# Model + effort share a single pill when both exist (visually grouped)
if [ -n "$model" ]; then
  read -r mbr mbg_ mbb <<< "$MOD_BG"
  read -r mfr mfg_ mfb <<< "$MOD_FG"
  model_content="$(bg $mbr $mbg_ $mbb)$(fg $mfr $mfg_ $mfb) ${ICON_MODEL}${model} ${reset}"
  seg_bgs+=("$MOD_BG")
  seg_contents+=("$model_content")

  if [ -n "$eff_text" ]; then
    read -r ebr ebg_ ebb <<< "$eff_bg"
    read -r efr efg_ efb <<< "$eff_fg"
    # Transition chevron from model bg → effort bg
    trans="$(fg $mbr $mbg_ $mbb)$(bg $ebr $ebg_ $ebb)${SEP_RIGHT}${reset}"
    eff_pill="$(bg $ebr $ebg_ $ebb)$(fg $efr $efg_ $efb) ${ICON_EFFORT}${eff_text} ${reset}"
    seg_bgs+=("$eff_bg")
    # Prepend transition to the effort pill (so next segment still chevrons from effort bg)
    seg_contents+=("${trans}${eff_pill}")
  fi
fi

# Context bar as a pill with inline gradient fill
if [ -n "$used_pct" ]; then
  used_int=${used_pct%.*}
  [ -z "$used_int" ] && used_int=0

  read -r cbr cbg_ cbb <<< "$CTX_BG"

  # Adaptive fg color for percentage text
  if [ "$used_int" -ge 80 ] 2>/dev/null; then
    pct_fg_rgb="240 120 120"
  elif [ "$used_int" -ge 50 ] 2>/dev/null; then
    pct_fg_rgb="240 210 110"
  else
    pct_fg_rgb="140 220 170"
  fi
  read -r pfr pfg_ pfb <<< "$pct_fg_rgb"

  # Build gradient bar (10 chars wide for compactness)
  bar_width=10
  filled=$(( used_int * bar_width / 100 ))
  [ "$filled" -gt "$bar_width" ] && filled=$bar_width
  empty=$(( bar_width - filled ))

  bar="$(bg $cbr $cbg_ $cbb)"
  for ((i=0; i<filled; i++)); do
    pos=$(( i * 100 / bar_width ))
    if [ "$pos" -lt 50 ]; then
      t=$(( pos * 2 ))
      r=$(( 120 + (240 - 120) * t / 100 ))
      g=210
      b=$(( 150 + (100 - 150) * t / 100 ))
    else
      t=$(( (pos - 50) * 2 ))
      r=240
      g=$(( 210 + (120 - 210) * t / 100 ))
      b=$(( 100 + (110 - 100) * t / 100 ))
    fi
    bar+="$(fg $r $g $b)█"
  done
  for ((i=0; i<empty; i++)); do
    bar+="$(fg 60 70 82)░"
  done

  pct_txt="$(printf '%3d%%' "$used_int")"
  ctx_pill="$(bg $cbr $cbg_ $cbb)  ${bar}$(bg $cbr $cbg_ $cbb) $(fg $pfr $pfg_ $pfb)${pct_txt} ${reset}"
  seg_bgs+=("$CTX_BG")
  seg_contents+=("$ctx_pill")
fi

[ -n "$token_display" ] && push_pill "$TOK_BG"   "$TOK_FG"   "$ICON_TOKENS" "$token_display"
[ -n "$cost_display" ]  && push_pill "$COST_BG"  "$COST_FG"  "$ICON_COST"   "$cost_display"

# Lines pill needs inline +/- coloring
if [ -n "$lines_display" ]; then
  read -r lbr lbg_ lbb <<< "$LINES_BG"
  read -r lfr lfg_ lfb <<< "$LINES_FG"
  green="$(fg 160 230 160)"
  red="$(fg 240 140 140)"
  neutral="$(fg $lfr $lfg_ $lfb)"
  # Replace +N / -N with colored variants
  colored=$(echo "$lines_display" | sed \
    -e "s/+\([0-9]*\)/${green}+\1${neutral}/g" \
    -e "s/-\([0-9]*\)/${red}-\1${neutral}/g")
  lines_pill="$(bg $lbr $lbg_ $lbb)${neutral} ${ICON_LINES}${colored} ${reset}"
  seg_bgs+=("$LINES_BG")
  seg_contents+=("$lines_pill")
fi

# ══════════════════════════════════════════════════════════════════
#  Render with Powerline transitions
# ══════════════════════════════════════════════════════════════════
out=""
prev_bg=""

for ((i=0; i<${#seg_contents[@]}; i++)); do
  cur_bg="${seg_bgs[$i]}"
  cur_content="${seg_contents[$i]}"

  # Skip transition if this segment already starts with one (model→effort case)
  # Heuristic: if the first visible char of content is the chevron, don't add another
  if [ -n "$prev_bg" ] && [ "$prev_bg" != "$cur_bg" ]; then
    # Model→effort transition is embedded inside the effort content, so
    # only emit a standalone transition if the content doesn't already have one.
    # We detect this via a sentinel: effort segment's content starts with $(fg ...)$(bg ...).
    # Simpler: always emit transition for non-effort segments.
    if [[ "$cur_content" != *"${SEP_RIGHT}"* ]] || [ "$i" -eq 0 ]; then
      read -r pr pg_ pb <<< "$prev_bg"
      read -r nr ng_ nb <<< "$cur_bg"
      out+="$(fg $pr $pg_ $pb)$(bg $nr $ng_ $nb)${SEP_RIGHT}${reset}"
    else
      # Content already embeds its own transition — still need to bridge prev_bg → embedded-first-bg
      # The embedded chevron uses model_bg → effort_bg. We need prev_bg → model_bg... wait no,
      # effort is ALWAYS preceded by model in our order, so prev_bg == MOD_BG here. Skip.
      :
    fi
  fi

  out+="$cur_content"
  prev_bg="$cur_bg"
done

# Right edge chevron (last pill → terminal default)
if [ -n "$prev_bg" ]; then
  read -r pr pg_ pb <<< "$prev_bg"
  out+="$(fg $pr $pg_ $pb)${SEP_RIGHT}${reset}"
fi

printf '%s' "$out"
