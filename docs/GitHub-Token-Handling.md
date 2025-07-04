## The Problem We Solved

When creating this GitHub Action, we encountered several token-related issues that are common when building composite actions that need authentication.

## Key Lessons Learned

### 1. Composite Actions Cannot Use Expressions as Defaults

**What doesn't work:**

```yaml
inputs:
  github-token:
    description: "GitHub token"
    required: true
    default: ${{ github.token }} # ❌ This fails silently!
```

**Why it fails:**

- Composite actions don't support expressions in the `default` field
- The token becomes `undefined` or empty
- No error is thrown - it just silently fails

**The solution:**

```yaml
inputs:
  github-token:
    description: "GitHub token"
    required: false # Make it optional

# In the action step:
env:
  INPUT_GITHUB_TOKEN: ${{ inputs.github-token || github.token }}
```

### 2. Different Token References

We learned the distinction between different token references:

- `${{ secrets.GITHUB_TOKEN }}` - Traditional way, still works
- `${{ github.token }}` - Modern way, equivalent functionality
- Both have the same permissions and capabilities

### 3. Smart Fallback Pattern

The best pattern we discovered:

```yaml
# action.yml
inputs:
  github-token:
    description: "GitHub token. Optional - defaults to github.token"
    required: false

runs:
  using: "composite"
  steps:
    - name: Run action
      shell: bash
      run: ${{ github.action_path }}/script.sh
      env:
        INPUT_GITHUB_TOKEN: ${{ inputs.github-token || github.token }}
```

**Benefits:**

- Users don't need to explicitly pass a token
- Still allows custom tokens if needed
- Backward compatible
- Clear documentation about optionality

### 4. Token Validation

Always validate the token is available:

```bash
if [ -z "$INPUT_GITHUB_TOKEN" ]; then
    echo "::error::GitHub token is required"
    exit 1
fi
```

### 5. Token Debugging (Security-Safe)

Show token info without exposing it:

```bash
# Show first 8 characters and length for debugging
echo "Token info: ${INPUT_GITHUB_TOKEN:0:8}... (${#INPUT_GITHUB_TOKEN} chars)"
```

## Implementation Example

Our final implementation:

1. **Optional input** with clear description
2. **Logical OR fallback** in environment variable
3. **Early validation** in script
4. **Debug-friendly logging** without security risks

This pattern makes the action both user-friendly (no token required in most cases) and flexible (custom token supported when needed).
