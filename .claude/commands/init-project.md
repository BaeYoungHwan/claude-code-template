# /init-project — 새 프로젝트 초기화

새 프로젝트를 시작할 때 실행하세요. Claude가 양식을 출력하면, 직접 작성해서 붙여넣으면 됩니다.

---

## Step 1 — 아래 양식을 사용자에게 출력한다

```
=== 프로젝트 초기화 양식 ===
(항목을 작성 후 전체를 붙여넣어 주세요)

1. 프로젝트명:
   예) my-saas-app

2. 한 줄 설명 (무엇을 위해 만드는가):
   예) 소규모 팀의 업무 일지를 자동으로 요약해 주는 슬랙 봇

3. 기술 스택:
   예) Python 3.12 + FastAPI + PostgreSQL 16 + React 18 + Docker

4. 배포 환경:
   예) AWS EC2 + Docker Compose / Vercel + Supabase / 온프레미스 / 미정

5. 타겟 유저 / 페르소나:
   예)
   - 주 사용자: 5~20인 스타트업의 개발팀 리드
   - 부 사용자: 경영진 (요약 보고서 수신)

6. 성공 지표 (KPI):
   예)
   - 일지 작성 시간 50% 단축
   - 주간 활성 사용자 100명 이상
   - 요약 만족도 평점 4.0 이상

7. MVP 핵심 기능 (반드시 구현할 것):
   예)
   - 사용자 로그인/회원가입
   - 대시보드 조회
   - 데이터 CSV 업로드

8. MVP 제외 사항 (이번 버전에 포함하지 않을 것):
   ※ AI가 알아서 추가 구현하는 것을 막는 범위 선언입니다.
   예)
   - 소셜 로그인 (Google, GitHub)
   - 이메일 알림 기능
   - 다국어(i18n) 지원

9. 비기능 요건 (성능 / 보안 / 가용성 목표):
   예)
   - 응답시간: p95 < 300ms
   - 동시 접속: 최대 200명
   - 가용성: 99.5% (월 다운타임 3.6시간 이하)
   - 보안: JWT 인증, HTTPS 강제, SQL 인젝션 방지

10. 팀 구성 / 일정:
    예)
    - 팀: 개인 프로젝트 (1인) / 2인 팀 (풀스택 1 + 디자이너 1)
    - MVP 마감: 2025-03-31
    - 런칭 목표: 2025-05-01

11. 제약사항 / 특이사항:
    예) 클라이언트 측 렌더링만 허용, 외부 API 의존 최소화, 예산 월 $50 이하

12. 이 프로젝트에서 Claude에게 특별히 지켜야 할 것:
    ※ 없으면 "없음"으로 작성하세요.
    예)
    - 테스트 없이 구현 파일 생성 금지
    - DB 스키마 변경 전 반드시 확인 요청
    - 외부 라이브러리 추가 시 항상 물어볼 것

==============================
```

---

## Step 2 — 사용자가 양식을 제출하면

### [필수] 프로젝트 규모 선택

아래 표를 출력하고 번호를 입력받는다. **이 항목은 건너뛸 수 없다.**

```
=== 프로젝트 규모 선택 ===
규모에 따라 Claude 훅(자동화 제약)이 설정됩니다.

  1. 개인 (1인)       — 현재 기본 설정 유지
  2. 스타트업 (2~10인) — + Lint·Test·Build 검사 (commit 전 자동 실행)
  3. 회사 (10인+)     — + Lint·Test·Build + 장애 패턴 Deny List + PR Sub-Agent 리뷰

번호를 입력하세요 (1 / 2 / 3):
```

사용자가 번호를 입력하면 내부 변수 `SCALE`에 저장한다 (1=개인, 2=스타트업, 3=회사).

---

1. 내용을 검토하고 **2~3가지 보완 질문**을 한다
   - MVP 제외 사항(8번)이 비어 있으면 반드시 물어볼 것
   - 비기능 요건(9번)이 "없음/미정"이면 서비스 규모를 재확인할 것
   - 스택이 모호하면 버전 또는 DB 선택 이유를 물어볼 것
   - 일정(10번)이 없으면 MVP 목표 시점을 물어볼 것

