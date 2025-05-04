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

# Check if branch exists on remote
if git ls-remote --exit-code --heads origin "$BRANCH" > /dev/null; then
    # Branch exists remotely, fetch and checkout
    git fetch origin "$BRANCH"
    git checkout "$BRANCH"
else
    echo "Branch $BRANCH does not exist. Creating empty base branch..."

    # Create a blank commit as the initial base
    git checkout --orphan "$BRANCH"
    git rm -rf .
    touch .gitkeep
    git add .gitkeep
    git commit -m "Initial empty commit for $BRANCH"
    git push origin "$BRANCH"
fi

# Create directory for this run
RUN_NUMBER=$GITHUB_RUN_NUMBER
RUN_DIR="runs/$RUN_NUMBER/$DIRECTORY"
mkdir -p "$RUN_DIR"

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

# Generate file URLs for the current run using raw.githubusercontent.com
FILE_URLS=""
for file in $(find "$RUN_DIR" -type f -not -path "./.git/*"); do
    file=${file#./}
    file_url="https://raw.githubusercontent.com/${GITHUB_REPOSITORY}/${BRANCH}/$file"
    FILE_URLS="$FILE_URLS,$file_url"
done
FILE_URLS=${FILE_URLS#,}

# Set output
echo "file_urls=$FILE_URLS" >> $GITHUB_OUTPUT
