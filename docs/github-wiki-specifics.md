# GitHub Wiki Specifics

## What We Learned About GitHub Wikis

GitHub Wikis have unique characteristics that significantly impacted our action design. Here are the key insights we discovered.

## Wiki Repository Structure

### 1. Separate Git Repository

**Key insight:** Wikis are completely separate Git repositories with `.wiki.git` suffix.

```
Main repo:     https://github.com/user/repo.git
Wiki repo:     https://github.com/user/repo.wiki.git
```

**Implications:**

- Different clone URLs
- Separate permission requirements
- Independent Git history
- Different branch structure (usually just `master`)

### 2. File Naming Conventions

**Home page requirement:**

- Must have a `Home.md` file
- This becomes the wiki's main page
- Case-sensitive filename

**File processing:**

```bash
# Our validation
if [ ! -f "wiki/$WIKI_HOME_FILE" ]; then
    log_error "Wiki home file '$WIKI_HOME_FILE' not found!"
    exit 1
fi
```

### 3. File Structure Differences

**Wiki repository contents:**

```
repo.wiki/
├── .git/           # Git metadata
├── Home.md         # Required: Main wiki page
├── Page-1.md       # Wiki pages (hyphens, not spaces)
└── Page-2.md       # More pages
```

**Note:** Wiki URLs convert spaces to hyphens automatically.

## Authentication Challenges

### 1. Token Requirements

**Wiki-specific permissions:**

- Wikis require `contents: write` permission
- Standard repository permissions don't automatically extend to wikis
- Token must be explicitly passed to wiki operations

**Our solution:**

```bash
wiki_url="https://x-access-token:${INPUT_GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.wiki.git"
```

### 2. Token Persistence Issues

**The problem:**
Git doesn't always preserve authentication tokens after clone operations.

**Why it happens:**

- Git may strip credentials from remote URLs for security
- Different Git versions handle this differently
- Wiki repositories have stricter security

**Our solution:**

```bash
# Re-set remote URL before push operations
git remote set-url origin "https://x-access-token:${INPUT_GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.wiki.git"
```

## Wiki Initialization Requirements

### 1. Manual Initialization Required

**The challenge:**

- Wikis must be manually enabled in repository settings
- At least one page must be created manually
- This creates the `.wiki.git` repository

**Detection logic:**

```bash
if ! git clone "$wiki_url" wiki 2>/dev/null; then
    log_error "Failed to clone wiki repository."
    log_error "This usually means the wiki is not enabled or initialized."
    log_error ""
    log_error "To fix this:"
    log_error "1. Go to your repository on GitHub"
    log_error "2. Click on the 'Settings' tab"
    log_error "3. Scroll down to the 'Features' section"
    log_error "4. Check the 'Wikis' checkbox to enable it"
    log_error "5. Go to the 'Wiki' tab and create your first page"
    exit 1
fi
```

### 2. Wiki vs Repository State

**Important distinction:**

- Repository can exist without wiki
- Wiki cannot exist without repository
- Wiki can be disabled even if it previously existed

## Content Synchronization Patterns

### 1. File Filtering

**Our approach:**

```bash
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
```

**Default exclusions:**

- `README.md` (usually repository-specific)
- Files starting with `.` (hidden files)
- Non-markdown files (wikis are markdown-focused)

### 2. Content Processing

**What we learned:**

- Wikis support GitHub Flavored Markdown
- Relative links may need adjustment
- Images must be handled separately (not implemented in our action)
- Wiki pages support limited HTML

**File copying approach:**

```bash
for file in *.md; do
    if [ -f "$file" ] && ! should_exclude "$file"; then
        cp "$file" "../wiki/"
        files_synced=$((files_synced + 1))
    fi
done
```

## Wiki-Specific Git Operations

### 1. Branch Handling

**Wiki characteristics:**

- Usually only has `master` branch
- No complex branching strategies needed
- Direct push to master is normal

**Our implementation:**

```bash
# Simple push - no branch switching needed
git add -A
git commit -m "$COMMIT_MESSAGE"
git push
```

### 2. Commit Messages

**Best practices for wiki commits:**

```bash
full_commit_message="$COMMIT_MESSAGE

Source: $GITHUB_REPOSITORY@$GITHUB_SHA
Triggered by: $GITHUB_EVENT_NAME
Files synced: $files_synced"
```

**Why detailed commit messages matter:**

- Wiki history is separate from main repository
- Provides traceability back to source changes
- Helps with debugging sync issues

## Performance Considerations

### 1. Wiki Size Limitations

**What we discovered:**

- Wikis can become large over time
- Clone operations can be slow for large wikis
- Consider incremental sync for very large documentation sets

### 2. Optimization Strategies

**Our approach:**

```bash
# Check if changes exist before committing
if git diff --cached --quiet; then
    log "No changes to commit"
    changes_made=false
else
    # Only commit and push if there are actual changes
    git commit -m "$full_commit_message"
    git push
    changes_made=true
fi
```

## Common Wiki Pitfalls

### 1. Case Sensitivity

**Issue:** Wiki filenames are case-sensitive
**Solution:** Consistent naming conventions in documentation

### 2. Special Characters

**Issue:** Some characters in filenames cause issues
**Solution:** Stick to alphanumeric, hyphens, and underscores

### 3. Large File Handling

**Issue:** Wikis aren't designed for large binary files
**Solution:** Keep wikis text-focused, use main repository for assets

### 4. Link Management

**Issue:** Internal links may break when syncing from repository
**Future consideration:** Parse and adjust relative links during sync

## Wiki URL Patterns

**Understanding wiki URLs:**

```
Repository:  https://github.com/user/repo
Wiki:        https://github.com/user/repo/wiki
Page:        https://github.com/user/repo/wiki/Page-Name
Edit:        https://github.com/user/repo/wiki/Page-Name/_edit
```

**File to URL mapping:**

```
Home.md      → /wiki
About.md     → /wiki/About
User Guide.md → /wiki/User-Guide  (spaces become hyphens)
```

## Best Practices We Developed

### 1. Validation Strategy

- Always check wiki existence before operations
- Validate required files (Home.md)
- Provide clear setup instructions on failure

### 2. Error Recovery

- Detect common wiki setup issues
- Provide step-by-step resolution guidance
- Link to relevant GitHub documentation

### 3. User Communication

- Explain wiki-specific requirements clearly
- Differentiate wiki issues from general Git issues
- Provide wiki-specific troubleshooting steps

These wiki-specific considerations shaped many of our architectural decisions and error handling strategies.
