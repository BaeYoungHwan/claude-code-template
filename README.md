# Claude Code 하네스 템플릿

> Claude Code를 프로덕션 수준으로 바로 쓸 수 있는 범용 템플릿.
> 보안 훅, 자동화 스킬, 문서 구조가 사전 구성되어 있습니다.

---

## 무엇이 포함되나

### 보안 & 감사 훅 (`.claude/hooks/`)

| 훅 | 동작 시점 | 역할 |
|----|-----------|------|
| `pre-bash-guard.sh` | Bash 실행 전 | `rm -rf`, `--no-verify`, `curl\|sh`, 자격증명 패턴 차단 |
| `post-bash-audit.sh` | Bash 실행 후 | 모든 명령을 `logs/claude-audit.log`에 기록 |
| `tdd-enforcer.sh` | Write/Edit 전 | 구현 파일 생성 시 테스트 파일 존재 여부 강제 확인 |
| `architecture-guard.sh` | Write/Edit 후 | 레이어 의존성 위반 감지 (경고) |
| `circuit-breaker.sh` | Bash 실행 후 | 동일 에러 3회 반복 시 자동 중단 |
| `session-replay.sh` | Bash 실행 후 | tool call 이벤트를 JSONL로 기록 (성능 분석) |
| `session-persist.sh` | 세션 종료 시 | git 상태를 `docs/ref/session-state.md`에 저장 |

### 슬래시 스킬 (`.claude/commands/`)

| 스킬 | 역할 |
|------|------|
| `/init-project` | 프로젝트 정보 양식 → CLAUDE.md 완성 + PRD 초안 |
| `/commit` | 한국어 커밋 컨벤션 + Trailers 패턴 |
| `/tdd` | Red → Green → Refactor 사이클 (pass^3) |
| `/deep-interview` | 소크라테스식 질문으로 스펙 구체화 |
| `/ralph` | plan → exec → verify → fix 완료 보장 루프 |
| `/ultrawork` | 독립 작업 병렬화 (에이전트 서브태스크) |

### 에이전트 (`agents/`)

| 에이전트 | 역할 |
|----------|------|
| `code-reviewer.md` | 코드 품질 리뷰 (Sonnet) |
| `doc-gardener.md` | 문서-코드 불일치 감지 (Haiku) |
| `example-agent.md` | 프로젝트별 에이전트 생성 템플릿 |

### 문서 구조 (`docs/`)

```
docs/
├── ref/              # 필요할 때만 로드하는 참조 문서
│   ├── todo-workflow.md       # [ ]→[🔄]→[x] 워크플로우
│   ├── commit-convention.md   # 한국어 커밋 + Trailers
│   ├── testing-patterns.md    # pass@k / pass^k
│   ├── agent-model-routing.md # Haiku/Sonnet/Opus 라우팅
│   ├── verification-protocol.md
│   ├── PRD-template.md
│   ├── architecture-template.md
│   ├── ADR-template.md
│   └── spec-driven-workflow.md
├── design-docs/      # 설계 문서 (core-beliefs, golden-principles 등)
├── exec-plans/       # 실행 계획 (active/ / completed/)
└── product-specs/    # PRD / 기획 문서
```

### 자동화 도구

- `executor.py` — exec-plans의 `[ ]` 항목을 `claude -p` 헤드리스 모드로 순차 실행

---

## 빠른 시작

### 1단계 — 템플릿으로 새 레포 생성

GitHub **"Use this template"** 버튼 클릭 → 새 레포 생성

또는 gh CLI:
```bash
gh repo create my-project --template <owner>/claude-code-template --private --clone
cd my-project
```

### 2단계 — 전역 설정 설치 (최초 1회)

상태바(컨텍스트 사용량 표시)와 Windows 토스트 알림을 사용하려면:

```bash
mkdir -p ~/.claude/hooks

cp global-setup/settings.json ~/.claude/settings.json
cp global-setup/hooks/context-bar.sh ~/.claude/hooks/
cp global-setup/hooks/notify.ps1 ~/.claude/hooks/
cp global-setup/hooks/session_start.ps1 ~/.claude/hooks/

# Mac/Linux
chmod +x ~/.claude/hooks/context-bar.sh
```

> `~/.claude/settings.json`이 이미 있다면 기존 내용 백업 후 병합하세요.

### 3단계 — 프로젝트 초기화

Claude Code를 열고 실행:
```
/init-project
```

양식을 작성하면 Claude가 `CLAUDE.md` 플레이스홀더를 완성하고 PRD 초안을 생성합니다.

---

## 상태바 (context-bar)

```
claude-sonnet-4-6 | 📁 my-project | 🔀 main (0 uncommitted) | ████░░░░░░ ~12%
💬 마지막 메시지...
```

색상 변경: `global-setup/hooks/context-bar.sh` 상단의 `COLOR` 값 수정
`orange | blue | teal | green | lavender | rose | gold | slate | cyan`

---

## Windows 토스트 알림

작업 완료 시 알림 + 효과음. 세션 3분 이상일 때만 발동 (짧은 작업 노이즈 방지).

> Mac/Linux: `global-setup/settings.json`의 훅 커맨드를 OS에 맞게 수정

---

## executor.py 사용법

exec-plans의 마크다운에 `- [ ] 작업설명` 형식으로 작업을 나열하면 자동 순차 실행:

```bash
python executor.py --plan docs/exec-plans/active/phase-1.md
python executor.py --plan docs/exec-plans/active/phase-1.md --dry-run
python executor.py --plan docs/exec-plans/active/phase-1.md --retry-failed
```

---

## 요구사항

- [Claude Code](https://claude.ai/code) 설치
- Python 3.x (훅 JSON 파싱에 사용)
- [jq](https://jqlang.github.io/jq/) (context-bar 상태 표시에 필요)
- Windows: PowerShell 5.1+ (토스트 알림)
