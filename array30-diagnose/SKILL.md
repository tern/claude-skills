# Array30 Diagnose

Invoked as `/array30-diagnose` — 執行 Steam Deck 行列30輸入法診斷，自動解讀輸出並給出具體修復建議。

## When to Use

- 行列30輸入法安裝後無法使用
- 更新後出現問題
- 懷疑 ABI 不相容（fcitx5 或 fmt 版本問題）
- 任何行列30相關的異常行為

## Instructions

When `/array30-diagnose` is invoked:

1. 執行診斷：
   ```bash
   bash ~/steamdeck-array30/array30-setup.sh diagnose 2>&1
   ```

2. 分析輸出，識別問題類型並給出精確修復指令：

   **ABI 問題**（`undefined symbol`、`cannot open shared object`）
   → 重新安裝：`cd ~/steamdeck-array30 && echo "y" | bash array30-setup.sh install`

   **Flatpak 模式 — array.so 找不到**（`Could not locate library array.so`）
   - 確認 wrapper 存在：`ls ~/.var/app/org.fcitx.Fcitx5/data/fcitx5/bin/fcitx5-array-wrapper.sh`
   - 若不存在：重新執行 install（flatpak_install_files 會重建 wrapper）
   - 若存在但仍失敗：確認啟動指令用了 `flatpak run --command=<wrapper>`，而非直接 `flatpak run org.fcitx.Fcitx5`
   - **不要**用 `flatpak override --env=FCITX_ADDON_DIRS=...`（無效，會被 /app/bin/fcitx5 覆蓋）

   **字根表問題**（array.db 遺失或太小）
   → `bash ~/steamdeck-array30/array30-setup.sh update-table`

   **fcitx5 服務問題**（未執行）
   - Flatpak：`flatpak run --command=~/.var/app/org.fcitx.Fcitx5/data/fcitx5/bin/fcitx5-array-wrapper.sh org.fcitx.Fcitx5 -rd &`
   - 原生：`fcitx5 -rd &`

   **Profile 問題**（array 不在 profile）
   → 重新執行 install 會重設 profile

3. 說明診斷結果（用中文，簡明扼要），無法判斷時印出原始輸出

## Background: Flatpak 限制

SteamOS 上 fcitx5 通常以 Flatpak 安裝（`org.fcitx.Fcitx5`）：
- 所有 user addon 必須放在 `~/.var/app/org.fcitx.Fcitx5/data/fcitx5/lib/`
- addonloader 命名：`Library=array` → 找 `array.so`（不加 lib 前綴）
- `/app/bin/fcitx5` 是 shell wrapper，每次啟動重建 `FCITX_ADDON_DIRS`（僅包含 /app 路徑），`flatpak override --env` 無效
- 解法：用 `fcitx5-array-wrapper.sh` 作為 `--command`，在 exec fcitx5-bin 前插入 user addon lib 路徑

## Background: 原生 SteamOS ABI 差異

原生安裝（舊版）有 ABI 差異：
- `StandardPath::global()` → `StandardPaths::global()`（fcitx5 API 變更）
- `fmt::v11::vformat` → `fmt::v12::vformat`（fmt 版本差異）

安裝腳本從 Arch Linux Archive 下載對應版本降級容器內套件再編譯，SteamOS 更新後可能需要重新執行。
