# Array30 Diagnose

Invoked as `/array30-diagnose` — 執行 Steam Deck 行列30輸入法診斷，自動解讀輸出並給出具體修復建議。

## When to Use

- 行列30輸入法安裝後無法使用
- 更新後出現問題
- 懷疑 ABI 不相容（fcitx5 或 fmt 版本問題）
- 任何行列30相關的異常行為

## What It Does

1. 執行 `~/steamdeck-array30/array30-setup.sh diagnose`
2. 解讀輸出，判斷問題類型：
   - fcitx5-array .so 找不到或無法載入
   - ABI 不相容（StandardPath vs StandardPaths、fmt v11 vs v12）
   - 字根表 array.db 遺失或損毀
   - fcitx5 服務未執行
   - 其他環境問題
3. 給出具體修復指令（不只說「重新安裝」，而是精確的修復步驟）

## Background

Steam Deck 上 fcitx5 5.1.11 與上游 Arch 版本有 ABI 差異：
- `StandardPath::global()` → `StandardPaths::global()`（fcitx5 API 變更）
- `fmt::v11::vformat` → `fmt::v12::vformat`（fmt 版本差異）

安裝腳本會從 Arch Linux Archive 下載對應版本降級容器內套件再編譯，但若版本漂移可能需要重新執行。

## Instructions

When `/array30-diagnose` is invoked:

1. 執行 `bash ~/steamdeck-array30/array30-setup.sh diagnose 2>&1`，捕捉完整輸出
2. 分析輸出，識別問題類型（ABI / 檔案遺失 / 服務問題 / 其他）
3. 說明診斷結果（用中文，簡明扼要）
4. 給出具體修復指令，例如：
   - ABI 問題 → `./array30-setup.sh install`（重新編譯）
   - 字根表問題 → `./array30-setup.sh update-table`
   - 服務問題 → `systemctl --user restart fcitx5`
5. 若無法判斷，印出原始診斷輸出請用戶提供更多資訊
