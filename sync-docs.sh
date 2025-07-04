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
log "Environment information:"
log "  - Working directory: $(pwd)"
log "  - Repository: $GITHUB_REPOSITORY"
log "  - SHA: $GITHUB_SHA"
log "  - Event: $GITHUB_EVENT_NAME"
log "  - GitHub Output: $GITHUB_OUTPUT"
log "Configuration:"
log "  - Docs path: $DOCS_PATH"
log "  - Exclude files: $EXCLUDE_FILES"
log "  - Wiki home file: $WIKI_HOME_FILE"
log "  - Dry run: $DRY_RUN"
log "  - Commit message: $COMMIT_MESSAGE"

# Debug: Show current directory structure
log "Debug: Current directory structure"
ls -la . 2>/dev/null || log_warning "Could not list current directory"

# Check if docs directory exists
if [ ! -d "$DOCS_PATH" ]; then
    log_error "Documentation directory '$DOCS_PATH' not found!"
    log_error "Available directories:"
    ls -la . 2>/dev/null || log_error "Cannot list current directory"
    exit 1
fi

log_success "Documentation directory '$DOCS_PATH' found"

# Check if there are any .md files in docs directory
log "Checking for markdown files in '$DOCS_PATH' directory"
md_files=$(find "$DOCS_PATH" -maxdepth 1 -name "*.md" -type f | wc -l)
log "Found $md_files markdown files"

if [ "$md_files" -eq 0 ]; then
    log_warning "No markdown files found in '$DOCS_PATH' directory"
    log_warning "Directory contents:"
    ls -la "$DOCS_PATH/" 2>/dev/null || log_error "Cannot list docs directory"

    # Set outputs for early exit
    if [ -n "$GITHUB_OUTPUT" ]; then
        echo "files-synced=0" >>"$GITHUB_OUTPUT"
        echo "changes-made=false" >>"$GITHUB_OUTPUT"
        log "Set outputs for early exit"
    fi

    exit 0
fi

log_success "Found $md_files markdown files to process"

# Convert exclude files to array
IFS=',' read -ra EXCLUDE_ARRAY <<<"$EXCLUDE_FILES"

# Clone the wiki repository
log "Cloning wiki repository..."
log "Token info: ${INPUT_GITHUB_TOKEN:0:8}... (${#INPUT_GITHUB_TOKEN} chars)"
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

# Debug: Check git remote configuration
cd wiki
log "Git remote configuration:"
git remote -v 2>/dev/null || log_warning "Could not get git remote info"
cd ..

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
log "Current directory: $(pwd)"
log "Changing to docs directory: $DOCS_PATH"

if ! cd "$DOCS_PATH"; then
    log_error "Failed to change to docs directory: $DOCS_PATH"
    exit 1
fi

log "Successfully changed to docs directory"
log "Files in docs directory:"
ls -la *.md 2>/dev/null || log_warning "No .md files found with ls"

for file in *.md; do
    log "Checking file: $file"

    if [ -f "$file" ]; then
        log "File exists: $file"

        if should_exclude "$file"; then
            log "Skipping excluded file: $file"
            continue
        fi

        log "Processing: $file"
        # Get file size (try different stat formats)
        file_size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null || echo "unknown")
        log "File size: $file_size bytes"

        if [ "$DRY_RUN" = "true" ]; then
            log "DRY RUN: Would copy $file to ../wiki/"
        else
            log "Copying $file to ../wiki/"
            if ! cp "$file" "../wiki/"; then
                log_error "Failed to copy $file to ../wiki/"
                log_error "Source file: $(pwd)/$file"
                log_error "Destination: $(pwd)/../wiki/"
                log_error "Wiki directory contents:"
                ls -la ../wiki/ 2>/dev/null || log_error "Cannot list wiki directory"
                exit 1
            fi
            log_success "Successfully copied $file"
        fi

        log "About to increment files_synced counter"
        files_synced=$((files_synced + 1))
        log "Files synced count: $files_synced"
    else
        log_warning "File not found or not a regular file: $file"
    fi
done

log "Finished file processing loop"
log "Total files processed: $files_synced"
log "Finished processing files, changing back to parent directory"
if ! cd ..; then
    log_error "Failed to change back to parent directory"
    exit 1
