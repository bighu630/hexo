#!/bin/bash
# 修复版的Hexo发布脚本
# 简单、可靠、适合日常使用

set -e  # 遇到错误立即退出

echo "🚀 开始发布Hexo博客..."
echo "时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 1. 更新主仓库
echo "📦 更新主仓库..."
echo "----------------------------------------"
git pull --rebase || {
    echo "⚠️  拉取失败，尝试强制更新..."
    git fetch --all
    git reset --hard origin/$(git branch --show-current)
}

# 检查是否有更改
if [ -n "$(git status --porcelain)" ]; then
    echo "📝 提交更改..."
    git add .
    git commit -m "更新: $(date '+%Y-%m-%d %H:%M:%S')" || echo "ℹ️  没有需要提交的更改"
    git push
else
    echo "ℹ️  没有未提交的更改"
fi

echo "✅ 主仓库更新完成"
echo ""

# 2. 生成静态网站
echo "🔨 生成静态网站..."
echo "----------------------------------------"

# 清理
echo "🧹 清理旧文件..."
npx hexo clean

# 生成
echo "🏗️  生成新文件..."
if npx hexo g; then
    # 统计生成的文件
    COUNT=$(find public -type f -name "*.html" | wc -l)
    echo "✅ 生成完成！共 $COUNT 个HTML文件"
else
    echo "❌ 生成失败！"
    echo "尝试修复Stylus错误..."
    
    # 尝试修复常见的Stylus错误
    echo "修复颜色配置..."
    sed -i "s/card: '#fff'/card: '#ffffff'/" _config.volantis.yml 2>/dev/null || true
    sed -i "s/card: '#444'/card: '#444444'/" _config.volantis.yml 2>/dev/null || true
    
    echo "重新生成..."
    npx hexo g
fi

echo ""

# 3. 部署到GitHub
echo "🚀 部署到GitHub Pages..."
echo "----------------------------------------"

if npx hexo deploy; then
    echo "✅ 部署成功！"
else
    echo "⚠️  Hexo部署失败，尝试手动部署..."
    
    cd public
    echo "手动部署public目录..."
    
    # 初始化git（如果需要）
    if [ ! -d ".git" ]; then
        git init
        git remote add origin git@github.com:bighu630/bighu630.github.io.git 2>/dev/null || true
    fi
    
    # 添加并提交
    git add .
    git commit -m "部署: $(date '+%Y-%m-%d %H:%M:%S')" || echo "ℹ️  提交失败（可能没有更改）"
    
    # 强制推送
    git push -f origin master
    
    cd ..
    echo "✅ 手动部署完成！"
fi

echo ""

# 4. 完成信息
echo "🎉 发布完成！"
echo "========================================"
echo "博客地址: https://bighu630.github.io"
echo "完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo ""

# 显示最新文章
echo "📄 最新文章:"
find public -name "*.html" -type f -exec ls -lt {} + 2>/dev/null | head -3 | while read line; do
    filename=$(echo "$line" | awk '{print $NF}')
    date=$(echo "$line" | awk '{print $6, $7, $8}')
    echo "  $date - $(basename $(dirname $(dirname "$filename")))/$(basename $(dirname "$filename"))/$(basename "$filename" .html)"
done

echo ""
echo "💡 提示: 访问 https://bighu630.github.io 查看更新"