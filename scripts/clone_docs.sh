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

# grab the code of conduct and the contributing files from .github repo
REPO=".github"

echo "Fetching CODE_OF_CONDUCT.md and CONTRIBUTING.md from $REPO..."

TMP_DIR=$(mktemp -d)

git clone --depth=1 --filter=blob:none --sparse "https://github.com/$ORG/$REPO.git" "$TMP_DIR/$REPO"
cd "$TMP_DIR/$REPO"

git checkout sparse-checkout set CODE_OF_CONDUCT.md CONTRIBUTING.md

if [ -f CODE_OF_CONDUCT.md ]; then
  cp -v CODE_OF_CONDUCT.md "$GITHUB_WORKSPACE/$DEST_DIR"
else
  echo "⚠️ No CODE_OF_CONDUCT.md found in $REPO"
fi

if [ -f CONTRIBUTING.md ]; then
  cp -v CONTRIBUTING.md "$GITHUB_WORKSPACE/$DEST_DIR"
else
  echo "⚠️ No CONTRIBUTING.md found in $REPO"
fi

cd "$GITHUB_WORKSPACE"
rm -rf "$TMP_DIR"