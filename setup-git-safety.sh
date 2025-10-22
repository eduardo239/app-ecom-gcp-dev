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

echo "✅ Git safety measures configured!"
echo "💡 New aliases available:"
echo "  git pushn  - Dry run push (test without pushing)"
echo "  git pushd  - Push to develop branch"
echo "  git pushm  - Push to main branch"  
echo "  git pushf  - Safe force push (--force-with-lease)"
echo "  git st     - Compact status"
echo "  git rc     - Show remotes"
echo "  git bc     - Show branch tracking"

echo ""
echo "🔒 Pre-push hook installed - you'll get warnings for:"
echo "  - Pushes to main/master branches"
echo "  - Production deployments"
echo "  - Force pushes"