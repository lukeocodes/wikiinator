## Architecture Overview

This directory contains comprehensive documentation about the architectural decisions, lessons learned, and best practices developed while creating the Sync Docs to Wiki GitHub Action.

## Documentation Structure

### Core Architecture

- **[Architecture](Architecture.md)** - High-level design decisions and overview (this file)
- **[Composite Actions Architecture](Composite-Actions-Architecture.md)** - Deep dive into composite action design patterns

### Implementation Lessons

- **[GitHub Token Handling](GitHub-Token-Handling.md)** - Token management, fallbacks, and validation
- **[Permissions and Security](Permissions-and-Security.md)** - Permission requirements and security best practices
- **[GitHub Wiki Specifics](GitHub-Wiki-Specifics.md)** - Wiki-specific considerations and challenges

### Development Practices

- **[Error Handling and UX](Error-Handling-and-UX.md)** - User-friendly error messages and debugging
- **[Debugging Strategies](Debugging-Strategies.md)** - Troubleshooting and development techniques

## What We Built

### The Final Product

A production-ready GitHub Action that automatically synchronizes markdown documentation from a repository's `docs/` folder to its GitHub Wiki. The action evolved from a simple workflow into a robust, user-friendly tool with comprehensive error handling and permission management.

**Key Features:**

- ✅ Automatic docs-to-wiki synchronization
- ✅ Smart GitHub token handling with fallbacks
- ✅ Early permission detection and clear error messages
- ✅ Configurable file exclusions and paths
- ✅ Dry-run mode for testing
- ✅ Comprehensive logging and debugging support
- ✅ Wiki initialization detection and guidance

### Architecture Evolution

**Phase 1: Basic Workflow**
Started with a simple GitHub workflow that copied files from docs to wiki.

**Phase 2: Action Conversion**
Converted to a reusable composite action with parameterized inputs.

**Phase 3: Error Handling Enhancement**
Added comprehensive error detection, early permission testing, and user-friendly messages.

**Phase 4: Production Hardening**
Implemented security best practices, debugging capabilities, and edge case handling.

## Key Architectural Decisions

### 1. Composite Action over Docker/JavaScript

**Decision**: Use composite action with bash script
**Rationale**:

- Fast startup (no container build)
- Direct git command access
- Easy maintenance and debugging
- Cross-platform compatibility
- Transparent execution

### 2. Single Script Architecture

**Decision**: Consolidate all logic in `sync-docs.sh`
**Benefits**:

- Unified error handling
- Easier state management
- Simpler debugging
- Better control flow
- Atomic operations

### 3. Optional Token with Smart Fallback

**Decision**: Make `github-token` optional with automatic fallback

```yaml
env:
  INPUT_GITHUB_TOKEN: ${{ inputs.github-token || github.token }}
```

**Impact**:

- Zero-configuration usage for most users
- Backward compatibility
- Security through validation
- Flexibility for custom tokens

### 4. Early Permission Detection

**Decision**: Test wiki write permissions before doing work
**Implementation**: Use `git push --dry-run` after clone
**Benefits**:

- Fail fast with clear guidance
- Better user experience
- Reduced frustration
- Actionable error messages

### 5. Progressive Error Enhancement

**Evolution**:

1. Basic error messages
2. Categorized error types
3. Pattern-matched troubleshooting
4. Visual hierarchy and formatting
5. Copy-paste solutions

## Technical Architecture

### Component Structure

```
wikiinator/
├── action.yml                    # Action metadata and inputs
├── sync-docs.sh                  # Main synchronization logic
├── README.md                     # User documentation
├── LICENSE                       # MIT license
└── docs/                         # Architecture documentation
    ├── Architecture.md           # This file
    ├── GitHub-Token-Handling.md  # Token management patterns
    ├── Permissions-and-Security.md # Security considerations
    ├── GitHub-Wiki-Specifics.md  # Wiki-specific challenges
    ├── Composite-Actions-Architecture.md # Action design
    ├── Error-Handling-and-UX.md  # UX patterns
    └── Debugging-Strategies.md   # Development practices
```

### Data Flow

```
User Workflow → GitHub Actions → Composite Action → Bash Script
                                       ↓
Input Validation → Early Permission Test → Wiki Clone
                                       ↓
File Processing → Change Detection → Commit & Push → Outputs
```

### Error Handling Strategy

**Layered Approach**:

1. **Input Validation** - Check required parameters
2. **Environment Verification** - Validate GitHub context
3. **Permission Testing** - Early detection with dry-run
4. **State Validation** - Verify operations succeeded
5. **Pattern Matching** - Classify errors for specific guidance

## Key Innovations

### 1. Permission Error Detection

```bash
if echo "$push_output" | grep -q "403\|Permission.*denied"; then
    # Show specific permission fix with exact YAML
```

### 2. Token Persistence Handling

```bash
# Re-set remote URL before push to ensure token availability
git remote set-url origin "https://x-access-token:${TOKEN}@github.com/${REPO}.wiki.git"
```

### 3. User-Centric Error Messages

```bash
log_error "🚨 PERMISSION ERROR DETECTED 🚨"
log_error "QUICK FIX: Add this to your workflow file:"
log_error "permissions:"
log_error "  contents: write"
```

### 4. Comprehensive State Logging

```bash
log "Environment information:"
log "  - Working directory: $(pwd)"
log "  - Repository: $GITHUB_REPOSITORY"
log "  - Files synced: $files_synced"
```

## Lessons Learned

### Critical Discoveries

1. **Composite actions can't use expressions as defaults** - Required logical OR pattern
2. **Wiki repositories need explicit permissions** - `contents: write` is mandatory
3. **Git may not persist authentication tokens** - Must re-set remote URL before push
4. **Early failure is better than late failure** - Test permissions immediately
5. **Users need actionable guidance** - Generic errors frustrate, specific solutions help

### Best Practices Developed

- Fail fast with clear guidance
- Provide copy-paste solutions
- Use visual hierarchy in error messages
- Log comprehensively but securely
- Test edge cases and document solutions

## Future Considerations

### Planned Enhancements

- Subdirectory support for complex documentation structures
- Relative link transformation for wiki compatibility
- Image and asset handling capabilities
- Incremental sync for large documentation sets

### Alternative Architectures Considered

- **JavaScript Action**: For complex link processing and file transformations
- **Docker Action**: For specialized tools and custom environments
- **Webhook Integration**: For real-time synchronization

## Success Metrics

**User Experience**:

- Zero-configuration usage for 90% of users
- Clear resolution paths for all common errors
- Sub-30-second execution time
- Comprehensive troubleshooting documentation

**Technical Excellence**:

- Robust error handling for all edge cases
- Security-first design principles
- Maintainable and debuggable codebase
- Comprehensive test coverage through real-world usage

This architecture successfully transformed a simple workflow into a production-ready GitHub Action that prioritizes user experience while maintaining technical excellence.
