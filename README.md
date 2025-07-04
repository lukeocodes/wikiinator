# Sync Docs to Wiki

[![GitHub Action](https://img.shields.io/badge/GitHub-Action-blue?logo=github)](https://github.com/marketplace/actions/sync-docs-to-wiki)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)

A GitHub Action that automatically synchronizes documentation from your repository to GitHub Wiki whenever changes are made to your docs folder.

## Features

- 🔄 **Automatic Sync**: Syncs documentation files to your GitHub Wiki on every push
- 📁 **Flexible Paths**: Configurable documentation folder path
- 🚫 **File Exclusion**: Exclude specific files from sync (like README.md)
- 🏠 **Home Page Support**: Ensures your wiki has a proper Home.md file
- 🔒 **Dry Run Mode**: Test changes without actually modifying the wiki
- 📊 **Detailed Outputs**: Returns information about files synced and changes made
- 🎨 **Colored Logging**: Beautiful, colored output for better readability

## Quick Start

Add this action to your workflow:

```yaml
name: Sync Docs to Wiki

on:
  push:
    paths:
      - "docs/**"
    branches:
      - main

permissions:
  contents: write

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Sync docs to wiki
        uses: lukeocodes/sync-docs-to-wiki@v1
        with:
          github-token: ${{ github.token }}
```

## Inputs

| Input            | Description                              | Required | Default                    |
| ---------------- | ---------------------------------------- | -------- | -------------------------- |
| `github-token`   | GitHub token with wiki access            | Yes      | None (must be provided)    |
| `docs-path`      | Path to documentation folder             | No       | `docs`                     |
| `exclude-files`  | Comma-separated list of files to exclude | No       | `README.md`                |
| `wiki-home-file` | Name of the file that should be Home.md  | No       | `Home.md`                  |
| `commit-message` | Custom commit message template           | No       | `Sync docs from main repo` |
| `dry-run`        | Run in dry-run mode (no actual changes)  | No       | `false`                    |

## Outputs

| Output         | Description                               |
| -------------- | ----------------------------------------- |
| `files-synced` | Number of files that were synced          |
| `changes-made` | Whether any changes were made to the wiki |

## Examples

### Basic Usage

```yaml
- name: Sync docs to wiki
  uses: lukeocodes/sync-docs-to-wiki@v1
  with:
    github-token: ${{ github.token }}
```

### Custom Configuration

```yaml
- name: Sync docs to wiki
  uses: lukeocodes/sync-docs-to-wiki@v1
  with:
    github-token: ${{ github.token }}
    docs-path: "documentation"
    exclude-files: "README.md,INTERNAL.md"
    wiki-home-file: "Welcome.md"
    commit-message: "Update wiki documentation"
```

### With Outputs

```yaml
- name: Sync docs to wiki
  id: sync
  uses: lukeocodes/sync-docs-to-wiki@v1
  with:
    github-token: ${{ github.token }}

- name: Check sync results
  run: |
    echo "Files synced: ${{ steps.sync.outputs.files-synced }}"
    echo "Changes made: ${{ steps.sync.outputs.changes-made }}"
```

### Dry Run Mode

```yaml
- name: Test sync (dry run)
  uses: lukeocodes/sync-docs-to-wiki@v1
  with:
    github-token: ${{ github.token }}
    dry-run: "true"
```

## Prerequisites

⚠️ **Important**: You must complete these steps before using this action:

### 1. Enable Wiki

- Go to your repository **Settings** → **Features**
- Check the **Wikis** checkbox to enable it

### 2. Initialize Wiki

- Go to your repository's **Wiki** tab
- Click **Create the first page**
- Create any page (e.g., title: "Home", content: "Welcome to the Wiki")
- This initializes the wiki git repository

### 3. Create Home.md

- Ensure you have a `Home.md` file in your docs directory
- This will become your wiki's main page

### 4. Workflow Permissions

- Add `permissions: contents: write` to your workflow
- This grants the action write access to the wiki repository

## File Structure

Your repository should have a structure like this:

```
your-repo/
├── docs/
│   ├── Home.md          # Required: Wiki home page
│   ├── Installation.md  # Will be synced
│   ├── Usage.md         # Will be synced
│   └── README.md        # Excluded by default
└── .github/
    └── workflows/
        └── sync-wiki.yml
```

## Troubleshooting

### ❌ "Failed to clone wiki repository" Error

This is the most common issue. The wiki must be **manually enabled and initialized**:

1. **Enable Wiki Feature**:
   - Go to `Settings` → `Features` → Check `Wikis`
2. **Initialize Wiki**:
   - Go to the `Wiki` tab → Click `Create the first page`
   - Create any page (this creates the wiki git repository)
3. **Verify Setup**:
   - Your wiki URL should be accessible: `https://github.com/YOUR_USERNAME/YOUR_REPO/wiki`

### ❌ Missing Home.md Error

The action requires a `Home.md` file in your docs directory:

- This file becomes your wiki's main page
- Make sure it exists: `docs/Home.md`
- Check the file name capitalization

### ❌ No Changes Detected

If the action runs but no changes are made:

1. **Check File Differences**: Files might be identical to what's already in the wiki
2. **Verify Docs Path**: Ensure `docs-path` parameter points to the correct directory
3. **Check Exclusions**: Make sure your files aren't being excluded by `exclude-files`
4. **File Extensions**: Only `.md` files are synchronized

### ❌ Permission Errors

**Most common fix**: Add `permissions: contents: write` to your workflow

```yaml
permissions:
  contents: write

jobs:
  sync:
    # ... rest of your job
```

Other permission issues:

- If using a custom token, ensure it has `repo` scope
- Organization repositories might have additional restrictions

### 🔍 Debug Mode

Use dry-run mode to test without making changes:

```yaml
- uses: lukeocodes/sync-docs-to-wiki@v1
  with:
    github-token: ${{ github.token }}
    dry-run: "true"
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you find this action helpful, please consider giving it a ⭐ star on GitHub!
