#!/usr/bin/env bash
# tdd-enforcer.sh — 구현 코드 작성 전 테스트 파일 존재 여부 확인
# PreToolUse(Write/Edit) 훅

INPUT=$(cat)

# 작성하려는 파일 경로 추출
FILE_PATH=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    path = data.get('tool_input', {}).get('file_path', '')
    print(path)
except:
    print('')
" 2>/dev/null)

[ -z "$FILE_PATH" ] && exit 0

# 구현 파일인지 판단 (테스트/설정/문서 파일은 제외)
is_impl_file() {
  local path="$1"
  # 제외 패턴: 테스트, 문서, 설정, 마이그레이션, 훅, 스킬
  echo "$path" | grep -qiE '(test_|_test\.|\.test\.|spec\.|\.spec\.|/tests?/|__tests__|\.md$|\.json$|\.yaml$|\.yml$|\.toml$|\.cfg$|\.ini$|hooks/|commands/|migrations?/|\.env|\.gitignore|requirements)' && return 1
  # 구현 파일 패턴: .py .ts .tsx .js .jsx .go .rs
  echo "$path" | grep -qiE '\.(py|ts|tsx|js|jsx|go|rs|java|rb|php)$' && return 0
  return 1
}

if ! is_impl_file "$FILE_PATH"; then
  exit 0
fi

# 파일명에서 테스트 파일 경로 추론
BASENAME=$(basename "$FILE_PATH")
DIRNAME=$(dirname "$FILE_PATH")
STEM="${BASENAME%.*}"
EXT="${BASENAME##*.}"

# 이미 존재하는 파일 수정이면 패스 (신규 생성만 체크)
if [ -f "$FILE_PATH" ]; then
  exit 0
fi

# 테스트 파일 존재 여부 확인 (여러 위치 검색)
TEST_EXISTS=false

# Python 패턴
if [ "$EXT" = "py" ]; then
  for pattern in \
    "$(dirname "$DIRNAME")/tests/test_${STEM}.py" \
    "${DIRNAME}/test_${STEM}.py" \
    "tests/test_${STEM}.py" \
    "tests/${STEM}/test_${STEM}.py"
  do
    [ -f "$pattern" ] && TEST_EXISTS=true && break
  done
fi

# TypeScript/JavaScript 패턴
if echo "$EXT" | grep -qE '^(ts|tsx|js|jsx)$'; then
  for pattern in \
    "${DIRNAME}/${STEM}.test.${EXT}" \
    "${DIRNAME}/${STEM}.spec.${EXT}" \
    "__tests__/${STEM}.test.${EXT}" \
    "tests/${STEM}.test.${EXT}"
  do
    [ -f "$pattern" ] && TEST_EXISTS=true && break
  done
fi

if [ "$TEST_EXISTS" = "false" ]; then
  echo "⚠️  [TDD 강제] 테스트 파일이 없습니다." >&2
  echo "   구현 파일: $FILE_PATH" >&2
  echo "   먼저 테스트 파일을 작성하세요. (/tdd 스킬 참조)" >&2
  echo "   테스트 없이 진행하려면 Not-done: 이유를 커밋 메시지에 명시하세요." >&2
  echo "" >&2
  echo "   계속 진행하려면 먼저 테스트 파일을 생성하세요." >&2
  exit 1
fi

exit 0
