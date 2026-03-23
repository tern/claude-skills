# create-vm.sh 完整解析

`~/array30-install/create-vm.sh` — 全自動在 KVM 建立 Ubuntu 24.04 測試 VM，用於驗證 `array30-install.sh`。

## 架構總覽

```
create-vm.sh
├── 設定常數（VM 規格、路徑、快照名稱）
├── 工具函式（IP 刷新、SSH 等待、快照操作）
├── 前置檢查 + 快照感知選單
├── Phase A：建立 VM（Cloud Image + cloud-init）
├── Phase B：安裝 GNOME 桌面（ubuntu-desktop-minimal）
└── Phase C：SCP + 執行 array30-install.sh（fcitx5 或 ibus）
```

## 關鍵常數

```bash
VM_NAME="ubuntu-array30-install"
VM_USER="array30"        VM_PASS="@1234567"
VM_RAM=4096              VM_CPUS=2
VM_DISK_SIZE=25G
DISK_PATH="~/VMs/ubuntu-array30-install.qcow2"
CLOUD_IMG_CACHE="~/Downloads/ubuntu-24.04-server-cloudimg-amd64.img"
VIRSH="virsh --connect qemu:///system"   # 全域統一連線
SNAP_A="snap-phase-a"    # 基礎 Ubuntu
SNAP_B="snap-phase-b"    # Ubuntu + GNOME
SNAP_C="snap-phase-c"    # 行列30安裝完成
```

## AUTO_YES 模式

```bash
AUTO_YES=${AUTO_YES:-false}
[[ ! -t 0 ]] && AUTO_YES=true   # 非 TTY 自動觸發（pipe、CI、Claude Code）
```

AUTO_YES 時：
- 略過快照選單，直接從 Phase A 建立
- 所有 `ask_yn()` 自動回答 yes
- Phase C 引擎選擇從 `ARRAY30_TEST_ENGINE`（預設 `fcitx5`）讀取

**從快照還原並跑 Phase C（Claude Code 常用方式）：**
```bash
# 先還原快照，再用 pipe 觸發 AUTO_YES
virsh -c qemu:///system snapshot-revert ubuntu-array30-install snap-phase-b
export ARRAY30_TEST_ENGINE=ibus   # 或 fcitx5
printf "1\ny\ny\n" | bash create-vm.sh > /tmp/test.log 2>&1 &
```
注意：選單選項 `1` 對應快照選單第一個（因快照存在，選單動態建立）。

## 快照感知選單邏輯

腳本啟動時偵測現有快照，動態建立選單：

```
有 snap-phase-c → 選項: 還原 C → 繼續跑 Phase C
有 snap-phase-b → 選項: 還原 B → 繼續跑 Phase C
有 snap-phase-a → 選項: 還原 A → 繼續跑 Phase B+C
永遠有         → 選項: 從 Phase A 全新建立
有任何快照時   → 選項: 管理還原點（刪除）
```

無快照時：直接詢問是否全新建立，省去選單。

AUTO_YES 時完全略過選單（注意！即使有快照也會重建）。

## Phase A 詳解

| 步驟 | 說明 | 重點 |
|------|------|------|
| A1 | 清理殘留 VM 和磁碟 | 同時清 session + system 連線 |
| A2 | 啟動 libvirtd + default 網路 | 需 sudo 啟動 libvirtd |
| A3 | 下載/使用快取 Cloud Image | wget -c 支援斷點續傳 |
| A4 | 複製並 resize 磁碟 | qcow2，25G |
| A5 | 產生 cloud-init user-data | 見下方說明 |
| A6 | virt-install | UEFI (non-secboot)，SPICE+QXL |
| A7 | 等待 SSH 就緒（最多 5 分鐘） | 逾時後詢問是否繼續等 |

**cloud-init user-data 關鍵設定：**
```yaml
users:
  - name: array30
    sudo: ALL=(ALL) NOPASSWD:ALL
    ssh_authorized_keys: [~/.ssh/id_ed25519.pub]
runcmd:
  - netplan apply           # 確保 DHCP 網路
  - systemctl enable ssh
  - ufw disable
  - touch /var/lib/cloud/instance/boot-finished-marker  # Phase B 等待標記
```

**virt-install 關鍵參數：**
```
--boot loader=OVMF_CODE.4m.fd,...,loader.secure=no  # UEFI 非 secboot
--features smm.state=off                             # 關閉 SMM（避免 secboot 依賴）
--video qxl                                          # 非 virtio（桌面才不黑畫面）
--cloud-init user-data=...                           # 注入設定
```

