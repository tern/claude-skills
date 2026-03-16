# claude-skills

Personal Claude Code skills collection.

## Skills

| Skill | 說明 |
|-------|------|
| [memory-optimizer](./memory-optimizer/) | 自動壓縮 `memory/*.md` 記憶檔，減少 token 用量 |
| [claude-skills-sync](./claude-skills-sync/) | 偵測變更並 push 到 GitHub，含新機器一鍵安裝腳本 |

## 快速安裝（新機器）

```bash
git clone https://github.com/tern/claude-skills.git ~/claude-skills
bash ~/claude-skills/claude-skills-sync/install.sh
```

自動完成：clone repo → 建立所有 skill 的 symlink → 設定 PM2 每日排程。

## 單獨安裝

```bash
npx skills add tern/claude-skills@memory-optimizer
npx skills add tern/claude-skills@claude-skills-sync
```
# auto-push via post-commit hook
