# Permissions and Security in GitHub Actions

## The Core Permission Challenge

The biggest issue we encountered was GitHub Actions having insufficient permissions to write to wiki repositories, even though the same token worked in regular workflows.

## Key Lessons Learned

### 1. Default GITHUB_TOKEN Permissions Are Limited

**The problem:**

- By default, `GITHUB_TOKEN` has read-only permissions
- This is a security feature introduced to prevent accidental writes
- Wiki repositories require explicit write permissions

**The symptom:**

```
remote: Permission to user/repo.wiki.git denied to github-actions[bot].
fatal: unable to access 'https://github.com/user/repo.wiki.git/': The requested URL returned error: 403
```

### 2. Repository vs Workflow Permissions

There are two levels of permissions configuration:

#### Repository-Level (Settings → Actions)

```
Settings → Actions → General → Workflow permissions
- Read repository contents and packages permissions (default)
- Read and write permissions ✅ (needed for wikis)
```

#### Workflow-Level (In YAML)

```yaml
permissions:
  contents: write # Required for wiki access
```

**Important:** Both levels must allow write access!

### 3. Early Permission Detection

Instead of failing after doing all the work, we implemented early detection:

```bash
# Test permissions early with dry-run
permission_test_output=$(git push --dry-run 2>&1)
permission_test_exit_code=$?

if [ $permission_test_exit_code -ne 0 ]; then
    if echo "$permission_test_output" | grep -q "403\|Permission.*denied\|not authorized"; then
        echo "::error::Permission error detected early!"
        echo "::error::Add 'permissions: contents: write' to your workflow"
        exit 1
    fi
fi
```

### 4. Clear Error Messages

We learned to provide actionable error messages:

```bash
if echo "$push_output" | grep -q "403\|Permission.*denied\|not authorized"; then
    log_error ""
    log_error "🚨 PERMISSION ERROR DETECTED 🚨"
    log_error ""
    log_error "QUICK FIX: Add this to your workflow file:"
    log_error ""
    log_error "permissions:"
    log_error "  contents: write"
    log_error ""
    log_error "Example workflow:"
    # ... provide complete example
fi
```

### 5. Wiki-Specific Security Considerations

#### Why Wikis Need Special Permissions

- Wikis are separate Git repositories (`.wiki.git`)
- They require push access to update content
- Standard repository permissions don't automatically extend to wikis

#### Token Persistence Issues

- Git may not preserve authentication tokens after clone
- Solution: Re-set the remote URL before push operations

```bash
# Before pushing, ensure token is in remote URL
git remote set-url origin "https://x-access-token:${TOKEN}@github.com/${REPO}.wiki.git"
```

### 6. Security Best Practices

#### Token Handling

- Never log full tokens
- Use partial display for debugging: `${TOKEN:0:8}...`
- Validate token presence early
- Use environment variables, not command-line arguments

#### Minimal Permissions

- Only request `contents: write` (minimal needed permission)
- Don't request broader permissions like `repo` unless absolutely necessary
- Document exactly why each permission is needed

#### Input Validation

- Validate all user inputs
- Sanitize file paths
- Check for directory traversal attempts

## Recommended Implementation Pattern

### 1. Clear Documentation

```yaml
# In your action.yml
permissions:
  contents: write # Required for wiki repository access
```

### 2. Early Detection

- Test permissions immediately after clone
- Fail fast with clear error messages
- Provide copy-paste solutions

### 3. Robust Error Handling

- Pattern match permission errors
- Differentiate between permission vs other errors
- Include troubleshooting links

### 4. Security-First Approach

- Minimal permissions required
- Safe token handling
- Input validation and sanitization

This approach ensures both security and user experience are optimized.
