# Array30 Install

Invoked as `/array30-install` — 在 SteamOS (Steam Deck) 或 Ubuntu Desktop 上安裝原生 fcitx5-array 行列30引擎。

## Supported Platforms

| 平台 | 狀態 | 容器工具 |
|------|------|----------|
| SteamOS (Steam Deck) | ✅ | Podman（內建） |
| Ubuntu 24.04 Desktop | ✅ | Podman 或 Docker |
| Ubuntu 22.04 Desktop | ✅ | Podman 或 Docker |
| 其他 Debian-based | ⚠️ 實驗性 | Podman 或 Docker |

## Commands

```bash
./array30-setup.sh install        # 安裝（自動偵測平台）
./array30-setup.sh update-table   # 更新行列30字根表
./array30-setup.sh diagnose       # 診斷安裝狀態
./array30-setup.sh uninstall      # 移除
./array30-setup.sh backup         # 手動備份
./array30-setup.sh restore        # 從備份還原
```

## Why Container Compile

Ubuntu apt 只有 `fcitx5-table-array30`（table-based），不支援：
- W+數字鍵符號輸入
- 一級/二級簡碼
- 萬用字元查詢
- 詞組輸入、聯想詞

原生 `fcitx5-array` 引擎需從 AUR 編譯。因 Ubuntu/SteamOS 的 fcitx5 版本與上游 Arch 不同，腳本會在容器內降級依賴以匹配 host ABI。

## Instructions

When `/array30-install` is invoked:

1. 執行 `bash ~/steamdeck-array30/array30-setup.sh install 2>&1`，捕捉完整輸出
2. 若出現錯誤，分析錯誤類型：
   - 找不到容器工具 → 提示安裝 Podman 或 Docker
   - ABI 不相容 → 建議重新執行 install
   - 權限問題（Ubuntu） → 提示加 sudo
   - fcitx5 未安裝 → 提示 `sudo apt install fcitx5`
3. 安裝成功後提示重啟 fcitx5 或登出重登
