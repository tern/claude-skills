# claude-skills

Personal Claude Code skills collection — productivity tools for managing memory, syncing skills, and reducing token usage.

## Skills

| Skill | 指令 | 說明 | 自動化 |
|-------|------|------|--------|
| [memory-optimizer](./memory-optimizer/) | `/memory-optimize` | 壓縮記憶檔，減少 token 消耗 | 每日 08:23 |
| [claude-skills-sync](./claude-skills-sync/) | `/claude-skills-sync` | 偵測變更並 push 到 GitHub | 每次 commit + 每日 08:47 |
| [array30-diagnose](./array30-diagnose/) | `/array30-diagnose` | Steam Deck 行列30診斷 + 自動解讀修復建議 | 手動 |

---

## 快速安裝（新機器）

```bash
git clone https://github.com/tern/claude-skills.git ~/claude-skills
bash ~/claude-skills/claude-skills-sync/install.sh
```

一鍵完成：
- ✅ Clone repo 到 `~/claude-skills/`
- ✅ 建立所有 skill 的 symlink 到 `~/.claude/skills/`
- ✅ 設定 post-commit hook（每次 commit 後自動 push）
- ✅ 設定 PM2 每日排程（若已安裝 PM2）

---

## 系統需求

| 需求 | 說明 |
|------|------|
| [Claude Code](https://claude.ai/code) | CLI 版本，用於執行 skill 指令 |
| Git | repo 管理與自動 push |
| PM2（選用） | 持久排程，重開機後仍有效 |
| bash | 所有腳本皆為 bash |

## 相容性

| 平台 | 狀態 |
|------|------|
| Linux（Ubuntu / Debian） | ✅ 完整支援 |
| SteamOS（Steam Deck） | ✅ 完整支援 |
| macOS | ✅ 應可運作（未測試） |
| Windows | ❌ 不支援（bash 腳本） |

---

## 架構

```
~/claude-skills/               ← git repo（本檔案）
├── README.md
├── sync.sh                    ← 共用：偵測變更並 push
├── memory-optimizer/
│   ├── SKILL.md               ← /memory-optimize 指令定義
│   └── run.sh                 ← 獨立執行腳本（PM2 用）
└── claude-skills-sync/
    ├── SKILL.md               ← /claude-skills-sync 指令定義
    └── install.sh             ← 新機器一鍵安裝

~/.claude/skills/
├── memory-optimizer    → ~/claude-skills/memory-optimizer  (symlink)
└── claude-skills-sync  → ~/claude-skills/claude-skills-sync (symlink)
```

### 自動化排程

```
每天 08:23  PM2: memory-optimizer   → 壓縮記憶檔
每天 08:47  PM2: claude-skills-sync → 推送到 GitHub（兜底）
每次 commit post-commit hook        → 即時推送到 GitHub
```

---

## 新增 Skill 流程

```bash
# 1. 建立 skill 目錄
mkdir ~/claude-skills/my-skill

# 2. 建立 SKILL.md（定義指令）與實作檔
# 3. 建立 symlink
ln -s ~/claude-skills/my-skill ~/.claude/skills/my-skill

# 4. commit → 自動 push
cd ~/claude-skills
git add my-skill/
git commit -m "feat: add my-skill"
# ↑ post-commit hook 自動觸發 push
```

---

## 環境變數

| 變數 | 說明 | 預設 |
|------|------|------|
| `CLAUDE_MEMORY_DIR` | 覆寫 memory-optimizer 的記憶目錄路徑 | 自動偵測 |

---

Built with [Claude Code](https://claude.ai/code)
