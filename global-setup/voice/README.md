# Voice Input — 보이스 입력 기능

단축키 토글로 음성을 녹음하고, Google Web Speech로 전사해 터미널에 자동으로 입력합니다.
API 키 불필요, 인터넷 연결만 있으면 됩니다.

## 요구 사항

- Python 3.8+
- 마이크
- 인터넷 연결

## 설치 (한 번만, 멱등)

```powershell
powershell -ExecutionPolicy Bypass -File global-setup/voice/install_voice.ps1
```

설치 스크립트가 하는 일:

| 단계 | 내용 |
|------|------|
| 1 | Python 버전 확인 |
| 2 | pip 패키지 설치 |
| 3 | `~/.claude/voice/voice_input.py` 배포 |
| 4 | `~/.claude/hooks/start_voice.ps1` 배포 |
| 5 | `~/.claude/settings.json` 에 SessionStart 훅 병합 (덮어쓰기 없음) |
| 6 | `~/.claude/hooks/context-bar.sh` 에 🎤 상태 블록 삽입 (마커 기반) |

> **멱등 보장** — 동일 PC에 여러 프로젝트가 설치해도 중복·충돌 없음.

## 자동 실행

설치 후 Claude Code를 터미널에서 시작하면 SessionStart 훅이 자동으로 Voice 데몬을 백그라운드 실행합니다.

- 시작 시 토스트 알림: "🎤 Voice Input 준비됨"
- Claude Code 상태바에 `🎤` 상시 표시 (녹음 중엔 `🔴 REC`)

## 수동 실행

```powershell
# 백그라운드 (운영 환경)
Start-Process python -ArgumentList "`"$HOME\.claude\voice\voice_input.py`"" -WindowStyle Hidden

# 포그라운드 (로그 확인용)
python $HOME\.claude\voice\voice_input.py
```

## 사용법

| 동작 | 단축키 |
|------|--------|
| 녹음 시작 | `Ctrl+Shift+Space` |
| 녹음 종료 + 전사 + 입력 | `Ctrl+Shift+Space` |
| 데몬 종료 | 트레이 아이콘 우클릭 → 종료 |

1. Claude Code 터미널에 포커스를 둡니다.
2. `Ctrl+Shift+Space` → 비프음(800Hz) → 녹음 시작
3. 명령어를 말합니다.
4. `Ctrl+Shift+Space` → 비프음(1200Hz) → 전사 후 텍스트 자동 입력

## 옵션

```powershell
python $HOME\.claude\voice\voice_input.py --hotkey "ctrl+shift+space" --lang ko-KR
```

| 옵션 | 기본값 | 설명 |
|------|--------|------|
| `--hotkey` | `ctrl+shift+space` | 토글 단축키 |
| `--lang` | `ko-KR` | 전사 언어 (ko-KR, en-US 등) |

## 로그

```
~/.claude/voice/voice.log   — 전사 기록 및 오류
~/.claude/voice/state       — 현재 상태 (idle / recording)
```

## 주의 사항

- `keyboard` 라이브러리는 Windows에서 관리자 권한 없이 동작합니다.
- 전사 결과는 클립보드를 경유해 입력됩니다. 잠깐 클립보드 내용이 덮어씌워집니다.
- Google Web Speech는 무료이나 인터넷 연결이 필요합니다.
