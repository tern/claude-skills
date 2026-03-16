# Claude Skills Sync

Invoked as `/claude-skills-sync` — 偵測 `~/claude-skills/` 是否有未推送的變更，有則自動 commit + push 到 GitHub。

## When to Use

- **手動：** 新增或修改 skill 後執行，立即同步到 GitHub
- **自動：** 每日 PM2 排程兜底推送（每天 08:47）
- **自動：** post-commit hook 每次 commit 後即時觸發

## What It Does

1. 進入 `~/claude-skills/`
2. 檢查是否有 uncommitted / untracked 的變更
3. 有變更：`git add -A` → `git commit` → `git push origin main`
4. 沒變更：印出提示並結束

## Instructions

When `/claude-skills-sync` is invoked:

1. 執行 `bash ~/claude-skills/sync.sh "chore: sync skills <date>"`
2. 印出執行結果（成功 / 無變更 / 錯誤）
