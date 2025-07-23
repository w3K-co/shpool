#!/bin/bash
# =============================================================================
# GIT UPSTREAM SYNC SCRIPT (for macOS and Linux)
# =============================================================================
#
# WHAT THIS SCRIPT DOES:
# 1. Fetches the latest changes from the original "upstream" repository.
# 2. Rebases your local changes on top of the upstream project's main branch.
#
# HOW TO USE:
# 1. !!! IMPORTANT !!! Change the UPSTREAM_REPO_URL value below to the
#    URL of the original repository you forked from.
# 2. Save this file as `sync-upstream.sh` in the root folder of your project.
# 3. Open a terminal in your project's folder.
# 4. Make the script executable by running: chmod +x sync-upstream.sh
# 5. Run the script with: ./sync-upstream.sh
#
# AFTER THE SCRIPT RUNS:
# - If it says "Successfully rebased":
#   Open GitHub Desktop, and you will see that your branch is ahead of your
#   origin/main. You need to push these changes. Because the history was
#   rewritten, you must do a "force push". In GitHub Desktop, go to
#   Repository > Push, but if that fails, you may need to use the command
#   line: `git push --force-with-lease origin main`
#
# - If it says "CONFLICT":
#   Open GitHub Desktop. It will show you the merge conflicts. Resolve them
#   in your code editor, commit the changes, and then continue the rebase
#   from the terminal by typing: `git rebase --continue`

# --- CONFIGURATION ---
# !!! EDIT THIS LINE !!!
UPSTREAM_REPO_URL="https://github.com/shell-pool/shpool.git"

# The name of your primary branch (usually "main" or "master")
YOUR_BRANCH_NAME="master"
# --- END CONFIGURATION ---


# --- SCRIPT LOGIC (No need to edit below this line) ---
echo "▶️ Starting upstream sync..."

# Check if the upstream remote is configured
if ! git remote -v | grep -q "upstream"; then
  echo "⚪ Upstream remote not found. Adding it now..."
  git remote add upstream $UPSTREAM_REPO_URL
  if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to add upstream remote. Please check the URL."
    exit 1
  fi
  echo "✅ Upstream remote added successfully."
else
  echo "✅ Upstream remote is already configured."
fi

echo "🔄 Fetching latest changes from upstream repository..."
git fetch upstream
if [ $? -ne 0 ]; then
    echo "❌ Error: Failed to fetch from upstream. Check your connection and the remote URL."
    exit 1
fi

echo "🔀 Switching to your local '$YOUR_BRANCH_NAME' branch..."
git switch $YOUR_BRANCH_NAME
if [ $? -ne 0 ]; then
    echo "❌ Error: Could not switch to branch '$YOUR_BRANCH_NAME'. Does it exist?"
    exit 1
fi

echo "🏗️ Rebasing your changes on top of 'upstream/$YOUR_BRANCH_NAME'..."
git rebase upstream/$YOUR_BRANCH_NAME

if [ $? -eq 0 ]; then
  echo "✅✅✅ SUCCESS! Your branch is now up-to-date with upstream."
  echo "➡️ NEXT STEP: Push the changes to your GitHub fork."
  echo "   You will need to FORCE PUSH. In the terminal, run:"
  echo "   git push --force-with-lease origin $YOUR_BRANCH_NAME"
else
  echo "⚠️⚠️⚠️ CONFLICT! The rebase could not complete automatically."
  echo "➡️ NEXT STEP: Open GitHub Desktop or your code editor to resolve the conflicts."
  echo "   After resolving and saving the files, stage them (`git add .`)"
  echo "   Then, run 'git rebase --continue' in your terminal to finish."
fi