## Phase B 詳解

| 步驟 | 說明 | 已知陷阱 |
|------|------|---------|
| B1 | 等待 cloud-init 完成 | 偵測 marker 檔或 `cloud-init status disabled/done` |
| B2 | 等待 apt lock 釋放 | cloud-init 可能仍在後台跑 apt |
| B3 | apt-get update | |
| B4 | 安裝 ubuntu-desktop-minimal | 約 10-15 分鐘，SSH 可能斷線（exit 255）→ 等 60s 重連 |
| B5 | 確保 SSH 永久啟用 + ufw disable | 桌面安裝後 SSH 可能被關 |
| B6 | reboot | |
| B7 | 等待重開機完成 | VM_IP="" 強制重查 IP |

## Phase C 詳解

| 步驟 | 說明 |
|------|------|
| C1 | SCP array30-install.sh 到 VM |
| C2 | SSH 執行 install（傳入 ARRAY30_ENGINE env var）|
| C3 | 若 exit 0：執行 diagnose（set +e，失敗不中斷）|
| C4 | reboot，等待重連 |
| 建快照 | 詢問是否建立 snap-phase-c |

**引擎選擇：**
```bash
# 互動模式：選單 1=fcitx5, 2=ibus
# AUTO_YES 模式：ARRAY30_TEST_ENGINE env var（預設 fcitx5）
# 傳給 array30-install.sh：ARRAY30_ENGINE=$TEST_ENGINE
```

## IP 查詢機制

```bash
refresh_vm_ip() {
    # 方法1: ARP neighbor table（ip neigh show）— 即時，優先
    # 方法2: virsh net-dhcp-leases — 取最新租約 fallback
}
```

每次 SSH 前自動呼叫，重開機後 `VM_IP=""` 強制重查。

## 工具函式速查

| 函式 | 用途 |
|------|------|
| `refresh_vm_ip` | 更新 `$VM_IP`（MAC → ARP / DHCP leases）|
| `try_ssh <cmd>` | 自動刷新 IP 後執行遠端指令 |
| `wait_for_ssh <秒>` | 等待 SSH 就緒，VM 關機時自動重啟 |
| `vm_shutdown_wait` | 優雅關機，逾時強制 destroy |
| `create_snapshot <name> <desc>` | 關機 → 刪舊同名 → 建立 → 重啟 |
| `restore_snapshot <name>` | 還原 → 啟動 → 等 SSH（B/C 快照自動啟 GDM）|
| `ask_yn <prompt>` | AUTO_YES 時自動 yes，否則互動 |
| `snapshot_exists <name>` | 回傳 0/1 |

## CHANGELOG（腳本內記錄的 16 個踩坑）

| # | 問題 | 修法 |
|---|------|------|
| 1 | virt-install 無 sudo → session 找不到網路 | `--connect qemu:///system` |
| 2 | `--boot uefi` 自動選 secboot → 擋 Cloud Image | 指定非 secboot OVMF |
| 3 | 改 XML 關 secboot → firmware mismatch | 一開始就指定完整 firmware 路徑 |
| 4 | `--video virtio` → 桌面黑畫面 | 改 `--video qxl` |
| 5 | Cloud Image + BIOS → 開不了 | Cloud Image 是 GPT+EFI，必須 UEFI |
| 6 | cloud-init reboot → on_reboot=destroy → 關機 | 移除 power_state，偵測關機後自動 start |
| 7 | `set -euo pipefail` + pipeline → 腳本中斷 | 等待函式加 `|| true`，Phase C 用 `set +e` |
| 8 | 重開機後網路斷（cloud-init netplan 無 DHCP） | cloud-init write_files 寫永久 netplan |
| 9 | apt -qq + log → 無進度 + SSH 斷 | 即時顯示進度行 + ServerAliveInterval=30 |
| 10 | 重開機後 IP 改變 | `refresh_vm_ip()` 每次 SSH 前重查 |
| 11 | SSH 需密碼 | cloud-init 注入 SSH 公鑰 |
| 12 | Phase B apt lock 衝突 | B1 等 cloud-init，B2 等 apt lock |
| 13 | reboot 後 VM_IP 仍舊值 | reboot 後 `VM_IP=""` 強制重查 |
| 14 | 桌面安裝後 SSH 被關 | B5 `systemctl enable ssh + ufw disable` |
| 15 | B4 apt SSH 斷（exit 255） | 斷線後清 IP + 重新 wait_for_ssh |
| 16 | IP 查詢分散 | 統一 `refresh_vm_ip()` + `try_ssh()` |