2. 보완 답변을 받으면 **Step 3**으로 진행한다

---

## Step 3 — 산출물 5종 생성

### 3-1. CLAUDE.md 갱신

`CLAUDE.md` 상단 플레이스홀더를 채운다:
- `[프로젝트명]` → 양식 1번
- `[프로젝트 한 줄 설명]` → 양식 2번

`CLAUDE.md` 하단에 **프로젝트 맞춤 규칙** 섹션을 추가한다:

```markdown
## 프로젝트 맞춤 규칙

> /init-project 에서 자동 생성됨. 이 프로젝트에만 적용됩니다.

### Claude 행동 지침
[양식 12번 내용 — 없음이면 이 항목 생략]

### MVP 범위 제한
> 아래 항목은 명시적 요청 없이 절대 구현하지 않습니다.
[양식 8번 제외 목록]

### 기술 스택 고정
[양식 3번 스택 — 다른 라이브러리/프레임워크 임의 도입 금지]
```

---

### 3-2. TODO.md 채우기

`TODO.md`의 플레이스홀더를 아래 구조로 교체한다:

```markdown
# TODO — [프로젝트명]

> 워크플로우: `[ ]` 대기 → `[🔄]` 진행 중 → `[x]` 완료
> 재시작 시: `docs/ref/session-state.md` 확인 후 `[🔄]` 항목부터 재개

---

## 시작 전

- [x] `/init-project` 실행 완료
- [ ] `docs/design-docs/architecture-v1.md` 검토 및 확정
- [ ] `docs/design-docs/ARD-v1.md` 비기능 요건 확정
- [ ] Phase 분할 후 `docs/exec-plans/active/`에 실행 계획 생성

---

## P0 — 기반 구축

- [ ] 레포 초기화 및 폴더 구조 생성
- [ ] 기술 스택 설치 및 Hello World 확인
- [ ] CI/CD 파이프라인 초안 구성

---

## P1 — MVP 핵심 기능

[양식 7번 기능 목록을 항목으로 변환]

---

## P2 — 검증 및 배포

- [ ] E2E 테스트 작성
- [ ] [양식 4번 배포 환경]에 배포
- [ ] KPI 측정 기준 설정
```

---

### 3-3. PRD 생성

`docs/product-specs/PRD-v1.md` 생성:

```markdown
# [프로젝트명] PRD v1

> 버전: v1 | 작성일: [오늘 날짜] | 상태: Draft

---

## 1. 개요

[양식 2번 — 한 줄 설명]

## 2. 문제 정의

[양식 내용을 바탕으로 Claude가 추론하여 작성 — "현재 어떤 불편이 있고, 왜 지금 해결해야 하는가"]

## 3. 타겟 유저

| 페르소나 | 설명 | 주요 시나리오 |
|----------|------|---------------|
[양식 5번 내용을 표 형식으로 변환]

## 4. 성공 지표 (KPI)

[양식 6번 목록]

## 5. 기술 스택

[양식 3번]

## 6. 배포 환경

[양식 4번]

## 7. MVP 핵심 기능

> 이번 버전에서 반드시 구현할 기능

[양식 7번 목록을 `- [ ]` 형식으로]

## 8. MVP 제외 사항 ⚠️

> Claude는 아래 항목을 임의로 구현하지 않습니다.

[양식 8번 목록]

## 9. 제약사항

[양식 11번]

## 10. 팀 / 일정

[양식 10번]

## 11. Phase 분할 (초안)

| Phase | 목표 | 예상 산출물 |
|-------|------|-------------|
| P0 | 기반 구축 | 레포 초기화, CI/CD |
| P1 | MVP 핵심 기능 | [양식 7번 기능들] |
| P2 | 검증 및 배포 | E2E 테스트, 배포 |

## 12. 미결 사항

| 질문 | 결정권자 | 기한 |
|------|----------|------|
| [보완 질문에서 미결된 항목이 있으면 여기에] | - | - |
```

---

