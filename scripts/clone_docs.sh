#!/bin/bash
set -euo pipefail

ORG=vrui-vr
REPOS=($(<repos.txt))

DEST_DIR="docs"

mkdir -p "$DEST_DIR"

# grab docs/ from each repo
for REPO in "${REPOS[@]}"; do
  echo "Fetching only docs/ from $REPO..."

  TMP_DIR=$(mktemp -d)

  git clone --depth=1 --filter=blob:none --sparse "https://github.com/$ORG/$REPO.git" "$TMP_DIR/$REPO"
  cd "$TMP_DIR/$REPO"

  git sparse-checkout set docs

  if [ -d docs ]; then
    mkdir -p "$GITHUB_WORKSPACE/$DEST_DIR/$REPO"
    cp -vr docs/* "$GITHUB_WORKSPACE/$DEST_DIR/$REPO/"
  else
    echo "⚠️ No docs/ found in $REPO"
  fi

  cd "$GITHUB_WORKSPACE"
  rm -rf "$TMP_DIR"
done

# grab all .md files and assets/ from the .github repo
REPO=".github"

echo "Fetching .md files and assets/ from $REPO..."
TMP_DIR=$(mktemp -d)

git clone "https://github.com/$ORG/$REPO.git" "$TMP_DIR/$REPO"
cd "$TMP_DIR/$REPO"

# copy any *.md files
for FILE in *.md; do
  if [ -f "$FILE" ]; then
    cp -v "$FILE" "$GITHUB_WORKSPACE/$DEST_DIR/"
  fi
done

# copy assets/ directory
if [ -d assets ]; then
    mkdir -p "$GITHUB_WORKSPACE/$DEST_DIR/assets"
    cp -vr assets/* "$GITHUB_WORKSPACE/$DEST_DIR/assets/"
fi

cd "$GITHUB_WORKSPACE"
rm -rf "$TMP_DIR"

echo "✅ Done."
