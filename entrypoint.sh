#!/bin/bash
set -euo pipefail

# Arguments: 1=directory, 2=branch, 3=generations (default:5)
DIRECTORY="$1"
BRANCH="$2"
GENERATIONS="${3:-5}"

REPO_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
# Use workflow name to isolate runs per workflow
WORKFLOW_DIR="${GITHUB_WORKFLOW// /_}"
# Temporary clone directory
CLONE_DIR="$(mktemp -d)"

# Clone existing branch or initialize new orphan branch
if git ls-remote --exit-code --heads "$REPO_URL" "$BRANCH" &>/dev/null; then
  git clone --depth=1 --branch "$BRANCH" "$REPO_URL" "$CLONE_DIR"
else
  git clone --depth=1 "$REPO_URL" "$CLONE_DIR"
  cd "$CLONE_DIR"
  git checkout --orphan "$BRANCH"
  git rm -rf .
  # Configure git identity for initial commit
  git config user.name "github-actions[bot]"
  git config user.email "github-actions[bot]@users.noreply.github.com"
  git commit --allow-empty -m "Initialize $BRANCH branch"
  git push origin "$BRANCH"
fi

cd "$CLONE_DIR"

# Configure git identity for subsequent commits
git config user.name "github-actions[bot]"
git config user.email "github-actions[bot]@users.noreply.github.com"

# Copy user files into isolated clone
RUN_DIR="runs/${WORKFLOW_DIR}/${GITHUB_RUN_NUMBER}/${DIRECTORY}"
mkdir -p "$RUN_DIR"
cp -r "$GITHUB_WORKSPACE/$DIRECTORY/." "$RUN_DIR/"

# Commit new run
git add "runs/"
git commit -m "Upload files from run $GITHUB_RUN_NUMBER" || true

# Prune old runs
mapfile -t ALL_RUNS < <(find "runs/${WORKFLOW_DIR}" -mindepth 1 -maxdepth 1 -type d | sort -n)
if [ "${#ALL_RUNS[@]}" -gt "$GENERATIONS" ]; then
  REMOVE_COUNT=$(( ${#ALL_RUNS[@]} - GENERATIONS ))
  for OLD in "${ALL_RUNS[@]:0:REMOVE_COUNT}"; do
    git rm -r "$OLD"
  done
  git commit -m "Prune old runs, keep $GENERATIONS" || true
fi

# Push changes back to remote
git push origin "$BRANCH"

# Generate file URLs for output
FILE_URLS=()
while IFS= read -r file; do
  REL="${file#${CLONE_DIR}/}"
  URL="https://raw.githubusercontent.com/${GITHUB_REPOSITORY}/${BRANCH}/${REL}"
  FILE_URLS+=("$URL")
done < <(find "$RUN_DIR" -type f)

echo "file_urls=$(IFS=,; echo "${FILE_URLS[*]}")" >> $GITHUB_OUTPUT
