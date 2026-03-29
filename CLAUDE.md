# [프로젝트명] — Claude Code 지침

## 개요
[프로젝트 한 줄 설명]

## 환경
- Language: [e.g. Python 3.12 / Node 20 / Go 1.22]
- OS: Windows 11 / macOS / Linux
- Editor: VS Code + Claude Code

## 코딩 규칙
- 변수명, 함수명, 코드: 영어
- 주석, 커밋 메시지, 소통: 한국어
- 민감정보(API 키 등)는 .env로 관리, 절대 커밋 금지

## 참조 문서 규칙
- CLAUDE.md는 항상 참조해야 하는 핵심 규칙만 유지 (간소화)
- 특정 상황에만 필요한 문서는 `docs/ref/`에 배치
- 에이전트가 필요할 때만 ref 파일을 참조
- TODO.md 작업 시 → `docs/ref/todo-workflow.md` 참조

## 모델 사용 규칙
- Plan 모드: Opus
- 개발(코딩, 디버깅 등): Sonnet

## 에이전트 사용 규칙
- `agents/` 폴더의 에이전트는 **병렬 처리 서브태스크** 전용
- Plan 모드로 설계 후, 독립적으로 분리 가능한 작업은 반드시 에이전트로 병렬 실행
- 새 프로젝트 시작 시 `agents/example-agent.md`를 복사해서 역할별 에이전트 생성
  - 예: `frontend.md`, `backend.md`, `db.md` 등 모듈 단위로 분리

## 알림
- 1차: PC 토스트 알림 (global-setup 설치 시 자동 동작)
- 2차: [추후 도입 예정]

## 프로젝트 구조
```
[프로젝트명]/
├── CLAUDE.md
├── TODO.md
├── .claude/settings.json
├── .env                  # gitignore 대상
├── agents/               # Claude Code 병렬 에이전트
├── src/
├── tests/
├── docs/ref/             # 참조 문서
└── logs/                 # gitignore 대상
```
