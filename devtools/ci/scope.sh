#!/usr/bin/env bash
# CI test scope: what a change can break, once per change. Needs a
# full-history checkout (fetch-depth 0 / GIT_DEPTH 0). Prints, to
# $GITHUB_OUTPUT on GitHub Actions and to stdout elsewhere (GitLab: eval it):
#   full=true|false    every package: PRs/MRs into main, from release/* or
#                      hotfix/*, manual and scheduled runs, a change to a
#                      workspace-wide file, or no usable base
#   base=<sha>         diff base: merge base with the PR/MR target; on a push,
#                      the last commit this workflow passed on the branch
#                      (GitHub), else the push's before commit
#   version_only=true  the change only bumps `version:` in pubspec.yaml files
#                      and edits CHANGELOG.md, or changes nothing (back-merge)
#   code=true|false    something to test: false for docs-only changes and for
#                      a push of a merged PR/MR, which its PR/MR run tested
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"

full=false base='' candidates='' merged=false
if [[ -n ${GITHUB_ACTIONS:-} ]]; then
  case $GITHUB_EVENT_NAME in
    pull_request)
      [[ $GITHUB_BASE_REF == main || $GITHUB_HEAD_REF == release/* || $GITHUB_HEAD_REF == hotfix/* ]] && full=true
      base=$(git merge-base "origin/$GITHUB_BASE_REF" HEAD) ;;
    push)
      # The merge of a PR: its pull_request run already tested it.
      prs=$(gh api "repos/$GITHUB_REPOSITORY/commits/$GITHUB_SHA/pulls" \
        --jq '[.[] | select(.merged_at)] | length' 2>/dev/null || echo 0)
      [[ $prs =~ ^[1-9] ]] && merged=true
      # A cancelled or failed run must not drop its commits from the next
      # diff: start from the last commit this workflow passed on the branch.
      workflow=$(sed -E 's#^[^/]+/[^/]+/(.*)@.*#\1#' <<<"$GITHUB_WORKFLOW_REF")
      last=$(gh api "repos/$GITHUB_REPOSITORY/actions/workflows/${workflow##*/}/runs?branch=$GITHUB_REF_NAME&event=push&status=success&per_page=1" \
        --jq '.workflow_runs[0].head_sha // empty' 2>/dev/null || true)
      [[ -n $last ]] || echo "::warning::No passing $workflow run found on $GITHUB_REF_NAME (or the API failed); diffing from the push's before commit. Commits of a cancelled earlier run are not retested." >&2
      candidates="$last $(jq -r '.before // empty' "$GITHUB_EVENT_PATH")" ;;
    *) full=true ;;
  esac
elif [[ -n ${GITLAB_CI:-} ]]; then
  case $CI_PIPELINE_SOURCE in
    merge_request_event)
      [[ $CI_MERGE_REQUEST_TARGET_BRANCH_NAME == main || $CI_MERGE_REQUEST_SOURCE_BRANCH_NAME == release/* || $CI_MERGE_REQUEST_SOURCE_BRANCH_NAME == hotfix/* ]] && full=true
      base=$CI_MERGE_REQUEST_DIFF_BASE_SHA ;;
    push)
      # GitLab's default merge commit message ends with "See merge request
      # <project>!<iid>": the MR pipeline tested it. Squash and fast-forward
      # merges have no such message and are tested again.
      [[ ${CI_COMMIT_MESSAGE:-} == *"See merge request "* ]] && merged=true
      candidates=${CI_COMMIT_BEFORE_SHA:-} ;;
    *) full=true ;;
  esac
else
  base=${CI_SCOPE_BASE:-$(git merge-base origin/develop HEAD)} # local try-out
fi
for candidate in $candidates; do
  if [[ -z $base && ! $candidate =~ ^0+$ ]] && git merge-base --is-ancestor "$candidate" HEAD 2>/dev/null; then
    base=$candidate
  fi
done
# No usable base (first push, force push): test everything.
[[ -n $base ]] || { full=true; base=$(git rev-parse HEAD); }

files=$(git diff --name-only "$base" HEAD)

# Workspace-wide inputs reach every package; affected-only tooling cannot
# map them to one.
if grep -qE '^(pubspec\.(yaml|lock)|analysis_options\.yaml|build_prepare\.yaml|flavors\.yaml|devtools/ci/|\.github/workflows/|\.gitlab-ci\.yml$)' <<<"$files"; then
  full=true
fi

version_only=false code=false
if [[ $merged == true ]]; then
  echo "scope: merge of a tested PR/MR, nothing to test" >&2
elif [[ $base == "$(git rev-parse HEAD)" ]]; then
  code=true # manual or scheduled run, or no base: everything
elif [[ -z $files ]]; then
  version_only=true # e.g. a back-merge of a tested release
else
  if ! grep -vqE '(^|/)(pubspec\.yaml|CHANGELOG\.md)$' <<<"$files"; then
    lines=$(git diff -U0 "$base" HEAD -- '*pubspec.yaml' | grep -E '^[+-]' | grep -vE '^(\+\+\+|---) ' || true)
    if [[ -z $lines ]] || ! grep -vqE '^[+-]version: [^ ]+$' <<<"$lines"; then
      version_only=true
    fi
  fi
  if grep -vqE '(\.md$|^docs/)' <<<"$files"; then
    code=true
  fi
fi

out=${GITHUB_OUTPUT:-/dev/stdout}
printf 'full=%s\nbase=%s\nversion_only=%s\ncode=%s\n' "$full" "$base" "$version_only" "$code" >>"$out"
echo "scope: full=$full base=$base version_only=$version_only code=$code, $(grep -c . <<<"$files" || true) changed files" >&2