### 3-4. ARD 생성

`docs/design-docs/ARD-v1.md` 생성:

> **ARD(Architecture Requirements Document)** — 아키텍처가 만족해야 하는 품질 속성과 제약을 명세합니다.
> ADR(결정 기록)과 다릅니다: ARD는 "무엇을 달성해야 하나", ADR은 "어떻게 결정했나"입니다.

```markdown
# [프로젝트명] ARD v1

> 버전: v1 | 작성일: [오늘 날짜] | 상태: Draft
> 참조 PRD: `docs/product-specs/PRD-v1.md`

---

## 1. 품질 속성 목표 (Quality Attributes)

| 속성 | 목표 | 측정 방법 | 우선순위 |
|------|------|-----------|----------|
| 성능 | [양식 9번에서 추출] | [예: p95 응답시간 측정] | High |
| 가용성 | [양식 9번에서 추출] | [예: 월간 업타임 모니터링] | High |
| 보안 | [양식 9번에서 추출] | [예: OWASP Top 10 점검] | High |
| 확장성 | [동시 접속 수 기반 추론] | [예: 부하 테스트] | Medium |
| 유지보수성 | 테스트 커버리지 70%+ | 커버리지 리포트 | Medium |

---

## 2. 아키텍처 제약사항

### 기술적 제약
[양식 11번에서 기술적 항목 추출]

### 조직적 제약
[양식 10번 팀 구성 기반 — 예: "1인 개발이므로 운영 복잡도 최소화"]

### 예산/인프라 제약
[양식 11번에서 예산/인프라 항목 추출]

---

## 3. 주요 아키텍처 결정 (초안)

> 상세 결정 기록은 `docs/design-docs/adr/` 에 ADR로 작성합니다.

| 결정 영역 | 선택 | 근거 |
|-----------|------|------|
| 레이어 구조 | [스택 기반 추론] | [이유] |
| 인증 방식 | [스택/요건 기반 추론] | [이유] |
| 데이터 저장 | [스택 기반] | [이유] |
| 배포 전략 | [양식 4번 기반] | [이유] |

---

## 4. 리스크

| 리스크 | 영향도 | 발생 가능성 | 완화 전략 |
|--------|--------|-------------|-----------|
[스택/요건/팀 규모를 바탕으로 Claude가 3~5개 추론하여 작성]

---

## 5. 검증 기준

아키텍처가 이 ARD를 만족하는지 확인하는 방법:

- [ ] 품질 속성 목표 달성 여부 — 부하 테스트 / 모니터링 지표
- [ ] 제약사항 위반 없음 — `architecture-guard.sh` 훅 통과
- [ ] 주요 결정사항 ADR 작성 완료 (`docs/design-docs/adr/`)
```

---

### 3-5. 아키텍처 초안 생성

`docs/design-docs/architecture-v1.md` 생성:

> 기술 스택, 배포 환경, 비기능 요건을 바탕으로 Claude가 초안을 작성합니다.
> `docs/ref/architecture-template.md` 구조를 따릅니다.

```markdown
# [프로젝트명] 아키텍처 v1

> 작성일: [오늘 날짜] | 버전: v1 | 상태: Draft
> 참조 ARD: `docs/design-docs/ARD-v1.md`

---

## 1. 시스템 개요

[양식 2번 설명을 기반으로 시스템이 무엇을 하는지 한 단락으로]

## 2. 컴포넌트 다이어그램

[기술 스택과 배포 환경을 기반으로 ASCII 다이어그램 생성]

## 3. 레이어 구조

[스택에 맞는 폴더 구조 제안 — Python/FastAPI면 api/services/domain/repositories/core 등]

## 4. 데이터 흐름

[주요 기능 1~2개의 Request → Response 흐름]

## 5. 주요 설계 결정

| 결정 | 선택 | 이유 | ADR |
|------|------|------|-----|
[ARD 3번 내용 연동]

## 6. 비기능 요건 달성 전략

[ARD 품질 속성별로 어떻게 달성할지 설명]

## 7. 보안 고려사항

[양식 9번 보안 요건 기반]

## 8. 배포 구성

[양식 4번 배포 환경 기반으로 구체적인 구성 제안]
```

