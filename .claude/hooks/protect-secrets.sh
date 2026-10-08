#!/usr/bin/env bash
# PreToolUse: keep Claude out of real secrets/PII files.
# Blocks .env, .env.* (except .env.example) and anything under secrets/,
# whether reached through a file tool (Read/Edit/Write/...) or a Bash command.
set -uo pipefail

input=$(cat)
target=$(echo "$input" | jq -r '.tool_input.command // .tool_input.file_path // .tool_input.notebook_path // .tool_input.path // ""')

# Ignore the committed template, then look for anything secret-shaped.
scrubbed=${target//.env.example/}

if echo "$scrubbed" | grep -Eq '(^|[^[:alnum:]_])\.env([^[:alnum:]_]|$)|(^|[^[:alnum:]_])secrets/'; then
  echo "Blocked by .claude/hooks/protect-secrets.sh: .env files and secrets/ hold real PII/secrets and are off-limits." >&2
  echo "Use .env.example for key names. Ask the user to check or change real values. See CLAUDE.md > PII and secrets." >&2
  exit 2
fi

exit 0
