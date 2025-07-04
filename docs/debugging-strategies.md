# Debugging Strategies for GitHub Actions

## The Debugging Challenge

GitHub Actions run in ephemeral environments without direct access for debugging. We learned effective strategies for troubleshooting complex issues.

## Progressive Debugging Approach

### 1. Start with Basic Logging

**Level 1: Basic execution logging**

```bash
echo "Starting action..."
echo "Processing files..."
echo "Action complete"
```

**Level 2: State logging**

```bash
echo "Current directory: $(pwd)"
echo "Files found: $(ls -la)"
echo "Environment variables: $(env | grep INPUT_)"
```

**Level 3: Comprehensive debugging**

```bash
log "Environment information:"
log "  - Working directory: $(pwd)"
log "  - Repository: $GITHUB_REPOSITORY"
log "  - SHA: $GITHUB_SHA"
log "  - Event: $GITHUB_EVENT_NAME"
log "  - GitHub Output: $GITHUB_OUTPUT"
```

### 2. Strategic Information Gathering

**Always log:**

- Input parameters and their values
- File system state at key points
- Command outputs (but sanitize sensitive data)
- Environment variables
- Exit codes and error messages

**Example implementation:**

```bash
log "Configuration:"
log "  - Docs path: $DOCS_PATH"
log "  - Exclude files: $EXCLUDE_FILES"
log "  - Wiki home file: $WIKI_HOME_FILE"
log "  - Dry run: $DRY_RUN"
log "  - Commit message: $COMMIT_MESSAGE"
```

## Command Output Capture Strategies

### 1. Capture Both stdout and stderr

**Basic capture:**

```bash
output=$(command 2>&1)
exit_code=$?
```

**Advanced capture with separation:**

```bash
# Capture stderr separately
exec 3>&1
stderr=$(command 2>&1 1>&3)
exec 3>&-
```

### 2. Git Command Debugging

**Git operations need special handling:**

```bash
# Clone with error capture
if ! git clone "$wiki_url" wiki 2>/dev/null; then
    log_error "Failed to clone wiki repository."
    # Provide specific troubleshooting
fi

# Push with detailed error analysis
push_output=$(git push 2>&1)
push_exit_code=$?

if [ $push_exit_code -ne 0 ]; then
    log_error "Git push failed with exit code: $push_exit_code"
    log_error "Git push output: $push_output"

    # Pattern match for specific errors
    if echo "$push_output" | grep -q "403\|Permission.*denied"; then
        handle_permission_error
    fi
fi
```

### 3. File System State Debugging

**Directory listings at key points:**

```bash
log "Debug: Current directory structure"
ls -la . 2>/dev/null || log_warning "Could not list current directory"

log "Files in docs directory:"
ls -la "$DOCS_PATH/" 2>/dev/null || log_error "Cannot list docs directory"

log "Wiki directory contents:"
ls -la wiki/ 2>/dev/null || log_error "Cannot list wiki directory"
```

## Error Context Preservation

### 1. Save State Before Errors

**Capture environment before failure:**

```bash
debug_info() {
    log "=== DEBUG INFORMATION ==="
    log "Working directory: $(pwd)"
    log "Directory contents:"
    ls -la . 2>/dev/null || log "Cannot list directory"
    log "Git status (if applicable):"
    git status 2>/dev/null || log "Not a git repository or git not available"
    log "Environment variables:"
    env | grep -E "(INPUT_|GITHUB_)" | sort
    log "========================="
}

# Call before any operation that might fail
debug_info
```

### 2. Conditional Debug Output

**Enable verbose debugging via input:**

```yaml
# action.yml
inputs:
  debug:
    description: "Enable debug output"
    required: false
    default: "false"
```

```bash
# In script
if [ "$INPUT_DEBUG" = "true" ]; then
    set -x  # Enable bash debug mode
    debug_info
fi
```

## Token and Security Debugging

### 1. Safe Token Information

**Show token info without exposing it:**

```bash
if [ -n "$INPUT_GITHUB_TOKEN" ]; then
    log "Token info: ${INPUT_GITHUB_TOKEN:0:8}... (${#INPUT_GITHUB_TOKEN} chars)"
else
    log_error "No GitHub token provided"
fi
```

### 2. Git Remote Debugging

**Check remote configuration:**

```bash
log "Git remote configuration:"
git remote -v 2>/dev/null || log_warning "Could not get git remote info"

log "Remote URL (sanitized):"
git remote get-url origin 2>/dev/null | sed 's/:[^@]*@/:***@/' || log_warning "No remote URL"
```

