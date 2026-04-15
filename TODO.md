# TODO — Claude Code 하네스 고도화

> 참고 레포: [everything-claude-code](https://github.com/affaan-m/everything-claude-code) · [oh-my-claudecode](https://github.com/yeachan-heo/oh-my-claudecode)
> 참고 문서: [OpenAI 하네스 엔지니어링](https://openai.com/ko-KR/index/harness-engineering/)

---

## P0 — 안전망 (즉시)
> 이것 없이는 다른 작업이 위험하다

### 보안 & 감사 로그
- [x] `.claude/hooks/pre-bash-guard.sh` 생성
  - `--no-verify`, 자격증명 패턴(`password=`, `api_key=`), `curl | sh` 차단
  - 한국어 오류 메시지 출력
- [x] `.claude/hooks/post-bash-audit.sh` 생성
  - 실행된 Bash 명령어를 `logs/claude-audit.log`에 타임스탬프와 함께 기록 (async)
- [x] `.claude/settings.json` 수정
  - `hooks` 블록 추가: PreToolUse → pre-bash-guard.sh, PostToolUse → post-bash-audit.sh

### 세션 지속성
- [x] `.claude/hooks/session-persist.sh` 생성
  - 세션 종료 시 git 브랜치 / 마지막 커밋 / 미커밋 파일 수를 `docs/ref/session-state.md`에 저장
  - ※ 대화 맥락은 Claude Code Auto Memory가 담당 → git 상태만 저장

---

## P1 — 기반 구축 (1~2주)
> 규칙과 구조를 정의해야 나머지가 의미 있다

### CLAUDE.md 재설계 (목차형 지도)
- [x] `CLAUDE.md` 를 ~100줄 이내로 재작성
  - 세부 규칙은 `docs/`로 분리, CLAUDE.md는 어디에 있는지만 안내
  - 모델 규칙 추가: 탐색/grep → Haiku, 개발 → Sonnet, 설계 → Opus
  - 보안 규칙 섹션 추가 (2~3줄)

### 프로젝트 시작 가이드
- [x] `.claude/commands/init-project.md` → `/init-project` 스킬
  - 프로젝트 정보 양식 출력 (각 항목마다 설명 + 예시 포함)
  - 양식 항목: 프로젝트명, 기술 스택, MVP 핵심 기능, MVP 제외 사항, 제약사항
  - 사용자가 양식 작성 후 전달 → Claude가 보완 질문
  - CLAUDE.md 플레이스홀더 자동 완성 + PRD 초안 생성
- [x] `docs/ref/project-setup.md` 생성
  - 템플릿 복사 후 시작 체크리스트
  - 양식 각 항목의 의미와 예시 설명
    - MVP 제외 사항: "AI가 알아서 추가 구현하는 것을 막는 범위 선언"
  - `/init-project` 실행 방법 안내

### 참조 문서
- [x] `docs/ref/todo-workflow.md` 생성
- [x] `docs/ref/commit-convention.md` 생성
  - 한국어 커밋 컨벤션
  - Trailers 패턴: `Constraint:`, `Rejected:`, `Directive:`, `Confidence:`, `Scope-risk:`, `Not-done:`
- [x] `docs/ref/testing-patterns.md` 생성 — pass@k / pass^k 패턴
- [x] `docs/ref/agent-model-routing.md` 생성
- [x] `docs/ref/verification-protocol.md` 생성

### docs/ 지식 베이스 구조화
- [x] `docs/design-docs/` 생성
  - `index.md`, `core-beliefs.md`, `golden-principles.md`, `architecture-layers.md`
- [x] `docs/exec-plans/` 생성
  - `active/`, `completed/`, `tech-debt-tracker.md`
- [x] `docs/product-specs/index.md` 생성
- [ ] `docs/references/` 생성
  - 외부 라이브러리 문서를 `llms.txt` 포맷으로 저장 (에이전트가 레포 내에서 참조)
- [x] `docs/QUALITY_SCORE.md` 생성
- [x] `docs/RELIABILITY.md` 생성
- [x] `docs/SECURITY.md` 생성

---

## P2 — 자동화 (2~4주)
> 반복 작업을 명령 하나로

### 스킬 (슬래시 커맨드)
- [x] `.claude/commands/commit.md` → `/commit` 스킬
- [x] `.claude/commands/tdd.md` → `/tdd` 스킬
- [x] `.claude/commands/deep-interview.md` → `/deep-interview` 스킬

### 추가 안전 훅
- [x] `.claude/hooks/tdd-enforcer.sh` 생성 (PreToolUse)
- [x] `.claude/hooks/circuit-breaker.sh` 생성 (PostToolUse)
- [x] `.claude/settings.json` 수정 — tdd-enforcer, circuit-breaker, session-replay 추가

### Spec-driven 개발 기반
- [x] `docs/ref/PRD-template.md` 생성
- [x] `docs/ref/architecture-template.md` 생성
- [x] `docs/ref/ADR-template.md` 생성
- [x] `docs/ref/spec-driven-workflow.md` 생성

### 세션 리플레이
- [x] `.claude/hooks/session-replay.sh` 생성
- [x] `.gitignore` 수정 — `logs/` 확인 및 .gitkeep 예외 추가

---

## P3 — 하네스 완성 (1개월+)
> 에이전트가 스스로 검증하고 유지하는 시스템

### 고급 스킬
- [x] `.claude/commands/ralph.md` → `/ralph` 스킬
- [x] `.claude/commands/ultrawork.md` → `/ultrawork` 스킬

### 에이전트
- [x] `agents/LANES.md` 생성
- [x] `agents/code-reviewer.md` 생성
- [x] `agents/doc-gardener.md` 생성

### 자동 실행 엔진
- [x] `executor.py` 생성
  - `claude -p` 헤드리스 모드로 Phase별 순차 실행
  - 실패 시 해당 Phase만 재실행

### 아키텍처 강제
- [x] `.claude/hooks/architecture-guard.sh` 생성 (PostToolUse, async)

---

## 적용 안 할 항목

- `/review`, `/security-review` 스킬 → Claude Code 내장
- `security-reviewer.md` 에이전트 → Claude Code 내장
- `.omc/notepad.md`, `project-memory.json` → Auto Memory 내장
- `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE` → 자동 compact 내장
- 47개 전체 에이전트 (프로젝트별 생성 원칙)
- 181개 스킬 전체 (언어/프레임워크 종속)
- HUD 설정 (omcHud.preset) — 개인 템플릿에 과잉
- AI slop cleaner — 언어 종속적
