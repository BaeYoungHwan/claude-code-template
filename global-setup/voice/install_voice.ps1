# global-setup/voice/install_voice.ps1
# Voice Input 전체 설치 — 멱등(idempotent), 몇 번 실행해도 동일한 결과
# 기존 ~/.claude/settings.json 과 context-bar.sh 을 덮어쓰지 않고 병합함
#
# 사용법: powershell -ExecutionPolicy Bypass -File global-setup/voice/install_voice.ps1

$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$ScriptDir   = $PSScriptRoot
$ClaudeDir   = Join-Path $HOME ".claude"
$VoiceDir    = Join-Path $ClaudeDir "voice"
$HooksDir    = Join-Path $ClaudeDir "hooks"
$SettingsPath = Join-Path $ClaudeDir "settings.json"
$ContextBar  = Join-Path $HooksDir "context-bar.sh"

Write-Host "=== Voice Input 설치 (멱등) ===" -ForegroundColor Cyan
Write-Host ""

# ── 1. Python 확인 ──────────────────────────────────────────────────────────────
Write-Host "[1/5] Python 버전 확인..." -ForegroundColor White
$python = $null
foreach ($cmd in @("python", "python3")) {
    try {
        $ver = & $cmd --version 2>&1
        if ($LASTEXITCODE -eq 0) { $python = $cmd; break }
    } catch {}
}
if (-not $python) {
    Write-Host "  ✗ Python을 찾을 수 없습니다. Python 3.8+ 설치 후 재실행하세요." -ForegroundColor Red
    exit 1
}
$verStr = (& $python --version 2>&1) -replace "Python ", ""
$parts  = $verStr.Split(".")
if ([int]$parts[0] -lt 3 -or ([int]$parts[0] -eq 3 -and [int]$parts[1] -lt 8)) {
    Write-Host "  ✗ Python 3.8 이상 필요. 현재: $verStr" -ForegroundColor Red; exit 1
}
Write-Host "  ✓ $verStr ($python)" -ForegroundColor Green

# ── 2. pip 패키지 설치 ──────────────────────────────────────────────────────────
Write-Host ""
Write-Host "[2/5] 패키지 설치..." -ForegroundColor White
$req = Join-Path $ScriptDir "requirements.txt"
& $python -m pip install --quiet -r $req
if ($LASTEXITCODE -ne 0) { Write-Host "  ✗ pip install 실패" -ForegroundColor Red; exit 1 }
Write-Host "  ✓ 패키지 준비 완료" -ForegroundColor Green

# ── 3. ~/.claude/voice/ 에 데몬 복사 ────────────────────────────────────────────
Write-Host ""
Write-Host "[3/5] 데몬 파일 배포..." -ForegroundColor White
New-Item -ItemType Directory -Force -Path $VoiceDir | Out-Null
New-Item -ItemType Directory -Force -Path $HooksDir | Out-Null

Copy-Item (Join-Path $ScriptDir "voice_input.py") (Join-Path $VoiceDir "voice_input.py") -Force
Copy-Item (Join-Path $ScriptDir "start_voice.ps1") (Join-Path $HooksDir "start_voice.ps1") -Force
Write-Host "  ✓ $VoiceDir\voice_input.py" -ForegroundColor Green
Write-Host "  ✓ $HooksDir\start_voice.ps1" -ForegroundColor Green

# ── 4. settings.json — SessionStart 훅 병합 ─────────────────────────────────────
Write-Host ""
Write-Host "[4/5] settings.json 훅 등록..." -ForegroundColor White

$hookCmd = "powershell.exe -NoProfile -NonInteractive -ExecutionPolicy Bypass -File ~/.claude/hooks/start_voice.ps1"

# 파일 없으면 최소 구조 생성
if (-not (Test-Path $SettingsPath)) {
    @{ hooks = @{ SessionStart = @() } } | ConvertTo-Json -Depth 10 | Set-Content $SettingsPath -Encoding UTF8
}

$settings = Get-Content $SettingsPath -Raw -Encoding UTF8 | ConvertFrom-Json

# hooks 키 없으면 추가
if (-not $settings.hooks) {
    $settings | Add-Member -NotePropertyName hooks -NotePropertyValue ([PSCustomObject]@{}) -Force
}

