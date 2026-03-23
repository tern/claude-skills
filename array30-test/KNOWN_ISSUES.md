# array30-test — 已知問題與修法

本文件記錄 VM 測試流程中發現並修正的問題，供未來除錯參考。

---

## B1：等待 cloud-init 卡住最多 5 分鐘

**症狀：** `[B1] 等待 cloud-init 完成…` 後每 15 秒印一行，等到 300 秒才繼續。

**原因：** cloud-init 已 disabled，不會產生 `/var/lib/cloud/instance/boot-finished-marker`。

**修法（已修）：** 在等待條件加入 `cloud-init status` 回傳 `disabled` 也視為完成。

```bash
# create-vm.sh 中的等待條件
if try_ssh "test -f /var/lib/cloud/instance/boot-finished-marker || \
    cloud-init status 2>/dev/null | grep -qE 'done|disabled'"; then
```

---

## C2：select_engine() 在 SSH/pipe 模式 exit 1

**症狀：** Phase C 安裝失敗，exit code 1，log 顯示選單後立即結束。

**原因：** `set -e` + `read` 在非 TTY stdin 收到 EOF 時 exit 1。

**修法（已修）：** `select_engine()` 加 `IS_PIPE` 檢查，自動選 fcitx5。

---

## C2（ibus）：下載字根表失敗 404

**症狀：** `[ERROR] 下載字根表失敗，請確認網路連線`

**原因 1：** 硬寫 `main` 分支，gontera/array30 實際用 `master`。

**原因 2：** cin 檔案在 `OpenVanilla/` 子目錄，且有版本號後綴：
`array30-OpenVanilla-big-v2023-1.0-20230211.cin`

**修法（已修）：** 新增 `IBUS_CIN_URL` 常數：
```bash
IBUS_CIN_URL="$ARRAY30_CIN_RAW/OpenVanilla/array30-OpenVanilla-big-v2023-1.0-20230211.cin"
```

驗證 URL 是否有效：
```bash
curl -sI "https://raw.githubusercontent.com/gontera/array30/master/OpenVanilla/array30-OpenVanilla-big-v2023-1.0-20230211.cin" | grep "HTTP\|content-length"
# 預期：HTTP/2 200，content-length: 1098835
```

---

## C2（ibus）：安裝成功但 exit code 1（tmpdir unbound）

**症狀：** 安裝成功訊息後出現 `列 N: tmpdir: 未綁定的變數`，exit 1。

**原因：** bash `trap 'rm -rf "$tmpdir"' RETURN` 不限函式作用域 —
`do_install_ibus()` 返回後 trap 仍殘留，父函式 `do_install()` 執行 `return` 時再次觸發，
此時 `tmpdir` 已超出作用域。

**修法（已修）：** `do_install_ibus()` 結尾加 `trap - RETURN`。

---

## C3：diagnose 非零 exit 中斷 create-vm.sh（ibus 路線）

**症狀：** ibus 安裝成功後，C3 diagnose 跑一半 create-vm.sh 就結束，
不建快照也不顯示最終摘要。

**原因：** diagnose 在 ibus 路線因找不到 fcitx5 而 exit 非零，
`set -e` 讓 create-vm.sh 一起中斷。

**修法（已修）：** C3 diagnose 命令用 `set +e` 包住。

---

## snap-phase-c 重複建立失敗

**症狀：** `operation failed: domain moment snap-phase-c already exists`

**原因：** 上次測試已建立，再跑時未先刪除。

**修法（已修）：** `create_snapshot()` 改為先刪（若存在）再建。

---

## ARRAY30_TEST_ENGINE env var 未傳進子 process

**症狀：** `ARRAY30_TEST_ENGINE=ibus printf "..." | bash create-vm.sh` — env var 設給 `printf` 而非 bash。

**修法：** 必須用 `export`：
```bash
export ARRAY30_TEST_ENGINE=ibus
printf "1\ny\ny\n" | bash create-vm.sh > /tmp/array30-test.log 2>&1 &
```
