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

for REPO_PATH in "${REPOS[@]}"; do
  REPO_PATH="$(realpath "$REPO_PATH")"  # Resolve symlinks/relative paths
  REPO_NAME="$(basename "$REPO_PATH")"
  DEST_DIR="$EXTERNAL_DIR/$REPO_NAME"

  echo "Cleaning and preparing $DEST_DIR..."
  rm -rf $DEST_DIR # remove old docs
  mkdir -p "$DEST_DIR" # recreate the dir

  DOCS_SRC="$REPO_PATH/docs"

  if [ -d "$DOCS_SRC" ]; then
    echo "Copying docs from $DOCS_SRC → $DEST_DIR"
    cp -r "$DOCS_SRC/"* "$DEST_DIR/" 2>/dev/null || echo "⚠️ Docs directory exists but is empty"
    cp "$DOCS_SRC/nav.yml" "$DEST_DIR/" 2>/dev/null || echo "⚠️ No nav.yml found in $DOCS_SRC"
  else
    echo "⚠️ Skipping $REPO_NAME: no docs directory found"
  fi
done

echo "Generating mkdocs.yml..."
python "$DOCS_REPO_ROOT/scripts/generate_mkdocs.py"

echo "Starting local MkDocs server..."
mkdocs serve --config-file "$DOCS_REPO_ROOT/mkdocs.generated.yml" --watch "$DOCS_REPO_ROOT/overrides"

# clean up
for REPO_PATH in "${REPOS[@]}"; do
  rm -rf $DEST_DIR # remove old docs
done
