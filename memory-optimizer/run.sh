#!/usr/bin/env bash
# memory-optimizer/run.sh
# 獨立執行版本，可加入系統 crontab 實現真正的每日持久排程
# 用法：bash ~/.claude/skills/memory-optimizer/run.sh

MEMORY_DIR="$HOME/.claude/projects/-home-deck/memory"

echo "[memory-optimizer] 開始優化 $(date '+%Y-%m-%d %H:%M')"

before=$(du -sb "$MEMORY_DIR"/*.md 2>/dev/null | awk '{sum+=$1} END{print sum}')

# 啟動 claude 執行優化
claude --print "請對 $MEMORY_DIR 下所有 project_*.md 套用記憶壓縮規則：
1. 已完成的任務壓縮成 1-2 行摘要
2. 移除 code block，改為路徑引用
3. 保留待辦、下一步、環境設定、已知陷阱
4. reference_*.md 不動
直接覆寫檔案，完成後印出優化了哪些檔案。" 2>&1

after=$(du -sb "$MEMORY_DIR"/*.md 2>/dev/null | awk '{sum+=$1} END{print sum}')

echo "[memory-optimizer] 完成。優化前: ${before} bytes → 優化後: ${after} bytes"