---

### 3-6. 규모별 훅 설정 (.claude/settings.json 업데이트)

`SCALE` 값에 따라 `.claude/settings.json`의 `hooks.PreToolUse` 배열을 수정한다.
Read → Edit 방식으로 JSON을 직접 수정한다.

**SCALE = 1 (개인):** settings.json 변경 없음.

**SCALE = 2 (스타트업):** `hooks.PreToolUse`에 아래 항목 추가:

```json
{
  "matcher": "Bash",
  "hooks": [
    {
      "type": "command",
      "command": "bash .claude/hooks/lint-test-build.sh"
    }
  ]
}
```

**SCALE = 3 (회사):** 위 항목에 추가로 아래 2개도 추가:

```json
{
  "matcher": "Bash",
  "hooks": [
    {
      "type": "command",
      "command": "bash .claude/hooks/deny-list-guard.sh"
    }
  ]
},
{
  "matcher": "Bash",
  "hooks": [
    {
      "type": "command",
      "command": "bash .claude/hooks/sub-agent-review.sh"
    }
  ]
}
```

**SCALE = 2, 3 공통 — permissions.deny에 main 직접 푸시 차단 추가:**

`settings.json`의 `permissions.deny` 배열에 아래 항목을 추가한다 (이미 있으면 스킵):

```json
"Bash(git push origin main)",
"Bash(git push origin master)"
```

**SCALE = 3 — 엄격 모드 플래그 생성 및 architecture-guard 동기화:**

1. `.claude/hooks-strict.flag` 빈 파일 생성:
   - 이 파일이 존재하면 `architecture-guard.sh`가 위반 시 실제로 차단(exit 1)하고,
     `tdd-enforcer.sh`가 기존 파일 수정 시에도 테스트 파일 존재를 확인한다.

2. `settings.json`에서 `architecture-guard.sh` 훅 항목의 `"async": true`를 제거:
   - async 상태에서는 exit code가 무시되어 차단이 불가능하므로 동기로 전환한다.
   - 변경 전: `{ "type": "command", "command": "bash .claude/hooks/architecture-guard.sh", "async": true }`
   - 변경 후: `{ "type": "command", "command": "bash .claude/hooks/architecture-guard.sh" }`

추가 안내:
- SCALE 3 선택 시: `.claude/deny-patterns.json` 파일에 팀 고유 장애 패턴을 등록하도록 안내한다.
- 이미 동일한 훅이 등록되어 있으면 중복 추가하지 않는다.

---

## Step 4 — 생성 완료 후 안내

산출물 생성 후 아래 메시지를 출력한다:

```
✅ 초기화 완료

생성된 파일:
  - CLAUDE.md           (프로젝트 맞춤 규칙 추가됨)
  - TODO.md             (Phase 구조로 채워짐)
  - docs/product-specs/PRD-v1.md
  - docs/design-docs/ARD-v1.md
  - docs/design-docs/architecture-v1.md

활성화된 훅 (규모: [선택한 규모]):
  [SCALE=1] 기본 훅만 유지 (TDD 강제, 보안 가드 등)
  [SCALE=2] + Lint·Test·Build / main 직접 푸시 차단
  [SCALE=3] + Lint·Test·Build / main 직접 푸시 차단
           + Deny List / Sub-Agent PR Review
           + 아키텍처 위반 차단 (엄격 모드)
           + TDD — 기존 파일 수정 시에도 테스트 확인

[SCALE=3인 경우에만 출력]
  ⚠️  장애 패턴 Deny List를 팀 상황에 맞게 등록하세요:
      .claude/deny-patterns.json

다음 단계:
  1. docs/design-docs/architecture-v1.md 검토 → 방향 수정이 있으면 알려주세요
  2. ARD의 품질 속성 목표 확정
  3. Phase 분할 계획: Plan 모드에서 /ralph 또는 /ultrawork 사용
  4. 실행 계획 생성: docs/exec-plans/active/phase-1.md
```
