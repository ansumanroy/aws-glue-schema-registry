# Creating GitHub Releases

This guide explains how to create GitHub releases with artifacts and documentation for this project.

## Prerequisites

1. **GitHub CLI (gh)**
   - Install from: https://cli.github.com/
   - Authenticate: `gh auth login`

2. **Build Tools**
   - Java 17+ (for Java artifacts)
   - Python 3.8+ (for Python artifacts)
   - Go 1.21+ (for Golang artifacts)
   - Make (for Linux/macOS) or PowerShell (for Windows)

3. **Git Repository**
   - Repository must be initialized
   - Remote origin must be set to GitHub repository

## Quick Start

### Linux/macOS (using Makefile)

```bash
# Create release version 1.0.0
make release VERSION=1.0.0

# Create draft release
make release VERSION=1.0.0 DRAFT=true

# Create prerelease
make release VERSION=1.0.0 PRERELEASE=true

# With custom release notes
make release VERSION=1.0.0 NOTES=RELEASE_NOTES.md
```

### Linux/macOS (using script directly)

```bash
# Basic usage
./scripts/create-release.sh --version 1.0.0

# With release notes
./scripts/create-release.sh --version 1.0.0 --notes "Release notes here"

# Draft release
./scripts/create-release.sh --version 1.0.0 --draft

# Dry run (test without creating release)
./scripts/create-release.sh --version 1.0.0 --dry-run
```

### Windows (using PowerShell)

```powershell
# Basic usage
.\scripts\create-release.ps1 -Version 1.0.0

# With release notes
.\scripts\create-release.ps1 -Version 1.0.0 -Notes "Release notes here"

# Draft release
.\scripts\create-release.ps1 -Version 1.0.0 -Draft

# Dry run (test without creating release)
.\scripts\create-release.ps1 -Version 1.0.0 -DryRun
```

## What Gets Created

The release process:

1. **Builds Artifacts**:
   - Java: Standard JAR and fat JAR (with all dependencies)
   - Python: Wheel and source distribution
   - Golang: Compiled binaries (if applicable)

2. **Generates Documentation**:
   - Java: Javadoc
   - Python: pydoc/HTML documentation
   - Golang: godoc/HTML documentation
   - Packages documentation into archives (tar.gz and zip)

3. **Creates Git Tag**:
   - Tag format: `v1.0.0` (version prefixed with 'v')
   - Annotated tag with release message

4. **Creates GitHub Release**:
   - Release title: "Release v1.0.0"
   - Release notes (custom or auto-generated)
   - Links to tag

5. **Uploads Artifacts**:
   - All JAR files
   - Python packages
   - Golang binaries
   - Documentation archives

## Script Options

### Bash Script (Linux/macOS)

| Option | Description | Default |
|--------|-------------|---------|
| `-v, --version` | Version to release (required) | - |
| `-n, --notes` | Release notes (file or text) | Auto-generated |
| `-d, --draft` | Create as draft release | false |
| `-p, --prerelease` | Mark as prerelease | false |
| `-s, --skip-build` | Skip building artifacts | false |
| `-x, --skip-docs` | Skip generating documentation | false |
| `-t, --skip-tag` | Skip creating Git tag | false |
| `-u, --skip-push` | Skip pushing to GitHub | false |
| `--dry-run` | Test without creating release | false |
| `-h, --help` | Show help message | - |

### PowerShell Script (Windows)

| Option | Description | Default |
|--------|-------------|---------|
| `-Version` | Version to release (required) | - |
| `-Notes` | Release notes (file or text) | Auto-generated |
| `-Draft` | Create as draft release | false |
| `-Prerelease` | Mark as prerelease | false |
| `-SkipBuild` | Skip building artifacts | false |
| `-SkipDocs` | Skip generating documentation | false |
| `-SkipTag` | Skip creating Git tag | false |
| `-SkipPush` | Skip pushing to GitHub | false |
| `-DryRun` | Test without creating release | false |
| `-Help` | Show help message | - |

## Release Notes

### Auto-Generated Notes

If you don't provide release notes, the script generates default notes:

```markdown
## Release v1.0.0

### Changes
- See commit history for details

### Artifacts
- Java JAR files (standard and fat JAR)
- Python wheel and source distribution
- Golang binaries (if applicable)
- Documentation (Javadoc, pydoc, godoc)

### Installation
See README.md for installation instructions.
```

### Custom Release Notes

#### From File

