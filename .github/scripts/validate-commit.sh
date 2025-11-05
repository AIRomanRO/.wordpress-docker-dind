#!/bin/bash

# Conventional Commit Message Validator
# This script validates commit messages against the Conventional Commits format
# Usage: ./validate-commit.sh [commit-message]
# Or use as a git hook: ln -s ../../.github/scripts/validate-commit.sh .git/hooks/commit-msg

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Valid commit types
VALID_TYPES=(
    "feat"
    "fix"
    "docs"
    "style"
    "refactor"
    "perf"
    "test"
    "build"
    "ci"
    "chore"
)

# Function to print colored output
print_error() {
    echo -e "${RED}❌ ERROR: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ SUCCESS: $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  WARNING: $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  INFO: $1${NC}"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 [commit-message-file]"
    echo ""
    echo "Validates commit messages against Conventional Commits format."
    echo ""
    echo "Format: <type>[optional scope]: <description>"
    echo ""
    echo "Valid types: ${VALID_TYPES[*]}"
    echo ""
    echo "Examples:"
    echo "  feat(carousel): add image preview"
    echo "  fix(oauth): resolve token issue"
    echo "  docs: update README"
    echo "  feat!: breaking change"
    echo ""
    echo "For more information, see .github/CONVENTIONAL_COMMITS.md"
}

# Function to validate commit type
validate_type() {
    local type=$1
    for valid_type in "${VALID_TYPES[@]}"; do
        if [[ "$type" == "$valid_type" ]]; then
            return 0
        fi
    done
    return 1
}

# Function to validate commit message
validate_commit_message() {
    local message=$1
    local errors=0
    local warnings=0

    # Skip merge commits
    if [[ "$message" =~ ^Merge ]]; then
        print_info "Merge commit detected, skipping validation"
        return 0
    fi

    # Skip revert commits
    if [[ "$message" =~ ^Revert ]]; then
        print_info "Revert commit detected, skipping validation"
        return 0
    fi

    # Extract the first line (subject)
    local subject=$(echo "$message" | head -n 1)

    # Check if message is empty
    if [[ -z "$subject" ]]; then
        print_error "Commit message is empty"
        return 1
    fi

    # Regex pattern for conventional commit
    # Format: type(scope): description
    # or: type: description
    # with optional ! for breaking changes
    local pattern='^(feat|fix|docs|style|refactor|perf|test|build|ci|chore)(\([a-z0-9-]+\))?!?: .+'

    if [[ ! "$subject" =~ $pattern ]]; then
        print_error "Commit message does not follow Conventional Commits format"
        echo ""
        echo "Expected format: <type>[optional scope]: <description>"
        echo ""
        echo "Your message: $subject"
        echo ""
        echo "Valid types: ${VALID_TYPES[*]}"
        echo ""
        echo "Examples:"
        echo "  feat(carousel): add image preview"
        echo "  fix(oauth): resolve token issue"
        echo "  docs: update README"
        echo ""
        ((errors++))
    else
        # Extract components
        if [[ "$subject" =~ ^([a-z]+)(\([a-z0-9-]+\))?(!)?: (.+)$ ]]; then
            local type="${BASH_REMATCH[1]}"
            local scope="${BASH_REMATCH[2]}"
            local breaking="${BASH_REMATCH[3]}"
            local description="${BASH_REMATCH[4]}"

            # Validate type
            if ! validate_type "$type"; then
                print_error "Invalid commit type: $type"
                echo "Valid types: ${VALID_TYPES[*]}"
                ((errors++))
            else
                print_success "Valid commit type: $type"
            fi

            # Check scope format (if present)
            if [[ -n "$scope" ]]; then
                if [[ "$scope" =~ ^\([a-z0-9-]+\)$ ]]; then
                    print_success "Valid scope: $scope"
                else
                    print_error "Invalid scope format: $scope"
                    echo "Scope should be lowercase alphanumeric with hyphens, e.g., (carousel), (oauth-config)"
                    ((errors++))
                fi
            fi

            # Check breaking change indicator
            if [[ -n "$breaking" ]]; then
                print_warning "Breaking change detected (!)"
                echo "Make sure to document the breaking change in the commit body or footer"
                ((warnings++))
            fi

            # Check description
            if [[ -z "$description" ]]; then
                print_error "Description is empty"
                ((errors++))
            else
                # Check description length
                local desc_length=${#description}
                if [[ $desc_length -lt 10 ]]; then
                    print_warning "Description is very short ($desc_length chars). Consider being more descriptive."
                    ((warnings++))
                elif [[ $desc_length -gt 72 ]]; then
                    print_warning "Description is long ($desc_length chars). Consider keeping it under 72 characters."
                    ((warnings++))
                else
                    print_success "Valid description length: $desc_length chars"
                fi

                # Check if description starts with capital letter
                if [[ "$description" =~ ^[A-Z] ]]; then
                    print_warning "Description starts with capital letter. Consider using lowercase."
                    ((warnings++))
                fi

                # Check if description ends with period
                if [[ "$description" =~ \.$ ]]; then
                    print_warning "Description ends with period. Consider removing it."
                    ((warnings++))
                fi

                # Check for imperative mood (common mistakes)
                if [[ "$description" =~ ^(added|fixed|updated|changed|removed) ]]; then
                    print_warning "Use imperative mood: 'add' not 'added', 'fix' not 'fixed'"
                    ((warnings++))
                fi
            fi
        fi
    fi

    # Check for BREAKING CHANGE in body
    if [[ "$message" =~ BREAKING[[:space:]]CHANGE ]]; then
        print_warning "BREAKING CHANGE found in commit body"
        ((warnings++))
    fi

    # Summary
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    if [[ $errors -eq 0 ]]; then
        print_success "Commit message is valid!"
        if [[ $warnings -gt 0 ]]; then
            print_warning "Found $warnings warning(s). Consider addressing them."
        fi
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        return 0
    else
        print_error "Found $errors error(s) and $warnings warning(s)"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        echo ""
        echo "For more information, see:"
        echo "  .github/CONVENTIONAL_COMMITS.md - Detailed guide"
        echo "  .github/COMMIT_TYPES.md - Quick reference"
        return 1
    fi
}

# Main script
main() {
    # Check if help is requested
    if [[ "$1" == "-h" ]] || [[ "$1" == "--help" ]]; then
        show_usage
        exit 0
    fi

    # Get commit message
    local commit_message=""
    
    if [[ -n "$1" ]]; then
        # If argument is a file, read from it (git hook mode)
        if [[ -f "$1" ]]; then
            commit_message=$(cat "$1")
        else
            # Otherwise, treat as direct message
            commit_message="$1"
        fi
    else
        # Read from stdin or last commit
        if [[ -t 0 ]]; then
            # Terminal input, get last commit message
            commit_message=$(git log -1 --pretty=%B 2>/dev/null || echo "")
            if [[ -z "$commit_message" ]]; then
                print_error "No commit message provided and no git history found"
                show_usage
                exit 1
            fi
            print_info "Validating last commit message"
        else
            # Pipe input
            commit_message=$(cat)
        fi
    fi

    # Validate the commit message
    validate_commit_message "$commit_message"
}

# Run main function
main "$@"

