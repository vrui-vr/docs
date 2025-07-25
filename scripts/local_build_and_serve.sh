#!/bin/bash
set -euo pipefail

# Resolve absolute path of this script regardless of where it's run from
SCRIPT_PATH="$(realpath "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"

# Root of the docs repo (parent of script dir)
DOCS_REPO_ROOT="$(realpath "$SCRIPT_DIR/..")"
EXTERNAL_DIR="$DOCS_REPO_ROOT/docs"

# Read repo names from file
REPO_NAMES=($(<"$DOCS_REPO_ROOT/repos.txt"))

# Build full paths (e.g., ../arsandbox)
REPOS=()
for NAME in "${REPO_NAMES[@]}"; do
  REPOS+=("$(realpath "$DOCS_REPO_ROOT/../$NAME")")
done

# Link each repo's docs directory into our unified docs folder
for REPO_PATH in "${REPOS[@]}"; do
  REPO_PATH="$(realpath "$REPO_PATH")"
  REPO_NAME="$(basename "$REPO_PATH")"
  DEST_LINK="$EXTERNAL_DIR/$REPO_NAME"
  DOCS_SRC="$REPO_PATH/docs"

  echo "Preparing symlink for $REPO_NAME..."

  rm -rf "$DEST_LINK"  # Remove any old content or link
  if [ -d "$DOCS_SRC" ]; then
    ln -s "$DOCS_SRC" "$DEST_LINK"
    echo "✅ Linked $DOCS_SRC → $DEST_LINK"
  else
    echo "⚠️ Skipping $REPO_NAME: no docs directory found"
  fi
done

echo "Generating mkdocs.yml..."
python "$DOCS_REPO_ROOT/scripts/generate_mkdocs.py"

echo "Starting local MkDocs server..."
mkdocs serve \
  --config-file "$DOCS_REPO_ROOT/mkdocs.generated.yml" \
  --watch "$DOCS_REPO_ROOT/overrides" \
  $(for PATH in "${REPOS[@]}"; do echo "--watch $PATH/docs"; done)

# Clean up symlinks after server stops
echo "Cleaning up symlinks..."
for REPO_NAME in "${REPO_NAMES[@]}"; do
  rm -rf "$EXTERNAL_DIR/$REPO_NAME"
done

echo "✅ Done."
