---
sidebar_position: 7
---

# Contributing

Thank you for your interest in contributing to awsutils! This guide will help you get started with contributing to the project.

## Code of Conduct

We are committed to providing a welcoming and inclusive environment. All contributors are expected to:

- Be respectful and professional
- Welcome newcomers and help them get started
- Accept constructive criticism gracefully
- Focus on what is best for the community
- Show empathy towards other community members

## Ways to Contribute

There are many ways to contribute to awsutils:

### 1. Report Bugs

Found a bug? Help us fix it:

- Check if the issue already exists in [GitHub Issues](https://github.com/awsutils/awsutils.github.io/issues)
- Create a new issue with:
  - Clear, descriptive title
  - Steps to reproduce
  - Expected vs actual behavior
  - Environment details (OS, AWS CLI version, etc.)
  - Any relevant logs or error messages

**Bug Report Template:**

```markdown
## Description

Brief description of the issue

## Steps to Reproduce

1. Step one
2. Step two
3. Step three

## Expected Behavior

What you expected to happen

## Actual Behavior

What actually happened

## Environment

- OS: [e.g., Ubuntu 22.04, macOS 13.0]
- AWS CLI Version: [e.g., 2.13.0]
- Script/Tool: [e.g., eksctl.sh]
- AWS Region: [e.g., us-east-1]

## Additional Context

Any other relevant information, logs, or screenshots
```

### 2. Suggest Features

Have an idea for improvement?

- Search existing issues to avoid duplicates
- Open a feature request issue
- Describe the problem you're trying to solve
- Explain your proposed solution
- Discuss alternatives you've considered

**Feature Request Template:**

```markdown
## Problem Statement

What problem does this feature solve?

## Proposed Solution

Describe your proposed solution

## Alternatives Considered

What other solutions did you consider?

## Additional Context

Any other relevant information
```

### 3. Improve Documentation

Documentation improvements are always welcome:

- Fix typos or unclear explanations
- Add examples or tutorials
- Improve existing documentation
- Translate documentation

### 4. Submit Code

Ready to contribute code? Great! Follow the guidelines below.

## Getting Started

### Prerequisites

Before you start contributing, ensure you have:

- Git installed
- AWS CLI installed and configured
- Basic knowledge of Bash scripting
- Familiarity with AWS services
- Node.js (for documentation site)

### Fork and Clone

1. **Fork the repository** on GitHub

2. **Clone your fork:**

   ```bash
   git clone https://github.com/YOUR-USERNAME/awsutils.github.io.git
   cd awsutils.github.io
   ```

3. **Add upstream remote:**

   ```bash
   git remote add upstream https://github.com/awsutils/awsutils.github.io.git
   ```

4. **Verify remotes:**
   ```bash
   git remote -v
   ```

### Set Up Development Environment

1. **Install dependencies (for documentation):**

   ```bash
   npm install
   ```

2. **Start local development server:**

   ```bash
   npm start
   ```

3. **Build documentation:**
   ```bash
   npm run build
   ```

## Development Workflow

### 1. Create a Branch

Always create a new branch for your changes:

```bash
# Update main branch
git checkout main
git pull upstream main

# Create feature branch
git checkout -b feature/your-feature-name

# Or for bug fixes
git checkout -b fix/bug-description
```

**Branch naming conventions:**

- `feature/feature-name` - New features
- `fix/bug-description` - Bug fixes
- `docs/description` - Documentation changes
- `refactor/description` - Code refactoring
- `test/description` - Test additions or changes

### 2. Make Your Changes

#### For Scripts

- Follow existing code style
- Add comments for complex logic
- Include error handling
- Support common command-line options (`--help`, `--dry-run`, etc.)
- Make scripts idempotent when possible

**Script template:**

```bash
#!/bin/bash
set -euo pipefail

# Script: script-name.sh
# Description: Brief description of what this script does
# Usage: ./script-name.sh [OPTIONS] [ARGUMENTS]
# Requirements: AWS CLI, jq

# Default values
DRY_RUN=false
VERBOSE=false
REGION="${AWS_REGION:-us-east-1}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Functions
log_info() {
    echo -e "${GREEN}[INFO]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

show_help() {
    cat <<EOF
Usage: $0 [OPTIONS] [ARGUMENTS]

Description of what this script does.

Options:
    -r, --region REGION    AWS region (default: us-east-1)
    -d, --dry-run         Simulate execution
    -v, --verbose         Enable verbose output
    -h, --help           Show this help message

Examples:
    $0 --region us-west-2
    $0 --dry-run

Requirements:
    - AWS CLI
    - jq
    - Appropriate AWS permissions

EOF
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -r|--region)
            REGION="$2"
            shift 2
            ;;
        -d|--dry-run)
            DRY_RUN=true
            shift
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            show_help
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            show_help
            exit 1
            ;;
    esac
done

# Check prerequisites
command -v aws >/dev/null 2>&1 || { log_error "AWS CLI not found"; exit 1; }
command -v jq >/dev/null 2>&1 || { log_error "jq not found"; exit 1; }

# Verify AWS credentials
aws sts get-caller-identity >/dev/null 2>&1 || { log_error "AWS credentials not configured"; exit 1; }

# Main script logic
main() {
    log_info "Starting script..."

    if [ "$DRY_RUN" = true ]; then
        log_info "DRY RUN MODE - No changes will be made"
    fi

    # Your script logic here

    log_info "Script completed successfully"
}

# Run main function
main "$@"
```

#### For Documentation

- Use clear, concise language
- Include code examples
- Add cross-references to related docs
- Follow the existing documentation structure

### 3. Test Your Changes

**For scripts:**

```bash
# Run shellcheck for syntax checking
shellcheck script.sh

# Test basic functionality
./script.sh --help

# Test dry run mode
./script.sh --dry-run

# Test actual execution (in safe environment)
./script.sh

# Test error handling
./script.sh --invalid-option
```

**For documentation:**

```bash
# Build documentation
npm run build

# Check for broken links
npm run build 2>&1 | grep -i "broken"

# Preview locally
npm start
```

### 4. Commit Your Changes

Write clear, descriptive commit messages:

```bash
git add .
git commit -m "Add feature: brief description

Detailed explanation of what changed and why.
Reference any related issues.

Fixes #123"
```

**Commit message guidelines:**

- Use present tense ("Add feature" not "Added feature")
- Keep first line under 72 characters
- Provide detailed description after blank line
- Reference issues and PRs when applicable

**Commit message examples:**

```
Add S3 bucket backup script

Implements automated backup script for S3 buckets with:
- Support for cross-region replication
- Configurable retention policies
- Dry-run mode for testing

Fixes #42
```

```
Fix credential timeout issue in eksctl script

The script was failing when temporary credentials expired.
Now checks credential validity before execution and
provides clear error messages.

Closes #78
```

### 5. Push to Your Fork

```bash
git push origin feature/your-feature-name
```

### 6. Create Pull Request

1. Go to your fork on GitHub
2. Click "New Pull Request"
3. Select your branch
4. Fill out the PR template
5. Submit the pull request

**Pull Request Template:**

```markdown
## Description

Brief description of changes

## Type of Change

- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring
- [ ] Other (please describe)

## Testing

Describe how you tested your changes

## Checklist

- [ ] Code follows project style guidelines
- [ ] Self-review completed
- [ ] Comments added for complex code
- [ ] Documentation updated
- [ ] No new warnings generated
- [ ] Tests added/updated as needed
- [ ] All tests pass locally

## Related Issues

Fixes #(issue number)

## Screenshots (if applicable)

Add screenshots to help explain your changes
```

## Code Style Guidelines

### Bash Scripts

- Use 4 spaces for indentation (no tabs)
- Maximum line length: 100 characters
- Use meaningful variable names
- Quote variables: `"$variable"` not `$variable`
- Use `[[ ]]` for conditions, not `[ ]`
- Use `$()` for command substitution, not backticks
- Use lowercase for local variables
- Use UPPERCASE for constants and environment variables

**Example:**

```bash
#!/bin/bash
set -euo pipefail

# Constants
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly DEFAULT_REGION="us-east-1"

# Variables
region="${AWS_REGION:-$DEFAULT_REGION}"
dry_run=false

# Functions
check_prerequisites() {
    local required_commands=("aws" "jq")

    for cmd in "${required_commands[@]}"; do
        if ! command -v "$cmd" &>/dev/null; then
            log_error "Required command not found: $cmd"
            return 1
        fi
    done
}

# Conditional logic
if [[ "$dry_run" == true ]]; then
    echo "Dry run mode enabled"
fi

# Loops
for instance_id in "${instance_ids[@]}"; do
    aws ec2 describe-instances --instance-ids "$instance_id"
done
```

### Documentation

- Use Markdown formatting
- Include code blocks with language specification
- Add frontmatter with sidebar_position
- Use descriptive headers
- Keep line length reasonable (80-100 characters)
- Add cross-references with relative links

## Testing

### Manual Testing Checklist

- [ ] Script executes without errors
- [ ] Help text displays correctly
- [ ] Error handling works properly
- [ ] Dry-run mode works as expected
- [ ] All command-line options work
- [ ] Script handles missing dependencies
- [ ] Script validates AWS credentials
- [ ] Script cleans up resources on exit

### Testing in Safe Environments

**Always test in a safe environment:**

- Use a dedicated test AWS account
- Test with limited permissions first
- Use `--dry-run` mode when available
- Back up data before destructive operations
- Start with small-scale tests

## Review Process

### What to Expect

1. **Initial Review**: Maintainers will review your PR within a few days
2. **Feedback**: You may receive feedback or change requests
3. **Iteration**: Make requested changes and push updates
4. **Approval**: Once approved, a maintainer will merge your PR
5. **Release**: Changes will be included in the next release

### Review Criteria

Reviewers will check:

- Code quality and style
- Functionality and correctness
- Security considerations
- Documentation completeness
- Test coverage
- Backward compatibility

## Community

### Communication Channels

- **GitHub Issues**: Bug reports and feature requests
- **Pull Requests**: Code contributions and discussions
- **Discussions**: General questions and ideas

### Getting Help

If you need help:

1. Check the [documentation](introduction.md)
2. Search existing issues
3. Ask in GitHub Discussions
4. Reach out to maintainers

## Recognition

Contributors will be:

- Listed in release notes
- Mentioned in project documentation
- Added to the contributors list

## License

By contributing, you agree that your contributions will be licensed under the MIT-0 License.

## Questions?

If you have questions about contributing:

- Review this guide
- Check existing issues and PRs
- Ask in GitHub Discussions
- Contact maintainers

Thank you for contributing to awsutils! Your contributions help make cloud automation easier for everyone.
