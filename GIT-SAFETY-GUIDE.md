# Git Safety Guide: Avoiding Accidental Pushes

## 🛡️ **Git Configuration Safeguards**

### 1. **Set Push Default to Current Branch Only**

```bash
# Only push the current branch to its upstream
git config --global push.default current

# Require explicit branch specification for new branches
git config --global push.autoSetupRemote false
```

### 2. **Enable Push Safety Checks**

```bash
# Warn before pushing to a different branch name
git config --global push.followTags false

# Require explicit confirmation for force pushes
git config --global push.force false
```

## 🚫 **Pre-Push Hooks**

Create a pre-push hook to validate your pushes:

```bash
# Create pre-push hook
cat > .git/hooks/pre-push << 'EOF'
#!/bin/bash

# Get the remote and branch being pushed to
remote="$1"
url="$2"

# Colors for output
RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo -e "${YELLOW}🔍 Push Safety Check${NC}"
echo "Remote: $remote"
echo "URL: $url"

# Get current branch
current_branch=$(git branch --show-current)
echo "Current branch: $current_branch"

# Check if pushing to main/master
if [[ $current_branch == "main" || $current_branch == "master" ]]; then
    echo -e "${RED}⚠️  WARNING: You're about to push to $current_branch!${NC}"
    echo -e "Are you sure? Type 'yes' to continue:"
    read -r confirmation
    if [[ $confirmation != "yes" ]]; then
        echo -e "${RED}❌ Push cancelled${NC}"
        exit 1
    fi
fi

# Check if pushing to production remote (origin)
if [[ $remote == "origin" && ($current_branch == "main" || $current_branch == "master") ]]; then
    echo -e "${RED}🚨 DANGER: Pushing to production branch on origin!${NC}"
    echo -e "This will trigger production deployment. Continue? Type 'DEPLOY' to confirm:"
    read -r confirmation
    if [[ $confirmation != "DEPLOY" ]]; then
        echo -e "${RED}❌ Production push cancelled${NC}"
        exit 1
    fi
fi

# Check for force push
while read local_ref local_sha remote_ref remote_sha; do
    if [[ $local_sha == "0000000000000000000000000000000000000000" ]]; then
        # Deleting a branch
        echo -e "${YELLOW}⚠️  Deleting branch: $remote_ref${NC}"
    elif [[ $remote_sha == "0000000000000000000000000000000000000000" ]]; then
        # New branch
        echo -e "${GREEN}✅ Creating new branch: $remote_ref${NC}"
    else
        # Check if this is a force push
        if ! git merge-base --is-ancestor $remote_sha $local_sha; then
            echo -e "${RED}🚨 FORCE PUSH DETECTED!${NC}"
            echo -e "This will overwrite history. Type 'FORCE' to confirm:"
            read -r confirmation
            if [[ $confirmation != "FORCE" ]]; then
                echo -e "${RED}❌ Force push cancelled${NC}"
                exit 1
            fi
        fi
    fi
done

echo -e "${GREEN}✅ Push safety check passed${NC}"
exit 0
EOF

# Make it executable
chmod +x .git/hooks/pre-push
```

## 🔧 **Git Aliases for Safer Operations**

Add these to your `~/.gitconfig` or run them as commands:

```bash
# Safe push aliases
git config --global alias.pushf 'push --force-with-lease'  # Safer force push
git config --global alias.pushn 'push --dry-run'          # Test push without actually pushing
git config --global alias.pushd 'push origin develop'     # Always push to develop
git config --global alias.pushm 'push origin main'        # Explicit main push

# Verification aliases
git config --global alias.status-all 'status --porcelain' # Check all changes
git config --global alias.remote-check 'remote -v'        # Check remotes
git config --global alias.branch-check 'branch -vv'       # Check branch tracking
```

## 🎯 **Recommended Workflow**

### Instead of `git push`, use:

```bash
# 1. Check what you're about to push
git status
git log --oneline origin/develop..HEAD  # See commits you'll push

# 2. Dry run to verify
git push --dry-run

# 3. Push to specific branch
git push origin develop                   # Explicit push to develop
git push origin feature/my-feature       # Explicit push to feature branch

# 4. For production (with confirmation)
git push origin main                     # Will trigger safety check
```