```bash
# Create RELEASE_NOTES.md
cat > RELEASE_NOTES.md << EOF
## Release v1.0.0

### New Features
- Added support for JSON schemas
- Enhanced error handling

### Bug Fixes
- Fixed serialization issue
EOF

# Use in release
./scripts/create-release.sh --version 1.0.0 --notes RELEASE_NOTES.md
```

#### From Command Line

```bash
./scripts/create-release.sh --version 1.0.0 --notes "Release v1.0.0 with new features"
```

## Workflow Examples

### Standard Release

```bash
# 1. Ensure all tests pass
make test

# 2. Create release
make release VERSION=1.0.0

# 3. Verify release on GitHub
# (Check GitHub repository releases page)
```

### Draft Release (for Review)

```bash
# Create draft release
make release VERSION=1.0.0 DRAFT=true

# Review on GitHub, then publish manually
# Or update to published release via GitHub UI
```

### Prerelease (Beta/RC)

```bash
# Create prerelease
make release VERSION=1.0.0-beta.1 PRERELEASE=true
```

### Release with Custom Notes

```bash
# Create release notes file
cat > RELEASE_NOTES.md << EOF
## Release v1.0.0

### Highlights
- Major feature additions
- Performance improvements
- Bug fixes

### Breaking Changes
- API changes (see migration guide)

### Contributors
- @user1
- @user2
EOF

# Create release
make release VERSION=1.0.0 NOTES=RELEASE_NOTES.md
```

## Troubleshooting

### Error: "GitHub CLI (gh) is not installed"

**Solution**: Install GitHub CLI:
```bash
# macOS
brew install gh

# Linux
# See: https://cli.github.com/manual/installation

# Windows
# See: https://cli.github.com/manual/installation
```

### Error: "Not authenticated with GitHub"

**Solution**: Authenticate with GitHub:
```bash
gh auth login
```

### Error: "Could not determine GitHub repository"

**Solution**: Set GITHUB_REPO environment variable:
```bash
export GITHUB_REPO=owner/repo-name
```

Or ensure Git remote is configured:
```bash
git remote add origin https://github.com/owner/repo-name.git
```

### Error: "Tag already exists"

**Solution**: The script will prompt to delete and recreate the tag. Or manually:
```bash
# Delete local tag
git tag -d v1.0.0

# Delete remote tag
git push origin :refs/tags/v1.0.0

# Recreate
git tag -a v1.0.0 -m "Release version 1.0.0"
git push origin v1.0.0
```

### Error: "Build failed"

**Solution**: Ensure all prerequisites are installed:
```bash
# Check Java
java -version  # Should be 17+

# Check Python
python3 --version  # Should be 3.8+

# Check Go
go version  # Should be 1.21+

# Check Make
make --version
```

### Error: "Upload failed"

**Solution**: 
- Check GitHub authentication: `gh auth status`
- Check file sizes (GitHub has limits)
- Ensure release was created successfully
- Check network connectivity

## Best Practices

1. **Semantic Versioning**: Use semantic versioning (MAJOR.MINOR.PATCH)
2. **Test Before Release**: Always run tests before creating a release
3. **Draft First**: Create draft releases for review before publishing
4. **Release Notes**: Write clear, comprehensive release notes
5. **Tag Format**: Use `v` prefix for tags (e.g., `v1.0.0`)
6. **Dry Run**: Use `--dry-run` to test the process first
7. **Version Consistency**: Ensure version matches across all build files

## Release Checklist

Before creating a release:

- [ ] All tests pass (`make test`)
- [ ] Version number updated in all relevant files
- [ ] Documentation is up to date
- [ ] Release notes prepared (or auto-generated)
- [ ] GitHub CLI authenticated (`gh auth status`)
- [ ] Git repository is clean (or intentionally dirty)
- [ ] All changes committed
- [ ] Build succeeds (`make build`)
- [ ] Artifacts are generated correctly

## Post-Release

After creating a release:

1. **Verify Release**:
   - Check GitHub releases page
   - Verify all artifacts are uploaded
   - Test artifact downloads

2. **Update Documentation**:
   - Update README with new version
   - Update changelog
   - Update installation instructions if needed

3. **Announce Release**:
   - Share release notes
   - Notify users
   - Update project status

4. **Clean Up**:
   - Remove `release-artifacts/` directory (optional)
   - Archive release notes

## Additional Resources

- [GitHub CLI Documentation](https://cli.github.com/manual/)
- [Semantic Versioning](https://semver.org/)
- [GitHub Releases API](https://docs.github.com/en/rest/releases/releases)

