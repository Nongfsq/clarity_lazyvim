#!/bin/bash

# 定义本地和仓库目录
LOCAL_DIR="/Users/meng/.config/nvim"
REPO_DIR="/Users/meng/Github/my_nvim_config/nvim"

# 确保目标目录存在
mkdir -p "$REPO_DIR"

# 同步本地文件到仓库目录
echo "Copying files from $LOCAL_DIR to $REPO_DIR..."
rsync -av --delete "$LOCAL_DIR/" "$REPO_DIR/"

# 进入仓库目录
cd /Users/meng/Github/my_nvim_config

# 检查 Git 状态，添加更改到 Git
if [ -n "$(git status --porcelain)" ]; then
    echo "Adding and committing changes..."
    git add nvim
    git commit -m "Auto-sync nvim configuration files"

    # 推送更改到 GitHub
    echo "Pushing changes to GitHub..."
    git push origin main
else
    echo "No changes to commit."
fi

echo "Sync complete."
