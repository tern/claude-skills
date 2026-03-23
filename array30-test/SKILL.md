---
name: array30-test
description: Run VM-based integration tests for array30-install.sh on Ubuntu 24.04. Use when user wants to test array30 installation, run VM tests, test ibus-array or fcitx5-array engine, debug create-vm.sh, or validate array30-install changes.
---

# array30-test

VM 整合測試 — 在 `ubuntu-array30-install` KVM 虛擬機上測試 `array30-install.sh`。

## 環境

| 項目 | 值 |
|------|-----|
| 腳本路徑 | `~/array30-install/create-vm.sh` |
| VM 名稱 | `ubuntu-array30-install` |
| libvirt 連線 | `qemu:///system` |
| VM 使用者 | `array30` / `@1234567` |
| VM 磁碟 | `~/VMs/ubuntu-array30-install.qcow2` |
| 快照 A | `snap-phase-a` — 基礎 Ubuntu 24.04 |
| 快照 B | `snap-phase-b` — Ubuntu + GNOME 桌面 |
| 快照 C | `snap-phase-c` — 行列30安裝完成 |
| 測試 log | `/tmp/array30-test.log` |
| 安裝 log | `/tmp/array30-install-result.log` |
| 診斷 log | `/tmp/array30-diagnose-result.log` |

## Workflows

### 快速測試（從 snap-phase-b，省去桌面安裝時間）

```bash
# 還原快照
virsh -c qemu:///system destroy ubuntu-array30-install 2>/dev/null
virsh -c qemu:///system snapshot-revert ubuntu-array30-install snap-phase-b

# 執行測試（fcitx5 引擎）
cd ~/array30-install
export ARRAY30_TEST_ENGINE=fcitx5
printf "1\ny\ny\n" | bash create-vm.sh > /tmp/array30-test.log 2>&1 &

# 或 ibus 引擎
export ARRAY30_TEST_ENGINE=ibus
printf "1\ny\ny\n" | bash create-vm.sh > /tmp/array30-test.log 2>&1 &
```

### 完整測試（從 snap-phase-a，包含 Phase B 桌面安裝）

```bash
virsh -c qemu:///system destroy ubuntu-array30-install 2>/dev/null
virsh -c qemu:///system snapshot-revert ubuntu-array30-install snap-phase-a

cd ~/array30-install
export ARRAY30_TEST_ENGINE=fcitx5   # 或 ibus
printf "1\ny\ny\n" | bash create-vm.sh > /tmp/array30-test.log 2>&1 &
```

### 監看進度

```bash
# 追蹤 log（過濾 apt 下載雜訊）
tail -f /tmp/array30-test.log | grep -v "^  Get:"

# 看關鍵狀態行
grep -E "\[OK\]|\[ERROR\]|\[C[0-9]\]|\[B[0-9]\]|=== Phase|成功|失敗" /tmp/array30-test.log

# 確認最終結果
grep "安裝結果\|全部完成" /tmp/array30-test.log
```

### 查看快照狀態

```bash
virsh -c qemu:///system snapshot-list ubuntu-array30-install
virsh -c qemu:///system list --all
```

### SSH 進 VM 除錯

```bash
SSH_OPTS="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"
ssh $SSH_OPTS array30@$(virsh -c qemu:///system domifaddr ubuntu-array30-install | awk '/ipv4/{print $4}' | cut -d/ -f1)

# 或直接用已知 IP（通常是 192.168.122.x）
ssh $SSH_OPTS array30@192.168.122.115
```

## 引擎選擇

`ARRAY30_TEST_ENGINE` 控制 Phase C 測試哪個引擎（未設定時預設 `fcitx5`）：

| 值 | 行為 |
|----|------|
| `fcitx5`（預設）| 從 AUR 編譯安裝 fcitx5-array，約 5 分鐘 |
| `ibus` | apt 安裝 ibus + 下載 cin 建表，約 1 分鐘 |

## 測試結果判讀

```
安裝結果: 成功   ← Phase C exit 0，診斷也通過
安裝結果: 失敗   ← Phase C exit 非零，看 /tmp/array30-install-result.log
```

Phase C 成功後 create-vm.sh 會：
1. 執行 `diagnose`（ibus 路線 diagnose 會顯示 fcitx5 not found，屬正常）
2. 重開機
3. 建立 `snap-phase-c` 快照
4. 啟動 GDM

## 常見問題

詳見 [KNOWN_ISSUES.md](KNOWN_ISSUES.md)