fi

# Check if wiki home file exists
log "Checking for wiki home file: wiki/$WIKI_HOME_FILE"
log "Wiki directory contents:"
ls -la wiki/ 2>/dev/null || log_error "Cannot list wiki directory"

if [ ! -f "wiki/$WIKI_HOME_FILE" ]; then
    log_error "Wiki home file '$WIKI_HOME_FILE' not found in wiki directory!"
    log_error "Expected file: $(pwd)/wiki/$WIKI_HOME_FILE"
    log_error "Make sure you have a '$WIKI_HOME_FILE' file in your '$DOCS_PATH' directory"
    log_error "Files in docs directory:"
    ls -la "$DOCS_PATH/" 2>/dev/null || log_error "Cannot list docs directory"
    exit 1
fi

log_success "Found wiki home file: wiki/$WIKI_HOME_FILE"
log_success "Copied $files_synced files to wiki"

# Commit and push to wiki
if [ "$DRY_RUN" = "true" ]; then
    log "DRY RUN: Would commit and push changes"
    changes_made=true
else
    log "Committing changes to wiki..."
    log "Changing to wiki directory"

    if ! cd wiki; then
        log_error "Failed to change to wiki directory"
        exit 1
    fi

    log "Current directory: $(pwd)"

    # Configure git
    log "Configuring git user"
    if ! git config user.name "github-actions[bot]"; then
        log_error "Failed to configure git user.name"
        exit 1
    fi

    if ! git config user.email "github-actions[bot]@users.noreply.github.com"; then
        log_error "Failed to configure git user.email"
        exit 1
    fi

    # Add all files
    log "Adding all files to git"
    if ! git add -A; then
        log_error "Failed to add files to git"
        exit 1
    fi

    # Show git status
    log "Git status:"
    git status 2>/dev/null || log_warning "Could not get git status"

    # Check if there are changes to commit
    if git diff --cached --quiet; then
        log "No changes to commit"
        changes_made=false
    else
        log "Changes detected, committing..."

        # Show what's being committed
        log "Files to be committed:"
        git diff --cached --name-only 2>/dev/null || log_warning "Could not get diff"

        # Create commit message
        full_commit_message="$COMMIT_MESSAGE

Source: $GITHUB_REPOSITORY@$GITHUB_SHA
Triggered by: $GITHUB_EVENT_NAME
Files synced: $files_synced"

        log "Committing with message: $COMMIT_MESSAGE"
        if ! git commit -m "$full_commit_message"; then
            log_error "Failed to commit changes"
            exit 1
        fi

        log "Pushing to wiki repository..."

        # Ensure the remote URL has the token for push
        log "Setting remote URL with token for push"
        git remote set-url origin "https://x-access-token:${INPUT_GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.wiki.git"

        if ! git push; then
            log_error "Failed to push to wiki repository"
            log_error "Remote URL: $(git remote get-url origin 2>/dev/null | sed 's/:[^@]*@/:***@/')"
            exit 1
        fi

        changes_made=true
        log_success "Wiki updated successfully!"
    fi

    log "Changing back to parent directory"
    if ! cd ..; then
        log_error "Failed to change back to parent directory"
        exit 1
    fi
fi

# Set outputs
log "Setting GitHub Action outputs"
log "  - files-synced: $files_synced"
log "  - changes-made: $changes_made"

if [ -n "$GITHUB_OUTPUT" ]; then
    if ! echo "files-synced=$files_synced" >>"$GITHUB_OUTPUT"; then
        log_error "Failed to write files-synced to GITHUB_OUTPUT"
        exit 1
    fi

    if ! echo "changes-made=$changes_made" >>"$GITHUB_OUTPUT"; then
        log_error "Failed to write changes-made to GITHUB_OUTPUT"
        exit 1
    fi

    log_success "Successfully wrote outputs to $GITHUB_OUTPUT"
else
    log_warning "GITHUB_OUTPUT not set, skipping output generation"
fi

if [ "$changes_made" = "true" ]; then
    log_success "Documentation sync completed successfully!"
    log_success "Files synced: $files_synced"
else
    log "No changes were made to the wiki"
fi
