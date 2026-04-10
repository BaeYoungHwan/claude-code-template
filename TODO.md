# TODO — everything-claude-code 적용

> 참고: [everything-claude-code](https://github.com/affaan-m/everything-claude-code) 분석 후 선별한 항목들

---

## Phase 1 — 보안 & 감사 로그 (최우선)

- [ ] `.claude/hooks/pre-bash-guard.sh` 생성
  - `--no-verify`, 자격증명 패턴(`password=`, `api_key=`), `curl | sh` 차단
  - 한국어 오류 메시지 출력
- [ ] `.claude/hooks/post-bash-audit.sh` 생성
  - 실행된 Bash 명령어를 `logs/claude-audit.log`에 타임스탬프와 함께 기록 (async)
- [ ] `.claude/settings.json` 수정
  - `hooks` 블록 추가: PreToolUse → pre-bash-guard.sh, PostToolUse → post-bash-audit.sh

## Phase 2 — 세션 지속성

- [ ] `global-setup/hooks/session-persist.sh` 생성 (bash, 크로스플랫폼)
  - 세션 종료 시 git 브랜치/커밋/미커밋 파일 수/TODO.md 상단을 `docs/ref/session-state.md`에 저장
- [ ] `global-setup/settings.json` 수정
  - `CLAUDE_AUTOCOMPACT_PCT_OVERRIDE: "80"` env 추가
  - Stop hooks 배열에 session-persist.sh 추가

## Phase 3 — 참조 문서

- [ ] `docs/ref/todo-workflow.md` 생성 (CLAUDE.md에서 참조 중인데 파일 없음)
- [ ] `docs/ref/commit-convention.md` 생성 — 한국어 커밋 컨벤션
- [ ] `docs/ref/testing-patterns.md` 생성 — pass@k / pass^k 패턴 설명

## Phase 4 — 스킬 (슬래시 커맨드)

- [ ] `.claude/commands/commit.md` → `/commit` 스킬
- [ ] `.claude/commands/review.md` → `/review` 스킬
- [ ] `.claude/commands/tdd.md` → `/tdd` 스킬

## Phase 5 — 에이전트 템플릿

- [ ] `agents/code-reviewer.md` — 코드 리뷰 전담 서브에이전트
- [ ] `agents/security-reviewer.md` — 보안 검토 전담 서브에이전트

## Phase 6 — CLAUDE.md 보강

- [ ] 모델 규칙에 Haiku 추가 (읽기 전용 탐색/단순 grep 작업용)
- [ ] 보안 규칙 섹션 추가 (2-3줄)
- [ ] `docs/ref` 목록 업데이트 (신규 파일 반영)

---

## 적용 안 할 항목

- 47개 전체 에이전트 (프로젝트별 생성 원칙)
- 181개 스킬 전체 (언어/프레임워크 종속)
- PreCompact 훅 (사용자가 이해하기 어려움)
- AgentShield 통합 (대규모 팀 대상, 개인 템플릿에 과잉)
- 품질 게이트 PostToolUse (언어/툴체인 종속)
