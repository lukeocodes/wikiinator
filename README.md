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

jobs:
  sync:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Sync docs to wiki
        uses: lukeocodes/sync-docs-to-wiki@v1
        with:
          github-token: ${{ secrets.GITHUB_TOKEN }}
```

## Inputs

| Input            | Description                              | Required | Default                    |
| ---------------- | ---------------------------------------- | -------- | -------------------------- |
| `github-token`   | GitHub token with wiki access            | Yes      | `${{ github.token }}`      |
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
    github-token: ${{ secrets.GITHUB_TOKEN }}
```

### Custom Configuration

```yaml
- name: Sync docs to wiki
  uses: lukeocodes/sync-docs-to-wiki@v1
  with:
    github-token: ${{ secrets.GITHUB_TOKEN }}
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
    github-token: ${{ secrets.GITHUB_TOKEN }}

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
    github-token: ${{ secrets.GITHUB_TOKEN }}
    dry-run: "true"
```

## Prerequisites

1. **Enable Wiki**: Make sure the wiki is enabled for your repository
2. **Home File**: Ensure you have a `Home.md` file in your docs directory
3. **Permissions**: The action needs write access to the wiki

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

### Wiki Not Found Error

If you get a "Failed to clone wiki repository" error:

1. Make sure the wiki is enabled for your repository
2. Create at least one wiki page manually to initialize the wiki
3. Check that the `GITHUB_TOKEN` has the necessary permissions

### Missing Home.md

The action requires a `Home.md` file in your docs directory. This becomes the main page of your wiki.

### No Changes Detected

If no changes are being made:

1. Check if files are actually different from what's in the wiki
2. Verify the `docs-path` is correct
3. Make sure files aren't being excluded

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you find this action helpful, please consider giving it a ⭐ star on GitHub!
