#!/usr/bin/env bash
# memory-optimizer/run.sh
# 獨立執行版本，每日由 PM2 排程觸發
# 用法：bash ~/.claude/skills/memory-optimizer/run.sh

# 自動偵測 Claude Code 記憶目錄
# Claude Code 的專案記憶路徑規則：將 $HOME 的 / 換成 - 作為目錄名
_detect_memory_dir() {
  local home_slug
  home_slug=$(echo "$HOME" | sed 's|/|-|g' | sed 's/^-//')
  echo "$HOME/.claude/projects/-${home_slug}/memory"
}

MEMORY_DIR="${CLAUDE_MEMORY_DIR:-$(_detect_memory_dir)}"

if [ ! -d "$MEMORY_DIR" ]; then
  echo "[memory-optimizer] 找不到記憶目錄：$MEMORY_DIR"
  echo "[memory-optimizer] 請設定 CLAUDE_MEMORY_DIR 環境變數指向正確路徑"
  exit 1
fi

echo "[memory-optimizer] 開始優化 $(date '+%Y-%m-%d %H:%M')"
echo "[memory-optimizer] 記憶目錄：$MEMORY_DIR"

before=$(du -sb "$MEMORY_DIR"/*.md 2>/dev/null | awk '{sum+=$1} END{print sum}')

claude --print "請對 $MEMORY_DIR 下所有 project_*.md 套用記憶壓縮規則：
1. 已完成的任務壓縮成 1-2 行摘要
2. 移除 code block，改為路徑引用
3. 保留待辦、下一步、環境設定、已知陷阱
4. reference_*.md 不動
直接覆寫檔案，完成後印出優化了哪些檔案。" 2>&1

after=$(du -sb "$MEMORY_DIR"/*.md 2>/dev/null | awk '{sum+=$1} END{print sum}')
saved=$((before - after))

echo "[memory-optimizer] 完成。優化前: ${before} bytes → 優化後: ${after} bytes（節省 ${saved} bytes）"
