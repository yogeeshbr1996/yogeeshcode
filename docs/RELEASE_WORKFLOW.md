# Release Workflow

How to version, build, and publish YogeeshCode releases.

## Versioning

We use [Semantic Versioning](https://semver.org/):
- **Patch** (1.0.0 -> 1.0.1): bug fixes, small changes
- **Minor** (1.0.0 -> 1.1.0): new features, backwards compatible
- **Major** (1.0.0 -> 2.0.0): breaking changes

```bash
# Show current version
script/version.sh

# Bump
script/version.sh bump patch
script/version.sh bump minor
script/version.sh bump major

# Set explicit
script/version.sh set 2.0.0
```

## Building

```bash
# Current platform only (fast)
script/yogeesh-build.sh

# All platforms (darwin/linux/win, arm64+x64)
script/yogeesh-build.sh --full

# Specific targets
script/yogeesh-build.sh cli
script/yogeesh-build.sh vscode
script/yogeesh-build.sh cli vscode
```

Output in `release/`:
```
release/
  yogeeshcode-1.0.0-darwin-arm64.zip
  yogeeshcode-1.0.0-darwin-x64.zip
  yogeeshcode-1.0.0-linux-x64.tar.gz
  yogeeshcode-1.0.0-linux-arm64.tar.gz
  yogeeshcode-1.0.0-windows-x64.zip
  yogeeshcode-1.0.0.vsix
  install.sh
  version.txt
```

## Releasing

```bash
# Dry run (build only, no tag)
script/release.sh --dry-run

# Build + tag + push
script/release.sh

# Build + tag + publish to GitHub Releases
script/release.sh --publish

# Re-release same version (force move tag)
script/release.sh --override --publish
```

## Install

```bash
# From local release folder
bash release/install.sh

# From GitHub (one-liner)
curl -fsSL https://raw.githubusercontent.com/yogeeshbr1996/yogeeshcode/yogeeshcode-rebrand/release/install.sh | bash
```

## Checklist Before Release

- [ ] All tests pass: `script/yogeesh-test.sh`
- [ ] Version bumped: `script/version.sh bump patch|minor|major`
- [ ] Changelog updated (if applicable)
- [ ] Build succeeds: `script/yogeesh-build.sh`
- [ ] Release: `script/release.sh --publish`
- [ ] Verify on GitHub Releases page
