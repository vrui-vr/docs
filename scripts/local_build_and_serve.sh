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

# Check to see if there is a .github* repo
GH_REPO=$(find "$DOCS_REPO_ROOT/../.github"* -maxdepth 0 -type d 2>/dev/null)
if [[ -a "$GH_REPO" ]]; then
  REPO_NAMES+=("$(basename "$GH_REPO")")
fi

# Build full paths (e.g., ../arsandbox)
REPOS=()
for NAME in "${REPO_NAMES[@]}"; do
  REPO_PATH="$(realpath "$DOCS_REPO_ROOT/../$NAME" 2>/dev/null || true)"
  if [ -z "$REPO_PATH" ] || [ ! -d "$REPO_PATH" ]; then
    echo "⚠️ Skipping $NAME: local repo not found"
    continue
  fi

  REPOS+=("$REPO_PATH")
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
  elif [[ "$REPO_NAME" == .github* ]]; then
    for FILENAME in "CODE_OF_CONDUCT.md" "CONTRIBUTING.md";
        do
        SRC_FILE="$REPO_PATH/$FILENAME"
        DEST_FILE="$DOCS_REPO_ROOT/docs/$FILENAME"
        if [ -f "$SRC_FILE" ]; then
            ln -s "$SRC_FILE" "$DEST_FILE"
            echo "✅ Linked $SRC_FILE → $DEST_FILE"
        else
            echo "⚠️ Skipping $FILENAME: file not found in .github repo"
        fi
        done
        # also need to symlink the stuff in .github/assets to docs/assets
        ASSETS_SRC="$REPO_PATH/assets"
        ASSETS_DEST="$DOCS_REPO_ROOT/docs/assets"
        if [ -d "$ASSETS_SRC" ]; then
            for ITEM in "$ASSETS_SRC"/*; do
                ITEM_NAME="$(basename "$ITEM")"
                DEST_ITEM_LINK="$ASSETS_DEST/$ITEM_NAME"
                ln -s "$ITEM" "$DEST_ITEM_LINK"
                echo "✅ Linked $ITEM → $DEST_ITEM_LINK"
            done
        fi
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
    --watch "$DOCS_REPO_ROOT/docs" \
    $(for PATH in "${REPOS[@]}"; do [ -d "$PATH/docs" ] && echo "--watch $PATH/docs"; done) \
    $(if [[ -a "$GH_REPO" ]]; then echo "--watch $GH_REPO"; fi)

# Clean up symlinks after server stops
echo "Cleaning up symlinks..."
find $DOCS_REPO_ROOT -type l -delete

echo "✅ Done."
