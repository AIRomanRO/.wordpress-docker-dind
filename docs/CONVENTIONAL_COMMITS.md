# Conventional Commits Guide

This project uses [Conventional Commits](https://www.conventionalcommits.org/) for automatic changelog generation.

## Format

```
<type>[optional scope]: <description>

[optional body]

[optional footer(s)]
```

## Commit Types

| Type | Changelog Section | When to Use | Example |
|------|------------------|-------------|---------|
| `feat` | Added | New feature | `feat(cli): add install command` |
| `fix` | Fixed | Bug fix | `fix(docker): resolve port conflict` |
| `docs` | Documentation | Documentation only | `docs: update installation guide` |
| `style` | Styles | Code formatting | `style: format shell scripts` |
| `refactor` | Refactored | Code restructuring | `refactor(config): simplify env loading` |
| `perf` | Performance | Performance improvement | `perf(images): optimize build time` |
| `test` | Tests | Adding/updating tests | `test(cli): add unit tests` |
| `build` | Build | Build system/dependencies | `build: update Docker base images` |
| `ci` | CI/CD | CI/CD configuration | `ci: add automated changelog` |
| `chore` | Chores | Maintenance tasks | `chore: update dependencies` |

## Common Scopes

For this project, common scopes include:
- `cli` - CLI tool changes
- `docker` - Docker configuration
- `images` - Docker images
- `config` - Configuration files
- `docs` - Documentation
- `workflow` - GitHub workflows

## Examples

### ✅ Good Commits

```bash
feat(cli): add wp-dind install command
fix(docker): resolve MySQL port conflict
docs: update quickstart guide
perf(images): reduce PHP image size
refactor(config): consolidate environment variables
build: upgrade to PHP 8.3
ci: add automated changelog workflow
```

### ❌ Bad Commits

```bash
update stuff
fix bug
WIP
changes
minor updates
```

## Breaking Changes

Add `!` after type or include `BREAKING CHANGE:` in footer:

```bash
# Method 1: Exclamation mark
feat!: change default PHP version to 8.3

# Method 2: Footer
feat(cli): update command structure

BREAKING CHANGE: Command syntax has changed. Use 'wp-dind init' instead of 'wp-dind setup'.
```

## Automated Workflows

### Commit Validation (on PR)

When a PR is opened or updated:

1. **GitHub Action validates** all commit messages in the PR
2. **Checks format** against Conventional Commits pattern
3. **Posts comment** on PR with validation results
4. **Fails the check** if any commits are invalid
5. **Provides guidance** on how to fix invalid commits

### Changelog Generation (on merge)

When a PR is merged to `main` or `master`:

1. **GitHub Action triggers** and fetches all commits from the PR
2. **Commits are parsed** and categorized by type
3. **Changelog entry is generated** with proper formatting
4. **CHANGELOG.md is updated** under the `[Unreleased]` section
5. **Changes are committed** and pushed automatically
6. **PR comment is posted** with the changelog entry

### Example Output

```markdown
### PR #42 - Add new features
_Merged on 2025-11-04_ - [View PR](link)

#### Added
- add wp-dind install command

#### Fixed
- resolve MySQL port conflict

---
```

## Best Practices

1. **Be specific**: Describe what changed, not why
2. **Use imperative mood**: "add feature" not "added feature"
3. **Keep it short**: First line under 72 characters
4. **One change per commit**: Don't mix features and fixes
5. **Use scopes**: Help categorize changes

## Resources

- [Conventional Commits Specification](https://www.conventionalcommits.org/)
- [Semantic Versioning](https://semver.org/)
- [Pull Request Template](PULL_REQUEST_TEMPLATE.md)

