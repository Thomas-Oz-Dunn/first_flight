#!/usr/bin/env bash

# if the index is clean, bail early since there's nothing to be committed
staged_files=$(git diff --staged --name-only)
[[ -z "$staged_files" ]] && exit 0

# create a temporary commit of the index
# (why do this? ideally, we just format the files to-be-committed, and leave
# everything else untouched. There's no good way to only stash unstaged
# changes, (keep-index stashes all changes, but preserves the index) 
# so we use temporary commits/stashes to accomplish this)
git commit --quiet --no-verify --message "TODO REVERT temporary commit of staged changes"

# this returns a script-friendly representation of the status that
# we can use to determine whether there were unstaged/untracked files 
stashable_files=$(git status --porcelain)

# if there WERE unstaged/untracked files:
if [[ -n $stashable_files ]]; then
  # stash any unstaged/untracked files
  git stash push --quiet --include-untracked --message \
    "TODO UNSTASH temporary stash of untracked/unstaged files"
fi

# undo the most recent commit, which should be the temp commit of the index
git reset --soft HEAD^

# change into the project root
cd $(git rev-parse --show-toplevel)

# call the dart formatter on the staged files
dart format --line-length=80 $staged_files

# re-stage any files that were just modified by the formatter
git add --update

# if we stashed any files, restore them
if [[ -n $stashable_files ]]; then
  git stash pop --quiet 
fi

exit 0