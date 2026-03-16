# Claude Skills Sync

Invoked as `/claude-skills-sync` — 偵測 `~/claude-skills/` 是否有未推送的變更，有則 commit + push 到 GitHub。

## When to Use

- 手動：新增或修改 skill 後執行 `/claude-skills-sync`
- 自動：每天 PM2 排程推送

## What It Does

1. 進入 `~/claude-skills/`
2. 檢查是否有 uncommitted 或 untracked 的變更
3. 有變更：`git add -A` → `git commit` → `git push origin main`
4. 沒變更：印出提示並結束
5. 印出推送結果

## Instructions

When `/claude-skills-sync` is invoked:

1. 執行 `bash ~/claude-skills/sync.sh` （可選：帶入 commit message 參數）
2. 印出執行結果
