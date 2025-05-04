#!/bin/bash
set -euo pipefail

# args: 1=directory, 2=branch, 3=generations
DIRECTORY="$1"
BRANCH="$2"
GENERATIONS="${3:-5}"

# clone repo at target branch (or create it)
REPO_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
CLONE_DIR="$(mktemp -d)"

if git ls-remote --exit-code --heads "$REPO_URL" "$BRANCH" &>/dev/null; then
  git clone --depth=1 --branch "$BRANCH" "$REPO_URL" "$CLONE_DIR"
else
  git clone --depth=1 "$REPO_URL" "$CLONE_DIR"
  cd "$CLONE_DIR"
  git checkout --orphan "$BRANCH"
  git rm -rf .
  git commit --allow-empty -m "Initialize $BRANCH branch"
  git push origin "$BRANCH"
fi

cd "$CLONE_DIR"

# isolate per-workflow: use workflow name as subdir
WORKFLOW_DIR="${GITHUB_WORKFLOW// /_}"
RUN_DIR="runs/${WORKFLOW_DIR}/${GITHUB_RUN_NUMBER}/${DIRECTORY}"
mkdir -p "$RUN_DIR"
cp -r "$GITHUB_WORKSPACE/$DIRECTORY/." "$RUN_DIR/"

# commit and push
git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"

git add "runs/"
git commit -m "Upload files from run ${GITHUB_RUN_NUMBER}" || true

# prune old runs per-workflow
mapfile -t ALL_RUNS < <(find "runs/${WORKFLOW_DIR}" -mindepth 1 -maxdepth 1 -type d | sort -n)
if [ "${#ALL_RUNS[@]}" -gt "$GENERATIONS" ]; then
  REMOVE_COUNT=$(( ${#ALL_RUNS[@]} - GENERATIONS ))
  for OLD in "${ALL_RUNS[@]:0:REMOVE_COUNT}"; do
    git rm -r "$OLD"
  done
  git commit -m "Prune old runs, keep ${GENERATIONS}" || true
fi

# push
git push origin "$BRANCH"

# generate output URLs
FILE_URLS=()
for f in $(find "$RUN_DIR" -type f); do
  REL="${f#*/}"
  URL="https://raw.githubusercontent.com/${GITHUB_REPOSITORY}/${BRANCH}/${REL}"
  FILE_URLS+=("$URL")
done

echo "file_urls=$(IFS=,; echo "${FILE_URLS[*]}")" >> $GITHUB_OUTPUT
