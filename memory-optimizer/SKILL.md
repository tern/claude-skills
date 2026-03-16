# Memory Optimizer Skill

Invoked as `/memory-optimize` — analyzes and compresses all memory files to reduce token usage while preserving actionable context.

## When to Use

- Manually: run `/memory-optimize` after finishing a major task
- Automatically: scheduled daily via cron

## What It Does

Reads every `.md` file under `~/.claude/projects/-home-deck/memory/` and applies the following compression rules:

### Rules

1. **已完成的任務** → 壓縮成 1-2 行摘要，不保留過程細節
2. **程式碼片段** → 移除，改為「內容見 `path/to/file`」
3. **只保留「下次繼續需要知道的事」**：
   - 待辦 / 下一步
   - 環境設定（port、DB、路徑）
   - 已知陷阱
   - 關鍵 PR / commit / URL
4. **MEMORY.md 索引** → 保持精簡，每行一個條目
5. **不動 Reference 檔案**（`reference_*.md`）：這些是查詢用的，本來就該完整

### Output

- 直接覆寫各 `.md` 檔案
- 結束後印出「優化前 / 優化後」的 byte 數對比
- 更新 MEMORY.md 的索引描述（若有變動）

## Instructions

When `/memory-optimize` is invoked:

1. 用 `Glob` 列出 `~/.claude/projects/-home-deck/memory/*.md`
2. 讀取每個檔案（MEMORY.md 最後處理）
3. 判斷每個檔案的類型：
   - `project_*.md`：套用壓縮規則
   - `reference_*.md`：跳過，不修改
   - `MEMORY.md`：最後根據修改結果更新索引描述
4. 對每個 `project_*.md`：
   - 保留 frontmatter（`---` 區塊）
   - 壓縮「已完成」段落為摘要
   - 移除 code block，改為路徑引用
   - 保留「待辦 / 下一步 / How to apply」
   - 保留環境設定、已知陷阱
5. 覆寫檔案，印出優化結果
