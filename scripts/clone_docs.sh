#!/bin/bash
set -euo pipefail

ORG=vrui-vr
REPOS=($(<repos.txt))

DEST_DIR="docs"

mkdir -p "$DEST_DIR"

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
