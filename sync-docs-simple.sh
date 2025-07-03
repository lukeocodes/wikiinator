#!/bin/bash

# Simple version closer to original workflow
# Remove set -e to be like original

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to log messages
log() {
    echo -e "${BLUE}[sync-docs]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[sync-docs]${NC} $1"
}

log_error() {
    echo -e "${RED}[sync-docs]${NC} $1"
}

# Initialize counters
files_synced=0
changes_made=false

# Set default values (like original)
DOCS_PATH="${INPUT_DOCS_PATH:-docs}"
EXCLUDE_FILES="${INPUT_EXCLUDE_FILES:-README.md}"
WIKI_HOME_FILE="${INPUT_WIKI_HOME_FILE:-Home.md}"
COMMIT_MESSAGE="${INPUT_COMMIT_MESSAGE:-Sync docs from main repo}"
DRY_RUN="${INPUT_DRY_RUN:-false}"

log "Starting documentation sync..."
log "Docs path: $DOCS_PATH"
log "Exclude files: $EXCLUDE_FILES"

# Check if docs directory exists
if [ ! -d "$DOCS_PATH" ]; then
    log_error "Documentation directory '$DOCS_PATH' not found!"
    exit 1
fi

# Clone the wiki repository (like original)
log "Cloning wiki repository..."
wiki_url="https://x-access-token:${INPUT_GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.wiki.git"
git clone "$wiki_url" wiki

# Verify wiki clone (like original)
if [ ! -d "wiki/.git" ]; then
    log_error "Wiki clone failed - .git directory not found!"
    exit 1
fi

log_success "Wiki repository cloned successfully"

# Copy docs to wiki (like original but with exclude logic)
log "Copying documentation files..."
cd "$DOCS_PATH"

for file in *.md; do
    if [ "$file" != "$EXCLUDE_FILES" ] && [ -f "$file" ]; then
        log "Copying: $file"
        cp "$file" ../wiki/
        files_synced=$((files_synced + 1))
    fi
done

cd ..

# Ensure Home.md exists (like original)
if [ ! -f "wiki/$WIKI_HOME_FILE" ]; then
    log_error "Wiki home file '$WIKI_HOME_FILE' not found!"
    exit 1
fi

log_success "Copied $files_synced files to wiki"

# Commit and push to wiki (like original)
if [ "$DRY_RUN" = "true" ]; then
    log "DRY RUN: Would commit and push changes"
    changes_made=true
else
    log "Committing changes to wiki..."
    cd wiki

    # Configure git
    git config user.name "github-actions[bot]"
    git config user.email "github-actions[bot]@users.noreply.github.com"

    # Add all files
    git add -A

    # Check if there are changes to commit
    if git diff --cached --quiet; then
        log "No changes to commit"
        changes_made=false
    else
        log "Changes detected, committing..."
        git commit -m "$COMMIT_MESSAGE

Source: $GITHUB_REPOSITORY@$GITHUB_SHA
Triggered by: $GITHUB_EVENT_NAME
Files synced: $files_synced"

        if git push; then
            changes_made=true
            log_success "Wiki updated successfully!"
        else
            log_error "Failed to push to wiki repository!"
            log_error "This is usually a permissions issue. Check:"
            log_error "1. Repository Settings → Actions → Workflow permissions"
            log_error "2. Make sure 'Read and write permissions' is enabled"
            log_error "3. Wiki is enabled in repository Features"
            exit 1
        fi
    fi

    cd ..
fi

# Set outputs
if [ -n "$GITHUB_OUTPUT" ]; then
    echo "files-synced=$files_synced" >>"$GITHUB_OUTPUT"
    echo "changes-made=$changes_made" >>"$GITHUB_OUTPUT"
fi

log_success "Documentation sync completed!"
log_success "Files synced: $files_synced"
