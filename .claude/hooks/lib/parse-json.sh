#!/usr/bin/env bash
# lib/parse-json.sh — 공통 JSON 파싱 유틸리티
# 사용법: source "$(dirname "$0")/lib/parse-json.sh"
# Windows/Linux/Mac 모두에서 동작 (python3 또는 python 자동 감지)

# 실제 동작하는 Python 탐색 (Windows AppStore stub 우회)
PYTHON_CMD=""
for _py in python3 python; do
  if "$_py" -c "import sys" 2>/dev/null; then
    PYTHON_CMD="$_py"
    break
  fi
done
[ -z "$PYTHON_CMD" ] && exit 0

# tool_input의 특정 필드 추출
# 인자: $1=JSON 문자열, $2=필드명
get_tool_input_field() {
  local input="$1"
  local field="$2"
  echo "$input" | "$PYTHON_CMD" -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_input', {}).get('$field', ''))
except:
    print('')
" 2>/dev/null
}

# tool_response의 특정 필드 추출
# 인자: $1=JSON 문자열, $2=필드명
get_response_field() {
  local input="$1"
  local field="$2"
  echo "$input" | "$PYTHON_CMD" -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('tool_response', {}).get('$field', ''))
except:
    print('')
" 2>/dev/null
}
