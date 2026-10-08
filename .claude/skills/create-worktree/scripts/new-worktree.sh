#!/usr/bin/env bash
# Create (or reuse) the git worktree for a GitHub issue.
#
# Usage: new-worktree.sh <issue#> [type]
#   type: feat|fix|chore|docs|refactor|test|ci. Inferred from labels when omitted
#         (bug -> fix, enhancement/epic -> feat). Exit 3 if it can't be inferred.
#
# Prints key=value lines on success:
#   issue, title, type, branch, path, status (created|exists)
set -euo pipefail

issue=${1:?usage: new-worktree.sh <issue#> [type]}
type=${2:-}

common_dir=$(git rev-parse --path-format=absolute --git-common-dir)
root=$(dirname "$common_dir")

# Reuse an existing worktree for this issue, whatever its type/slug.
existing=$(git worktree list --porcelain | awk -v n="$issue" '
  /^worktree / { path = substr($0, 10) }
  /^branch / { b = substr($0, 8); sub("refs/heads/", "", b); if (b ~ ("^[a-z]+/" n "-")) { print path "\t" b; exit } }')
if [ -n "$existing" ]; then
  echo "issue=$issue"
  echo "branch=${existing#*$'\t'}"
  echo "path=${existing%%$'\t'*}"
  echo "status=exists"
  exit 0
fi

json=$(gh issue view "$issue" --json state,title,labels)
state=$(jq -r .state <<<"$json")
title=$(jq -r .title <<<"$json")
if [ "$state" != "OPEN" ]; then
  echo "error=issue #$issue is $state" >&2
  exit 1
fi

if [ -z "$type" ]; then
  labels=$(jq -r '.labels[].name' <<<"$json")
  if grep -qx bug <<<"$labels"; then
    type=fix
  elif grep -qxE 'enhancement|epic' <<<"$labels"; then
    type=feat
  else
    echo "error=cannot infer branch type from labels; pass one of feat|fix|chore|docs|refactor|test|ci" >&2
    exit 3
  fi
fi
case "$type" in feat|fix|chore|docs|refactor|test|ci) ;; *) echo "error=bad type '$type'" >&2; exit 2 ;; esac

# Slug: drop a Conventional Commit prefix, lowercase, dash-separate, cap at 40 chars.
slug=$(printf '%s' "$title" \
  | tr '[:upper:]' '[:lower:]' \
  | sed -E 's/^(feat|fix|chore|docs|refactor|test|ci)(\([^)]*\))?:[[:space:]]*//; s/[^a-z0-9]+/-/g; s/^-+//; s/-+$//' \
  | cut -c1-40 | sed -E 's/-+$//')

branch="$type/$issue-$slug"
path="$root/.worktrees/$issue-$slug"

git fetch -q origin main
if git show-ref --verify --quiet "refs/heads/$branch"; then
  git worktree add -q "$path" "$branch"
else
  git worktree add -q --no-track -b "$branch" "$path" origin/main
fi

echo "issue=$issue"
echo "title=$title"
echo "type=$type"
echo "branch=$branch"
echo "path=$path"
echo "status=created"
