#!/bin/bash

set -e

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

log_warning() {
    echo -e "${YELLOW}[sync-docs]${NC} $1"
}

log_error() {
    echo -e "${RED}[sync-docs]${NC} $1"
}

# Initialize counters
files_synced=0
changes_made=false

# Validate required inputs
if [ -z "$INPUT_GITHUB_TOKEN" ]; then
    log_error "GitHub token is required"
    exit 1
fi

if [ -z "$GITHUB_REPOSITORY" ]; then
    log_error "GITHUB_REPOSITORY environment variable is required"
    exit 1
fi

# Set default values
DOCS_PATH="${INPUT_DOCS_PATH:-docs}"
EXCLUDE_FILES="${INPUT_EXCLUDE_FILES:-README.md}"
WIKI_HOME_FILE="${INPUT_WIKI_HOME_FILE:-Home.md}"
COMMIT_MESSAGE="${INPUT_COMMIT_MESSAGE:-Sync docs from main repo}"
DRY_RUN="${INPUT_DRY_RUN:-false}"

log "Starting documentation sync..."
log "Docs path: $DOCS_PATH"
log "Exclude files: $EXCLUDE_FILES"
log "Wiki home file: $WIKI_HOME_FILE"
log "Dry run: $DRY_RUN"

# Check if docs directory exists
if [ ! -d "$DOCS_PATH" ]; then
    log_error "Documentation directory '$DOCS_PATH' not found!"
    exit 1
fi

# Check if there are any .md files in docs directory
md_files=$(find "$DOCS_PATH" -maxdepth 1 -name "*.md" -type f | wc -l)
if [ "$md_files" -eq 0 ]; then
    log_warning "No markdown files found in '$DOCS_PATH' directory"
    echo "files-synced=0" >>$GITHUB_OUTPUT
    echo "changes-made=false" >>$GITHUB_OUTPUT
    exit 0
fi

# Convert exclude files to array
IFS=',' read -ra EXCLUDE_ARRAY <<<"$EXCLUDE_FILES"

# Clone the wiki repository
log "Cloning wiki repository..."
wiki_url="https://x-access-token:${INPUT_GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.wiki.git"

if ! git clone "$wiki_url" wiki 2>/dev/null; then
    log_error "Failed to clone wiki repository."
    log_error ""
    log_error "This usually means the wiki is not enabled or initialized for this repository."
    log_error ""
    log_error "To fix this:"
    log_error "1. Go to your repository on GitHub"
    log_error "2. Click on the 'Settings' tab"
    log_error "3. Scroll down to the 'Features' section"
    log_error "4. Check the 'Wikis' checkbox to enable it"
    log_error "5. Go to the 'Wiki' tab and create your first page"
    log_error "   (you can create a simple page with just 'Hello Wiki' as content)"
    log_error ""
    log_error "Repository: https://github.com/${GITHUB_REPOSITORY}"
    log_error "Wiki URL: https://github.com/${GITHUB_REPOSITORY}/wiki"
    log_error "Settings: https://github.com/${GITHUB_REPOSITORY}/settings"
    exit 1
fi

# Verify wiki clone
if [ ! -d "wiki/.git" ]; then
    log_error "Wiki clone failed - .git directory not found!"
    exit 1
fi

log_success "Wiki repository cloned successfully"

# Function to check if file should be excluded
should_exclude() {
    local file="$1"
    for exclude in "${EXCLUDE_ARRAY[@]}"; do
        exclude=$(echo "$exclude" | xargs) # trim whitespace
        if [ "$file" = "$exclude" ]; then
            return 0
        fi
    done
    return 1
}

# Copy docs to wiki
log "Copying documentation files..."
cd "$DOCS_PATH"

for file in *.md; do
    if [ -f "$file" ]; then
        if should_exclude "$file"; then
            log "Skipping excluded file: $file"
            continue
        fi

        log "Processing: $file"

        if [ "$DRY_RUN" = "true" ]; then
            log "DRY RUN: Would copy $file"
        else
            cp "$file" "../wiki/"
        fi

        ((files_synced++))
    fi
done

cd ..

# Check if wiki home file exists
if [ ! -f "wiki/$WIKI_HOME_FILE" ]; then
    log_error "Wiki home file '$WIKI_HOME_FILE' not found in docs directory!"
    log_error "Make sure you have a '$WIKI_HOME_FILE' file in your '$DOCS_PATH' directory"
    exit 1
fi

log_success "Copied $files_synced files to wiki"

# Commit and push to wiki
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

        # Create commit message
        full_commit_message="$COMMIT_MESSAGE

Source: $GITHUB_REPOSITORY@$GITHUB_SHA
Triggered by: $GITHUB_EVENT_NAME
Files synced: $files_synced"

        git commit -m "$full_commit_message"

        log "Pushing to wiki repository..."
        git push

        changes_made=true
        log_success "Wiki updated successfully!"
    fi

    cd ..
fi

# Set outputs
echo "files-synced=$files_synced" >>$GITHUB_OUTPUT
echo "changes-made=$changes_made" >>$GITHUB_OUTPUT

if [ "$changes_made" = "true" ]; then
    log_success "Documentation sync completed successfully!"
    log_success "Files synced: $files_synced"
else
    log "No changes were made to the wiki"
fi
