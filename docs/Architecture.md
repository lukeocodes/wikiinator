# Architecture Documentation

## Overview

The Sync Docs to Wiki GitHub Action is designed as a composite action that uses a bash script to handle the synchronization logic. This architectural decision was made to provide flexibility and maintainability while keeping the action lightweight.

## Components

### 1. Action Metadata (`action.yml`)

The main entry point that defines:

- Input parameters with defaults
- Output values
- Execution method (composite action)
- Branding and metadata

### 2. Sync Script (`sync-docs.sh`)

The core logic implemented in bash for:

- Cross-platform compatibility
- Direct git operations
- File system operations
- Error handling and logging

## Design Decisions

### Composite Action vs Docker/JavaScript

**Chosen**: Composite Action with bash script

**Rationale**:

- Faster startup time (no container build or Node.js runtime)
- Direct access to git commands
- Simpler deployment and maintenance
- Platform independence

### Input Validation

All inputs are validated at runtime with sensible defaults:

- Required inputs fail fast with clear error messages
- Optional inputs have documented defaults
- File existence checks prevent silent failures

### Error Handling

The script uses `set -e` for fail-fast behavior and provides:

- Colored output for better UX
- Detailed error messages
- Proper exit codes
- Cleanup on failure

### Security Considerations

- Token passed via environment variables (not command line)
- No sensitive data in logs
- Proper git credential handling
- Input sanitization for file paths

## Flow Diagram

```
Start
  ↓
Validate Inputs
  ↓
Check docs directory exists
  ↓
Clone wiki repository
  ↓
Copy files (excluding specified files)
  ↓
Verify Home.md exists
  ↓
Commit changes (if any)
  ↓
Push to wiki
  ↓
Set outputs
  ↓
End
```

## Future Enhancements

1. Support for subdirectories
2. Custom file transformation (e.g., relative links)
3. Backup and rollback capabilities
4. Integration with other documentation tools
