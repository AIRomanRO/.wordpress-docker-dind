# Contributing to WordPress Docker-in-Docker

Thank you for your interest in contributing to this project!

## 🚀 Quick Start

### 1. Fork and Clone

```bash
git clone https://github.com/YOUR_USERNAME/wordpress-docker-dind.git
cd wordpress-docker-dind
```

### 2. Create a Feature Branch

```bash
git checkout -b feat/your-feature-name
# or
git checkout -b fix/bug-description
```

### 3. Make Changes

Follow the project structure and coding standards.

### 4. Commit Using Conventional Commits

```bash
git commit -m "feat(cli): add new command"
git commit -m "fix(docker): resolve port conflict"
git commit -m "docs: update installation guide"
```

### 5. Push and Create PR

```bash
git push origin feat/your-feature-name
```

Then create a Pull Request using the [PR template](docs/PULL_REQUEST_TEMPLATE.md).

## 📝 Commit Message Format

We use [Conventional Commits](https://www.conventionalcommits.org/) for automatic changelog generation.

**Format**: `<type>[optional scope]: <description>`

**Common scopes**: `cli`, `docker`, `images`, `config`, `docs`, `workflow`

**Examples**:
```bash
feat(cli): add wp-dind install command
fix(docker): resolve MySQL port conflict
docs: update quickstart guide
perf(images): reduce PHP image size
```

See [docs/CONVENTIONAL_COMMITS.md](docs/CONVENTIONAL_COMMITS.md) for complete guide.

## 🔄 Development Workflow

1. **Fork and clone** the repository
2. **Create a feature branch** with descriptive name
3. **Make changes** following project conventions
4. **Test locally** to ensure everything works
5. **Commit** using Conventional Commits format
6. **Push** to your fork
7. **Create PR** using the template
8. **Changelog updates automatically** on merge!

## 📖 Resources

- [Conventional Commits Guide](docs/CONVENTIONAL_COMMITS.md)
- [Pull Request Template](docs/PULL_REQUEST_TEMPLATE.md)
- [Project Documentation](docs/README.md)

---

**Thank you for contributing! 🎉**
