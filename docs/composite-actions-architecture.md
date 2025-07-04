# Composite Actions Architecture

## Why We Chose Composite Actions

When building this GitHub Action, we had several architecture options. Here's what we learned about composite actions and why we chose them.

## Action Types Comparison

### 1. Docker Actions

```yaml
runs:
  using: "docker"
  image: "Dockerfile"
```

**Pros:**

- Complete control over environment
- Can use any programming language
- Consistent execution environment

**Cons:**

- Slower startup (build container)
- Larger resource usage
- More complex to maintain

### 2. JavaScript Actions

```yaml
runs:
  using: "node20"
  main: "dist/index.js"
```

**Pros:**

- Fast startup
- Rich ecosystem (npm packages)
- Good debugging tools

**Cons:**

- Need to compile/bundle code
- Node.js specific
- Larger repo size with dependencies

### 3. Composite Actions (Our Choice)

```yaml
runs:
  using: "composite"
  steps:
    - shell: bash
      run: ${{ github.action_path }}/script.sh
```

**Pros:**

- Fast startup (no container build)
- Direct shell script execution
- Easy to understand and maintain
- Cross-platform compatible
- No compilation step

**Cons:**

- Limited to shell scripting
- Less programmatic control
- Fewer debugging tools

## Key Architectural Decisions

### 1. Single Script Approach

**What we chose:**

```yaml
runs:
  using: "composite"
  steps:
    - name: Sync Documentation
      shell: bash
      run: ${{ github.action_path }}/sync-docs.sh
```

**Why:**

- All logic in one place
- Easier to debug
- Simpler to maintain
- Better error handling control

**Alternative (multi-step):**

```yaml
runs:
  using: "composite"
  steps:
    - name: Validate inputs
      shell: bash
      run: ${{ github.action_path }}/validate.sh
    - name: Clone wiki
      shell: bash
      run: ${{ github.action_path }}/clone.sh
    - name: Sync files
      shell: bash
      run: ${{ github.action_path }}/sync.sh
```

### 2. Environment Variable Pattern

**Input handling:**

```yaml
# action.yml
env:
  INPUT_GITHUB_TOKEN: ${{ inputs.github-token || github.token }}
  INPUT_DOCS_PATH: ${{ inputs.docs-path }}
  GITHUB_REPOSITORY: ${{ github.repository }}
```

**Benefits:**

- Standard GitHub Actions pattern
- Automatic INPUT\_ prefix
- Easy to access in shell script
- Clear separation of concerns

### 3. Error Handling Strategy

**Composite action limitations:**

- Can't use action-specific error formatting in intermediate steps
- Must rely on shell exit codes
- Limited debugging capabilities

**Our solution:**

```bash
# Use GitHub Actions logging format
echo "::error::Error message"
echo "::warning::Warning message"
echo "::debug::Debug message"

# Custom formatting for better UX
log_error() {
    echo -e "${RED}[sync-docs]${NC} $1"
}
```

### 4. Output Handling

**The challenge:**
Composite actions need to set outputs for the action itself, not just individual steps.

**Our solution:**

```yaml
# action.yml
outputs:
  files-synced:
    description: "Number of files synced"
    value: ${{ steps.sync-docs.outputs.files-synced }}

# In script
echo "files-synced=$files_synced" >> "$GITHUB_OUTPUT"
```

## Lessons Learned

### 1. Path References

**Use action path for scripts:**

```yaml
run: ${{ github.action_path }}/sync-docs.sh
```

**Not relative paths:**

```yaml
run: ./sync-docs.sh # ❌ Won't work
```

### 2. Shell Selection

**Always specify shell:**

```yaml
steps:
  - shell: bash # ✅ Explicit
    run: ${{ github.action_path }}/script.sh
```

**Different shells for different needs:**

- `bash` - Most compatible, rich features
- `sh` - More portable, fewer features
- `pwsh` - PowerShell for Windows compatibility

### 3. File Permissions

**Make scripts executable:**

```bash
chmod +x sync-docs.sh
```

**Or use explicit shell invocation:**

```yaml
run: bash ${{ github.action_path }}/sync-docs.sh
```

### 4. Cross-Platform Considerations

**File paths:**

```bash
# Good - works on all platforms
action_path="${{ github.action_path }}"
script_path="$action_path/sync-docs.sh"

# Bad - Windows issues
script_path="${{ github.action_path }}/sync-docs.sh"
```

**Command compatibility:**

```bash
# Check command availability
if command -v stat >/dev/null 2>&1; then
    file_size=$(stat -c%s "$file" 2>/dev/null || stat -f%z "$file" 2>/dev/null)
else
    file_size="unknown"
fi
```

## Best Practices We Developed

### 1. Structure

```
your-action/
├── action.yml          # Action metadata
├── sync-docs.sh        # Main script (executable)
├── README.md           # User documentation
├── LICENSE            # License file
└── docs/              # Architecture docs
    ├── architecture.md
    └── troubleshooting.md
```

### 2. Input Validation

```bash
# Early validation
if [ -z "$INPUT_GITHUB_TOKEN" ]; then
    echo "::error::GitHub token is required"
    exit 1
fi
```

### 3. Environment Setup

```bash
# Set error handling
set -e  # Exit on error (but be careful with arithmetic)

# Set up logging functions
log() { echo -e "${BLUE}[action]${NC} $1"; }
log_error() { echo -e "${RED}[action]${NC} $1"; }
```

### 4. Clean Exit Handling

```bash
# Always set outputs, even on early exit
cleanup() {
    if [ -n "$GITHUB_OUTPUT" ]; then
        echo "files-synced=${files_synced:-0}" >> "$GITHUB_OUTPUT"
        echo "changes-made=${changes_made:-false}" >> "$GITHUB_OUTPUT"
    fi
}

# Set trap for cleanup
trap cleanup EXIT
```

## When to Choose Composite Actions

**Choose composite actions when:**

- Primary logic is shell-based operations
- Need fast startup times
- Want simple maintenance
- Working with Git operations
- Building utility/automation actions

**Choose JavaScript actions when:**

- Need complex data manipulation
- Want rich error handling
- Building integrations with APIs
- Need npm package dependencies

**Choose Docker actions when:**

- Need specific runtime environment
- Using languages other than JavaScript/Shell
- Need system-level dependencies
- Building complex, stateful applications

Our choice of composite actions proved ideal for a Git-based documentation synchronization tool.
