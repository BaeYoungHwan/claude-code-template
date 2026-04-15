#!/usr/bin/env bash
# post-bash-audit.sh — 실행된 Bash 명령을 감사 로그에 기록
# PostToolUse(Bash) 훅: async 실행 (비동기, 실패해도 무시)

LOG_DIR="$(cd "$(dirname "$0")/../.." && pwd)/logs"
LOG_FILE="$LOG_DIR/claude-audit.log"

INPUT=$(cat)
COMMAND=$(echo "$INPUT" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('command', '').replace('\n', ' '))
except:
    print('')
" 2>/dev/null)

# 빈 명령이면 건너뜀
[ -z "$COMMAND" ] && exit 0

# logs/ 디렉토리 생성 (없으면)
mkdir -p "$LOG_DIR"

# 타임스탬프 + 명령어 기록
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
echo "[$TIMESTAMP] $COMMAND" >> "$LOG_FILE"

exit 0
