# install.ps1 — PowerShell installer for claude-statusline-pills
#
# One-liner (Windows PowerShell 5.1+, PowerShell 7+ on macOS/Linux):
#   irm https://raw.githubusercontent.com/yinshanlake/claude-statusline-pills/main/install.ps1 | iex
#
# Manual:
#   git clone https://github.com/yinshanlake/claude-statusline-pills.git
#   cd claude-statusline-pills
#   powershell -ExecutionPolicy Bypass -File .\install.ps1

$ErrorActionPreference = 'Stop'

$claudeDir  = Join-Path $HOME '.claude'
$settings   = Join-Path $claudeDir 'settings.json'
$scriptDest = Join-Path $claudeDir 'statusline-command.sh'
$repoRaw    = 'https://raw.githubusercontent.com/yinshanlake/claude-statusline-pills/main'

function Test-IsWindows {
    if ($PSVersionTable.PSVersion.Major -ge 6) { return [bool]$IsWindows }
    return $true
}

# ── 1. Ensure ~/.claude exists ───────────────────────────────────
New-Item -ItemType Directory -Force -Path $claudeDir | Out-Null

# ── 2. Download (or copy) statusline-command.sh ──────────────────
$localScript = $null
if ($PSScriptRoot) {
    $candidate = Join-Path $PSScriptRoot 'statusline-command.sh'
    if (Test-Path $candidate) { $localScript = $candidate }
}
if ($localScript) {
    Copy-Item $localScript $scriptDest -Force
    Write-Host "OK copied statusline-command.sh from local repo -> $scriptDest"
} else {
    Write-Host "Downloading statusline-command.sh..."
    Invoke-WebRequest -Uri "$repoRaw/statusline-command.sh" -OutFile $scriptDest -UseBasicParsing
    Write-Host "OK downloaded -> $scriptDest"
}

# ── 3. Runtime dependency hints (statusline-command.sh needs these) ──
$bash = Get-Command bash -ErrorAction SilentlyContinue
if (-not $bash) {
    if (Test-IsWindows) {
        Write-Warning "bash not found on PATH. Install Git for Windows:  winget install Git.Git"
    } else {
        Write-Warning "bash not found on PATH."
    }
} else {
    Write-Host "OK bash detected: $($bash.Source)"
}

foreach ($tool in @('jq','awk','curl')) {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        if (Test-IsWindows) {
            switch ($tool) {
                'jq'   { Write-Warning "jq not found. Install:  winget install jqlang.jq" }
                default { Write-Warning "$tool not found. Usually bundled with Git for Windows." }
            }
        } else {
            Write-Warning "$tool not found. Install via your package manager (e.g. 'brew install $tool')."
        }
    }
}

# ── 4. Patch settings.json ───────────────────────────────────────
$statusLine = [pscustomobject]@{
    type    = 'command'
    command = 'bash ~/.claude/statusline-command.sh'
}

if (Test-Path $settings) {
    $ts = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
    $backup = "$settings.bak.$ts"
    Copy-Item $settings $backup
    $cfg = Get-Content $settings -Raw | ConvertFrom-Json
    if ($cfg.PSObject.Properties.Name -contains 'statusLine') {
        $cfg.statusLine = $statusLine
    } else {
        $cfg | Add-Member -NotePropertyName statusLine -NotePropertyValue $statusLine
    }
    $json = $cfg | ConvertTo-Json -Depth 20
    [System.IO.File]::WriteAllText($settings, $json)
    Write-Host "OK patched $settings (backup: $backup)"
} else {
    $json = [pscustomobject]@{ statusLine = $statusLine } | ConvertTo-Json -Depth 20
    [System.IO.File]::WriteAllText($settings, $json)
    Write-Host "OK created $settings"
}

# ── 5. Done ──────────────────────────────────────────────────────
Write-Host ""
Write-Host "============================================================="
Write-Host "  Installation complete."
Write-Host ""
Write-Host "  Open a new Claude Code session to see the new statusline."
Write-Host "  Or send any message in an existing session to refresh."
Write-Host "============================================================="
Write-Host ""
Write-Host "Troubleshooting:"
Write-Host "  - Icons render as boxes  -> install a Nerd Font in your terminal"
Write-Host "  - No colors              -> terminal needs 24-bit true color (Windows Terminal / iTerm2)"
Write-Host "  - Effort not updating    -> see README; Claude Code writes it to ~/.claude/settings.json"