## 🚀 **Branch Protection Rules**

### Set up branch protection on GitHub:

1. Go to **Settings** → **Branches**
2. Add protection rule for `main` branch:
   - ✅ Require pull request reviews
   - ✅ Require status checks to pass
   - ✅ Require branches to be up to date
   - ✅ Restrict pushes to matching branches

## ⚡ **Quick Safety Commands**

```bash
# Check current remote and branch
git remote -v && git branch -vv

# See what would be pushed
git push --dry-run origin $(git branch --show-current)

# Push with confirmation
git push --verbose origin $(git branch --show-current)

# Safe force push (only if no one else pushed)
git push --force-with-lease origin $(git branch --show-current)
```

## 🔒 **Additional Safety Measures**

### 1. **Multiple Remotes Strategy**

```bash
# Add a separate remote for development
git remote add dev https://github.com/eduardo239/app-ecom-gcp-dev.git
git remote add prod https://github.com/eduardo239/app-ecom-gcp-dev.git

# Push to dev by default
git config branch.develop.remote dev
git config branch.main.remote prod

# Now you need to explicitly choose
git push dev develop    # Development pushes
git push prod main      # Production pushes (rare)
```

### 2. **Environment-Based Warnings**

```bash
# Add to your shell profile (.zshrc, .bashrc)
export GIT_PUSH_CONFIRM=true

# Create a wrapper function
git_safe_push() {
    local current_branch=$(git branch --show-current)
    local remote=${1:-origin}
    local branch=${2:-$current_branch}

    echo "🔍 About to push:"
    echo "  Remote: $remote"
    echo "  Branch: $branch"
    echo "  Current branch: $current_branch"

    if [[ $branch == "main" || $branch == "master" ]]; then
        echo "⚠️  WARNING: This is a production branch!"
        read -p "Continue? (yes/no): " -r
        if [[ ! $REPLY == "yes" ]]; then
            echo "❌ Push cancelled"
            return 1
        fi
    fi

    git push "$remote" "$branch"
}

# Use the function instead of git push
alias gps=git_safe_push
```

## 📋 **Daily Workflow Checklist**

Before any push:

- [ ] `git status` - Check what's staged
- [ ] `git branch -vv` - Verify current branch and tracking
- [ ] `git remote -v` - Confirm remote URLs
- [ ] `git push --dry-run` - Test the push
- [ ] Use explicit branch names: `git push origin feature-branch`

## 🚨 **Emergency Recovery**

If you accidentally pushed to the wrong place:

```bash
# If you pushed to wrong branch (and haven't shared it yet)
git push origin :wrong-branch-name      # Delete remote branch
git push origin correct-branch-name     # Push to correct branch

# If you force-pushed and broke something
git reflog                              # Find the commit before force push
git reset --hard HEAD@{n}              # Reset to that commit
git push --force-with-lease origin branch-name  # Restore

# If you pushed sensitive data
git filter-branch --force --index-filter \
    'git rm --cached --ignore-unmatch sensitive-file' \
    --prune-empty --tag-name-filter cat -- --all
git push --force --all
```

## ⚙️ **One-Time Setup Script**

Run this once to set up all safety measures:

```bash
#!/bin/bash
echo "🛡️  Setting up Git safety measures..."

# Configure push behavior
git config --global push.default current
git config --global push.autoSetupRemote false
git config --global push.followTags false

# Add safety aliases
git config --global alias.pushf 'push --force-with-lease'
git config --global alias.pushn 'push --dry-run'
git config --global alias.pushd 'push origin develop'
git config --global alias.pushm 'push origin main'
git config --global alias.st 'status --porcelain'
git config --global alias.rc 'remote -v'
git config --global alias.bc 'branch -vv'

# Create pre-push hook (already done above)

echo "✅ Git safety measures configured!"
echo "💡 Use 'git pushn' for dry runs and 'git pushd' for develop pushes"
```

##

# Instead of "git push", use:

```bash
git pushn    # Dry run - see what WOULD be pushed (safe testing)
git pushd    # Always push to develop branch
git pushm    # Explicit push to main (with safety prompts)
git pushf    # Safer force push (--force-with-lease)

# Quick status checks:
git st       # Compact status view
git rc       # Show all remotes
git bc       # Show branch tracking info
```