# SessionStart 배열 없으면 추가
if (-not $settings.hooks.SessionStart) {
    $settings.hooks | Add-Member -NotePropertyName SessionStart -NotePropertyValue @() -Force
}

# 이미 등록돼 있는지 확인
$exists = $false
foreach ($entry in $settings.hooks.SessionStart) {
    foreach ($h in $entry.hooks) {
        if ($h.command -eq $hookCmd) { $exists = $true; break }
    }
    if ($exists) { break }
}

if ($exists) {
    Write-Host "  ✓ SessionStart 훅 이미 등록됨 (스킵)" -ForegroundColor DarkGray
} else {
    $newHook   = [PSCustomObject]@{ type = "command"; command = $hookCmd; async = $true }
    $newEntry  = [PSCustomObject]@{ hooks = @($newHook) }
    $settings.hooks.SessionStart = @($settings.hooks.SessionStart) + $newEntry
    $settings | ConvertTo-Json -Depth 20 | Set-Content $SettingsPath -Encoding UTF8
    Write-Host "  ✓ SessionStart 훅 등록 완료" -ForegroundColor Green
}

# ── 5. context-bar.sh — voice 상태 블록 삽입 (마커 기반) ─────────────────────────
Write-Host ""
Write-Host "[5/5] context-bar.sh 상태 표시 추가..." -ForegroundColor White

$voiceBlock = @'
# [VOICE-STATE-START]
voice_state=""
voice_state_file="$HOME/.claude/voice/state"
if [[ -f "$voice_state_file" ]]; then
    _vs=$(cat "$voice_state_file" 2>/dev/null)
    if [[ "$_vs" == "recording" ]]; then
        voice_state=" | $(printf '\U0001F534') REC"
    elif [[ "$_vs" == "idle" ]]; then
        voice_state=" | $(printf '\U0001F3A4')"
    fi
fi
# [VOICE-STATE-END]

'@

$outputLine = 'output="${C_ACCENT}${model}${C_GRAY} | '

if (-not (Test-Path $ContextBar)) {
    Write-Host "  ✓ context-bar.sh 없음 (스킵)" -ForegroundColor DarkGray
} else {
    $cb = Get-Content $ContextBar -Raw -Encoding UTF8

    if ($cb -match '\[VOICE-STATE-START\]') {
        # 마커 블록 교체
        $cb = $cb -replace '(?s)# \[VOICE-STATE-START\].*?# \[VOICE-STATE-END\]\r?\n\r?\n', $voiceBlock
        Write-Host "  ✓ 기존 블록 갱신" -ForegroundColor Green
    } elseif ($cb -match '# Build output') {
        # 마커 블록 신규 삽입
        $cb = $cb -replace '# Build output', ($voiceBlock + '# Build output')
        # output 줄에 ${voice_state} 삽입
        $cb = $cb -replace [regex]::Escape('output="${C_ACCENT}${model}${C_GRAY} | 📁 ${dir}"'),
                            'output="${C_ACCENT}${model}${C_GRAY} | 📁 ${dir}${voice_state}"'
        Write-Host "  ✓ 상태 블록 삽입 완료" -ForegroundColor Green
    } else {
        Write-Host "  ⚠ context-bar.sh 구조가 다릅니다. 수동 확인 필요." -ForegroundColor Yellow
    }

    $cb | Set-Content $ContextBar -Encoding UTF8 -NoNewline
}

# ── 완료 ────────────────────────────────────────────────────────────────────────
Write-Host ""
Write-Host "=== 설치 완료 ===" -ForegroundColor Cyan
Write-Host ""
Write-Host "다음 Claude Code 실행 시 자동으로 Voice Input이 시작됩니다." -ForegroundColor White
Write-Host "단축키: Ctrl+Shift+Space  (녹음 시작 / 종료 토글)" -ForegroundColor Yellow
Write-Host ""
Write-Host "지금 바로 시작하려면:" -ForegroundColor White
Write-Host "  Start-Process python -ArgumentList \"`\"`$HOME\.claude\voice\voice_input.py`\"`\" -WindowStyle Hidden" -ForegroundColor DarkGray
