#!/usr/bin/env bash
set -euo pipefail

# Script to initialize a git repo (if absent), create sensible defaults,
# set the provided remote, commit the current tree and push to GitHub.
# Usage: ./publish_to_github.sh
# Make sure you have push access to the provided remote and have authenticated
# (SSH key or HTTPS credentials via credential manager).

REPO_HTTPS="https://github.com/abhinav-dvp/Learning_AI.git"
REPO_SSH="git@github.com:abhinav-dvp/Learning_AI.git"

echo "Publish script starting..."

if [ -d ".git" ]; then
  echo "Found existing .git directory — using existing repository state."
else
  echo "Initializing new git repository..."
  git init
fi

# Create a basic .gitignore if not present
if [ ! -f .gitignore ]; then
  cat > .gitignore <<'EOF'
venv/
__pycache__/
*.pyc
.DS_Store
.env
.env.*
.idea/
.vscode/
node_modules/
dist/
build/
*.egg-info/
data/*.db
EOF
  echo "Created .gitignore"
else
  echo ".gitignore already exists — leaving it alone."
fi

# Ensure data directories exist and are tracked (via .gitkeep)
mkdir -p data/papers data/vector_db
touch data/.gitkeep data/papers/.gitkeep data/vector_db/.gitkeep

# Prefer SSH when available
echo "Checking SSH access to GitHub..."
if ssh -T git@github.com >/dev/null 2>&1; then
  REMOTE_URL="$REPO_SSH"
  echo "SSH access detected — using SSH remote: $REMOTE_URL"
else
  REMOTE_URL="$REPO_HTTPS"
  echo "SSH not available — falling back to HTTPS remote: $REMOTE_URL"
fi

# Set or update origin remote
if git remote | grep -q "origin"; then
  echo "Remote 'origin' already configured — updating URL to $REMOTE_URL"
  git remote set-url origin "$REMOTE_URL"
else
  git remote add origin "$REMOTE_URL"
fi

echo "Staging files..."
git add .

echo "Committing..."
if git rev-parse --verify HEAD >/dev/null 2>&1; then
  git commit -m "Import local project snapshot" || echo "No changes to commit"
else
  git commit -m "Initial commit - import project" || echo "No changes to commit"
fi

echo "Ensuring branch is 'main'..."
git branch -M main || true

echo "Pushing to remote 'origin' (this may prompt for credentials)..."
set +e
git push -u origin main
RC=$?
set -e
if [ $RC -ne 0 ]; then
  echo "Push failed with exit code $RC. Trying to push current branch to origin as 'local-import' instead."
  git push -u origin HEAD:local-import || {
    echo "Push failed again. Please check your remote permissions or push manually."; exit 1
  }
fi

echo "Repository published to $REMOTE_URL"
