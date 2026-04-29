# Array30 Install

Invoked as `/array30-install` — 在 SteamOS (Steam Deck) 或 Ubuntu Desktop 上安裝原生 fcitx5-array 行列30引擎。

## Supported Platforms

| 平台 | fcitx5 安裝方式 | 容器工具 |
|------|----------------|----------|
| SteamOS (Steam Deck) — Flatpak fcitx5 | Flatpak `org.fcitx.Fcitx5` | Podman（內建） |
| SteamOS (Steam Deck) — native fcitx5 | 原生 pacman | Podman（內建） |
| Ubuntu 24.04 Desktop | apt | Podman 或 Docker |
| Ubuntu 22.04 Desktop | apt | Podman 或 Docker |
| 其他 Debian-based | apt | Podman 或 Docker |

## Commands

```bash
./array30-setup.sh install        # 安裝（自動偵測平台與 fcitx5 安裝方式）
./array30-setup.sh update-table   # 更新行列30字根表
./array30-setup.sh diagnose       # 診斷安裝狀態
./array30-setup.sh uninstall      # 移除
./array30-setup.sh backup         # 手動備份
./array30-setup.sh restore        # 從備份還原
```

## Why Container Compile

apt/pacman 只有 `fcitx5-table-array30`（table-based），不支援：
- W+數字鍵符號輸入
- 一級/二級簡碼
- 萬用字元查詢
- 詞組輸入、聯想詞

原生 `fcitx5-array` 引擎需從 AUR 編譯。因 Ubuntu/SteamOS 的 fcitx5 版本與上游 Arch 不同，腳本會在容器內降級依賴以匹配 host ABI。

## Critical: Flatpak Mode

SteamOS 上 fcitx5 通常以 Flatpak 安裝（`org.fcitx.Fcitx5`）。這個模式有特殊行為：

- **安裝路徑**：`~/.var/app/org.fcitx.Fcitx5/data/fcitx5/lib/array.so`（不需 sudo）
- **addonloader 命名**：`Library=array` → 找 `array.so`（不加 lib 前綴）
- **FCITX_ADDON_DIRS 問題**：`/app/bin/fcitx5` 是 shell wrapper，啟動時會無條件覆蓋 `FCITX_ADDON_DIRS`，`flatpak override --env=...` 無效
- **解決方案**：安裝時建立 `fcitx5-array-wrapper.sh`，所有啟動點改用 `flatpak run --command=<wrapper>`

## Instructions

When `/array30-install` is invoked:

1. 執行安裝（腳本有互動式確認，需 echo y）：
   ```bash
   cd ~/steamdeck-array30 && echo "y" | bash array30-setup.sh install 2>&1 | tee /tmp/array30-install.log
   ```

2. 若出現錯誤，分析錯誤類型：

   **通用錯誤**
   - 找不到容器工具 → 提示安裝 Podman 或 Docker
   - ABI 不相容（undefined symbol）→ 重新執行 install
   - 權限問題（Ubuntu）→ 提示加 sudo
   - fcitx5 未安裝 → 提示安裝 fcitx5

   **Flatpak 模式特定錯誤**
   - `Could not locate library array.so`：`_FP_WRAPPER` 沒被用來啟動 fcitx5（確認 restart/verify 用了 `--command=$_FP_WRAPPER`）
   - `array addon 載入失敗`：先執行 `./array30-setup.sh diagnose`，看 array.so 是否存在於正確路徑
   - do_backup 在 pacman -Q 時 crash：Flatpak 環境中 pacman 指令不存在，需走 flatpak 分支

3. 安裝成功後確認：
   - log 最後應出現 `array addon 載入成功` 和 `array.db 讀取正常`
   - 提示用 Ctrl+Space 切換輸入法

## Key File Paths (Flatpak Mode)

| 項目 | 路徑 |
|------|------|
| array.so | `~/.var/app/org.fcitx.Fcitx5/data/fcitx5/lib/array.so` |
| array.db | `~/.var/app/org.fcitx.Fcitx5/data/fcitx5/array/array.db` |
| addon wrapper | `~/.var/app/org.fcitx.Fcitx5/data/fcitx5/bin/fcitx5-array-wrapper.sh` |
| profile | `~/.var/app/org.fcitx.Fcitx5/config/fcitx5/profile` |
| autostart wrapper | `~/.local/bin/fcitx5-start-array.sh` |
