#!/bin/bash

# Get input parameters
DIRECTORY="$1"
BRANCH="$2"
GENERATIONS="$3"

# Add workspace as safe directory
git config --global --add safe.directory /github/workspace

# Set up git configuration
git config --global user.name "github-actions[bot]"
git config --global user.email "github-actions[bot]@users.noreply.github.com"

# Configure git to use the token
git remote set-url origin "https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"

# Create or switch to the target branch
git checkout -b "$BRANCH" || git checkout "$BRANCH"

# Get the current action run number
RUN_NUMBER=$GITHUB_RUN_NUMBER

# Create directory for this run
RUN_DIR="runs/$RUN_NUMBER"
mkdir -p "$RUN_DIR"

# Remove any existing files in the run directory to avoid conflicts
rm -rf "$RUN_DIR"/*

# Copy files from the specified directory to the run directory
cp -r "$DIRECTORY"/* "$RUN_DIR/"

# Stage only the runs directory
git add runs/

# Commit changes
git commit -m "Upload files from GitHub Action run $RUN_NUMBER"

# Get all run directories and sort them numerically
RUN_DIRS=$(find runs -maxdepth 1 -type d -name '[0-9]*' | sort -n)

# Count the number of run directories
RUN_COUNT=$(echo "$RUN_DIRS" | wc -l)

# Remove old generations if we have more than the specified number
if [ "$RUN_COUNT" -gt "$GENERATIONS" ]; then
    # Calculate how many directories to remove
    REMOVE_COUNT=$((RUN_COUNT - GENERATIONS))
    
    # Get the oldest directories to remove
    OLD_DIRS=$(echo "$RUN_DIRS" | head -n "$REMOVE_COUNT")
    
    # Remove the old directories
    for dir in $OLD_DIRS; do
        git rm -r "$dir"
    done
    
    # Commit the removal
    git commit -m "Remove old generations, keeping only $GENERATIONS generations"
fi

# Push to the target branch
git push origin "$BRANCH" --force

# Get the repository URL
REPO_URL=$(git config --get remote.origin.url)
REPO_URL=${REPO_URL/git@github.com:/https://github.com/}
REPO_URL=${REPO_URL%.git}

# Generate file URLs for the current run
FILE_URLS=""
for file in $(find "$RUN_DIR" -type f -not -path "./.git/*"); do
    file=${file#./}
    file_url="$REPO_URL/blob/$BRANCH/$file"
    FILE_URLS="$FILE_URLS,$file_url"
done
FILE_URLS=${FILE_URLS#,}

# Set output
echo "file_urls=$FILE_URLS" >> $GITHUB_OUTPUT 