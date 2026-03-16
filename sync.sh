#!/usr/bin/env bash
# claude-skills/sync.sh
# 自動偵測變更，有更新就 commit + push 到 GitHub
# 用法：bash ~/claude-skills/sync.sh [commit message]

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$REPO_DIR" || exit 1

# 若有傳入 commit message 就用，否則自動產生
MSG="${1:-"chore: sync skills $(date '+%Y-%m-%d %H:%M')"}"

# 檢查是否有變更
if git diff --quiet && git diff --staged --quiet && [ -z "$(git ls-files --others --exclude-standard)" ]; then
  echo "[claude-skills] 沒有變更，跳過 push"
  exit 0
fi

echo "[claude-skills] 偵測到變更，準備推送..."
git add -A
git commit -m "$MSG"
git push origin main

echo "[claude-skills] 推送完成 ✅"
