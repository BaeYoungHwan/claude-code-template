#!/usr/bin/env bash
# deny-list-guard.sh — 회사 장애 패턴 Deny List 차단
# PreToolUse(Bash) 훅: .claude/deny-patterns.json의 패턴과 매칭 시 차단

source "$(dirname "$0")/lib/parse-json.sh"

PATTERNS_FILE="$(git rev-parse --show-toplevel 2>/dev/null || pwd)/.claude/deny-patterns.json"

# 패턴 파일이 없으면 조용히 통과
[ -f "$PATTERNS_FILE" ] || exit 0

INPUT=$(cat)
COMMAND=$(get_tool_input_field "$INPUT" "command")

[ -z "$COMMAND" ] && exit 0

PYTHON_CMD=$(command -v python3 || command -v python)
[ -z "$PYTHON_CMD" ] && exit 0

export PATTERNS_FILE
export DENY_COMMAND="$COMMAND"

RESULT=$("$PYTHON_CMD" - <<'PYEOF'
import sys, json, os

patterns_file = os.environ.get('PATTERNS_FILE', '')
command = os.environ.get('DENY_COMMAND', '')

try:
    with open(patterns_file, 'r', encoding='utf-8') as f:
        data = json.load(f)
    for entry in data.get('patterns', []):
        pattern = entry.get('pattern', '')
        reason = entry.get('reason', '사유 미기재')
        if pattern and pattern in command:
            print(f"MATCH|{pattern}|{reason}")
            sys.exit(0)
except Exception:
    pass
PYEOF
)

if [ -n "$RESULT" ]; then
  PATTERN=$(echo "$RESULT" | cut -d'|' -f2)
  REASON=$(echo "$RESULT" | cut -d'|' -f3)
  echo "🚫 [Deny List] 금지 패턴 감지 — 명령이 차단되었습니다." >&2
  echo "   패턴: $PATTERN" >&2
  echo "   사유: $REASON" >&2
  echo "   ⚠️  시니어에게 확인 후 진행하세요." >&2
  echo "   패턴 목록: .claude/deny-patterns.json" >&2
  exit 1
fi

exit 0
