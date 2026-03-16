# Memory Optimizer

Invoked as `/memory-optimize` — 分析並壓縮 Claude Code 的記憶檔案，減少每次對話的 token 消耗，同時保留所有可繼續作業所需的上下文。

## When to Use

- **手動：** 完成一個大任務後執行，把已完成的細節壓縮
- **自動：** 每日 PM2/cron 排程自動執行（由 `claude-skills-sync` 安裝設定）

## What It Does

讀取 `~/.claude/projects/<project>/memory/` 下的所有 `.md` 檔案，套用以下壓縮規則：

| 類型 | 處理方式 |
|------|----------|
| `project_*.md` | 套用壓縮規則 |
| `reference_*.md` | **不動**（查詢用，需保持完整） |
| `MEMORY.md` | 最後更新索引描述 |

### 壓縮規則

1. **已完成的任務** → 壓縮成 1-2 行摘要，不保留過程細節
2. **程式碼片段** → 移除，改為「內容見 `path/to/file`」
3. **保留不動：** 待辦、下一步、環境設定（port/DB/路徑）、已知陷阱、關鍵 PR/commit/URL
4. **MEMORY.md 索引** → 每行一個條目，保持精簡

### Output

- 直接覆寫各 `.md` 檔案
- 印出優化前後 byte 數對比

## Environment Variables

| 變數 | 說明 | 預設 |
|------|------|------|
| `CLAUDE_MEMORY_DIR` | 記憶目錄路徑 | 自動偵測（`~/.claude/projects/-<home>/memory`） |

## Instructions

When `/memory-optimize` is invoked:

1. 讀取 `CLAUDE_MEMORY_DIR`（若未設定，自動從 `$HOME` 推算）
2. 用 `Glob` 列出該目錄下所有 `.md` 檔案
3. 跳過 `reference_*.md`，MEMORY.md 最後處理
4. 對每個 `project_*.md`：
   - 保留 frontmatter（`---` 區塊）
   - 壓縮「已完成」段落為摘要
   - 移除 code block，改為路徑引用
   - 保留「待辦 / 下一步 / How to apply / 環境設定 / 已知陷阱」
5. 覆寫檔案，印出優化前後 byte 數對比
