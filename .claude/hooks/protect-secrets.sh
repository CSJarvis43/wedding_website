#!/usr/bin/env bash
# PreToolUse: keep Claude out of real secrets/PII files.
# Blocks .env, .env.* (except .env.example) and anything under secrets/,
# whether reached through a file tool (Read/Edit/Write/...) or a Bash command.
#
# For Bash, quoted strings and heredoc bodies are ignored first, so prose that
# merely mentions these paths (commit messages, PR bodies) isn't blocked. Only
# bare words in the command itself (`cat .env`, `cp secrets/x .`) are checked.
set -uo pipefail

input=$(cat)
tool=$(echo "$input" | jq -r '.tool_name // ""')
target=$(echo "$input" | jq -r '.tool_input.command // .tool_input.file_path // .tool_input.notebook_path // .tool_input.path // ""')

if [ "$tool" = "Bash" ]; then
  target=$(printf '%s' "$target" | perl -0777 -pe '
    s/<<-?\s*([\x27"]?)(\w+)\1[^\n]*\n.*?\n\s*\2(?=\n|$)/ /gs;  # heredoc bodies
    s/\x27[^\x27]*\x27/ /g;                                     # single-quoted
    s/"(?:\\.|[^"\\])*"/ /g;                                     # double-quoted
  ')
fi

# Ignore the committed template, then look for anything secret-shaped.
scrubbed=${target//.env.example/}

if echo "$scrubbed" | grep -Eq '(^|[^[:alnum:]_])\.env([^[:alnum:]_]|$)|(^|[^[:alnum:]_])secrets/'; then
  echo "Blocked by .claude/hooks/protect-secrets.sh: .env files and secrets/ hold real PII/secrets and are off-limits." >&2
  echo "Use .env.example for key names. Ask the user to check or change real values. See CLAUDE.md > PII and secrets." >&2
  exit 2
fi

exit 0