## Performance and Timing Analysis

### 1. Operation Timing

**Measure operation duration:**

```bash
start_time=$(date +%s)
git clone "$wiki_url" wiki
end_time=$(date +%s)
duration=$((end_time - start_time))
log "Clone operation took $duration seconds"
```

### 2. File Processing Metrics

**Track processing statistics:**

```bash
log "Found $md_files markdown files"
log "Processing $files_synced files"
log "Copied $files_synced files to wiki"
```

## GitHub Actions Specific Debugging

### 1. Action Outputs Debugging

**Verify outputs are set correctly:**

```bash
log "Setting GitHub Action outputs"
log "  - files-synced: $files_synced"
log "  - changes-made: $changes_made"

if [ -n "$GITHUB_OUTPUT" ]; then
    echo "files-synced=$files_synced" >> "$GITHUB_OUTPUT"
    echo "changes-made=$changes_made" >> "$GITHUB_OUTPUT"
    log_success "Successfully wrote outputs to $GITHUB_OUTPUT"
else
    log_warning "GITHUB_OUTPUT not set, skipping output generation"
fi
```

### 2. Step Dependencies

**Verify action path and environment:**

```bash
log "Action path: ${{ github.action_path }}"
log "Workspace: ${{ github.workspace }}"
log "Runner temp: ${{ runner.temp }}"
```

## Common Debugging Patterns

### 1. The "Checkpoint" Pattern

**Add checkpoints throughout the script:**

```bash
checkpoint() {
    local name="$1"
    log "CHECKPOINT: $name"
    log "  - PWD: $(pwd)"
    log "  - Files synced so far: $files_synced"
    log "  - Changes made: $changes_made"
}

checkpoint "After clone"
checkpoint "After file processing"
checkpoint "Before commit"
```

### 2. The "State Dump" Pattern

**Dump all relevant state on error:**

```bash
error_state_dump() {
    log_error "=== ERROR STATE DUMP ==="
    log_error "Working directory: $(pwd)"
    log_error "Files synced: $files_synced"
    log_error "Changes made: $changes_made"
    log_error "Last command exit code: $?"
    log_error "Directory contents:"
    ls -la . 2>/dev/null || log_error "Cannot list directory"
    log_error "========================"
}

# Use in error handlers
trap error_state_dump ERR
```

### 3. The "Incremental Validation" Pattern

**Validate state after each major operation:**

```bash
validate_state() {
    local operation="$1"

    log "Validating state after: $operation"

    case "$operation" in
        "clone")
            [ -d "wiki/.git" ] || { log_error "Wiki not cloned properly"; exit 1; }
            ;;
        "copy")
            [ "$files_synced" -gt 0 ] || { log_warning "No files were copied"; }
            ;;
        "commit")
            cd wiki && git log -1 --oneline && cd .. || { log_error "Commit failed"; exit 1; }
            ;;
    esac

    log "State validation passed for: $operation"
}
```

## Testing and Development Debugging

### 1. Local Testing Setup

**Create local test environment:**

```bash
#!/bin/bash
# test-local.sh

export INPUT_GITHUB_TOKEN="your-token"
export INPUT_DOCS_PATH="docs"
export GITHUB_REPOSITORY="user/repo"
export GITHUB_SHA="test-sha"
export GITHUB_EVENT_NAME="push"
export GITHUB_OUTPUT="/tmp/github_output"

./sync-docs.sh
```

### 2. Dry Run Validation

**Use dry run for safe testing:**

```bash
if [ "$DRY_RUN" = "true" ]; then
    log "DRY RUN: Would execute: git push"
    log "DRY RUN: Would commit message: $full_commit_message"
    log "DRY RUN: Files that would be synced: $files_synced"
else
    # Actual operations
fi
```

## Documentation of Debugging Sessions

### 1. Issue Templates

**Create issue templates for common problems:**

```markdown
## Debugging Information

- Action version:
- Repository:
- Workflow file:
- Error message:
- Relevant logs:

## Steps to Reproduce

1.
2.
3.

## Expected vs Actual Behavior

Expected:
Actual:
```

### 2. Troubleshooting Runbook

**Maintain a runbook of common issues:**

- Permission errors and solutions
- Wiki setup problems
- Token configuration issues
- File processing edge cases

These debugging strategies evolved through multiple iterations and real-world usage, dramatically improving our ability to diagnose and resolve issues quickly.
