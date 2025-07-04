# Error Handling and User Experience in GitHub Actions

## The Challenge: Making Actions User-Friendly

GitHub Actions can fail in many ways, but most error messages are cryptic and unhelpful. We learned how to create actionable, user-friendly error handling.

## Key Lessons Learned

### 1. Fail Fast, Fail Clear

**Bad approach (what we started with):**

- Do all the work first
- Fail at the end with generic error
- User has to debug what went wrong

**Good approach (what we evolved to):**

- Validate requirements early
- Test permissions before doing work
- Provide specific, actionable error messages

### 2. The `set -e` Problem

**The issue:**

```bash
set -e  # Exit on any error
((counter++))  # This can fail and exit the script!
```

**Why it happens:**

- Arithmetic operations can return non-zero exit codes
- `set -e` causes immediate script termination
- Very difficult to debug

**Solutions:**

```bash
# Instead of ((counter++))
counter=$((counter + 1))

# Or disable set -e temporarily
set +e
((counter++))
set -e
```

### 3. Pattern Matching for Error Classification

We learned to detect specific error types:

```bash
# Capture both stdout and stderr
output=$(git push 2>&1)
exit_code=$?

if [ $exit_code -ne 0 ]; then
    # Pattern match to classify the error
    if echo "$output" | grep -q "403\|Permission.*denied\|not authorized"; then
        handle_permission_error
    elif echo "$output" | grep -q "404\|not found\|does not exist"; then
        handle_not_found_error
    else
        handle_generic_error "$output"
    fi
fi
```

### 4. Progressive Error Enhancement

Start with basic errors, then enhance based on user feedback:

#### Level 1: Basic Error

```bash
echo "::error::Failed to push to wiki"
exit 1
```

#### Level 2: Informative Error

```bash
echo "::error::Failed to push to wiki repository"
echo "::error::This is usually a permissions issue"
exit 1
```

#### Level 3: Actionable Error

```bash
log_error "🚨 PERMISSION ERROR DETECTED 🚨"
log_error ""
log_error "QUICK FIX: Add this to your workflow file:"
log_error "permissions:"
log_error "  contents: write"
```

### 5. Visual Error Hierarchy

Use emojis and formatting to create visual hierarchy:

```bash
# Functions for different message types
log_error() {
    echo -e "${RED}[sync-docs]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[sync-docs]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[sync-docs]${NC} $1"
}

# Error messages with visual impact
log_error "🚨 PERMISSION ERROR DETECTED 🚨"
log_error ""
log_error "QUICK FIX: Add this to your workflow file:"
```

### 6. Comprehensive Debug Output

Provide debugging info without overwhelming users:

```bash
log "Environment information:"
log "  - Working directory: $(pwd)"
log "  - Repository: $GITHUB_REPOSITORY"
log "  - SHA: $GITHUB_SHA"
log "  - Event: $GITHUB_EVENT_NAME"

# Show file listings when relevant
log "Files in docs directory:"
ls -la *.md 2>/dev/null || log_warning "No .md files found with ls"
```

### 7. Early Validation Pattern

Validate everything upfront:

```bash
# Check required environment variables
if [ -z "$INPUT_GITHUB_TOKEN" ]; then
    log_error "GitHub token is required"
    exit 1
fi

# Check directory exists
if [ ! -d "$DOCS_PATH" ]; then
    log_error "Documentation directory '$DOCS_PATH' not found!"
    log_error "Available directories:"
    ls -la . 2>/dev/null || log_error "Cannot list current directory"
    exit 1
fi

# Check for files to process
md_files=$(find "$DOCS_PATH" -maxdepth 1 -name "*.md" -type f | wc -l)
if [ "$md_files" -eq 0 ]; then
    log_warning "No markdown files found in '$DOCS_PATH' directory"
    # Set outputs for early exit
    echo "files-synced=0" >> "$GITHUB_OUTPUT"
    echo "changes-made=false" >> "$GITHUB_OUTPUT"
    exit 0
fi
```

### 8. Context-Aware Error Messages

Provide different error messages based on context:

```bash
if [ ! -f "wiki/$WIKI_HOME_FILE" ]; then
    log_error "Wiki home file '$WIKI_HOME_FILE' not found in wiki directory!"
    log_error "Expected file: $(pwd)/wiki/$WIKI_HOME_FILE"
    log_error "Make sure you have a '$WIKI_HOME_FILE' file in your '$DOCS_PATH' directory"

    # Show what files ARE available
    log_error "Files in docs directory:"
    ls -la "$DOCS_PATH/" 2>/dev/null || log_error "Cannot list docs directory"
    exit 1
fi
```

### 9. Documentation Integration

Link errors to documentation:

```bash
log_error "For more help, see: https://github.com/lukeocodes/wikiinator#troubleshooting"
```

### 10. User Experience Principles

#### Progressive Disclosure

- Start with the most likely solution
- Provide more details if needed
- Link to comprehensive docs

#### Actionable Messages

- Always provide a next step
- Include copy-paste solutions
- Show examples, not just descriptions

#### Empathetic Tone

- Acknowledge the frustration
- Use encouraging language
- Make it clear the issue is fixable

## Implementation Example

Our error handling evolution:

```bash
# Before: Cryptic error
git push || exit 1

# After: Comprehensive error handling
push_output=$(git push 2>&1)
push_exit_code=$?

if [ $push_exit_code -ne 0 ]; then
    log_error "Failed to push to wiki repository"
    log_error "Git push output: $push_output"

    if echo "$push_output" | grep -q "403\|Permission.*denied"; then
        # Show visual alert
        log_error ""
        log_error "🚨 PERMISSION ERROR DETECTED 🚨"
        log_error ""

        # Explain the problem
        log_error "This is likely because your workflow doesn't have write permissions."

        # Provide exact solution
        log_error ""
        log_error "QUICK FIX: Add this to your workflow file:"
        log_error ""
        log_error "permissions:"
        log_error "  contents: write"

        # Show complete example
        log_error ""
        log_error "Example workflow:"
        # ... complete workflow example

        # Link to help
        log_error ""
        log_error "For more help, see: https://github.com/lukeocodes/wikiinator#troubleshooting"
    fi

    exit 1
fi
```

This approach transformed user experience from frustrating debugging sessions to quick, guided problem resolution.
