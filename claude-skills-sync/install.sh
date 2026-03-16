#!/usr/bin/env bash
# claude-skills-sync/install.sh
# 在新機器上設定 claude-skills 環境
# 用法：bash ~/.claude/skills/claude-skills-sync/install.sh

set -e

REPO_URL="https://github.com/tern/claude-skills.git"
REPO_DIR="$HOME/claude-skills"
SKILLS_DIR="$HOME/.claude/skills"

echo "[claude-skills-sync] 開始安裝..."

# 1. clone repo（若尚未存在）
if [ ! -d "$REPO_DIR/.git" ]; then
  echo "[claude-skills-sync] Clone repo 到 $REPO_DIR"
  git clone "$REPO_URL" "$REPO_DIR"
else
  echo "[claude-skills-sync] $REPO_DIR 已存在，跳過 clone"
fi

# 2. 建立 symlinks
mkdir -p "$SKILLS_DIR"
for skill_dir in "$REPO_DIR"/*/; do
  skill_name=$(basename "$skill_dir")
  target="$SKILLS_DIR/$skill_name"
  if [ ! -e "$target" ]; then
    ln -s "$skill_dir" "$target"
    echo "[claude-skills-sync] symlink: $skill_name"
  else
    echo "[claude-skills-sync] 已存在，跳過: $skill_name"
  fi
done

# 3. 設定 post-commit hook（每次 commit 後自動 push）
HOOK_FILE="$REPO_DIR/.git/hooks/post-commit"
if [ ! -f "$HOOK_FILE" ]; then
  cat > "$HOOK_FILE" <<'HOOK'
#!/usr/bin/env bash
git push origin main 2>&1 | sed 's/^/[claude-skills] /'
HOOK
  chmod +x "$HOOK_FILE"
  echo "[claude-skills-sync] post-commit hook 已設定（commit 後自動 push）"
else
  echo "[claude-skills-sync] post-commit hook 已存在，跳過"
fi

# 4. 設定 PM2 排程（若有 PM2）
if command -v pm2 >/dev/null 2>&1; then
  if ! pm2 list | grep -q "claude-skills-sync"; then
    pm2 start "$REPO_DIR/sync.sh" --name "claude-skills-sync" --cron "47 8 * * *" --no-autorestart
    pm2 save
    echo "[claude-skills-sync] PM2 排程已設定（每天 08:47）"
  else
    echo "[claude-skills-sync] PM2 排程已存在，跳過"
  fi
fi

echo "[claude-skills-sync] 安裝完成 ✅"
