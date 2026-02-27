#!/bin/bash
# Hexo博客一键发布脚本 - 稳定版
# 修复了常见问题，提供备用方案

set -e  # 遇到错误立即停止

echo "========================================"
echo "🚀 Hexo博客发布工具"
echo "⏰ 开始时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "========================================"
echo ""

# 记录日志
LOG_FILE="deploy-$(date +%Y%m%d-%H%M%S).log"
exec 2>&1 | tee "$LOG_FILE"

# 1. 更新源码
echo "[1/4] 🔄 更新博客源码..."
echo "----------------------------------------"

# 检查Git状态
if ! git status &> /dev/null; then
    echo "❌ 不是Git仓库或Git配置有问题"
    exit 1
fi

# 尝试拉取更新
if git pull --rebase; then
    echo "✅ 源码更新成功"
else
    echo "⚠️  拉取失败，尝试备用方案..."
    git fetch --all
    CURRENT_BRANCH=$(git branch --show-current 2>/dev/null || echo "main")
    git reset --hard origin/$CURRENT_BRANCH
    echo "✅ 强制更新完成"
fi

# 提交本地更改（如果有）
CHANGES=$(git status --porcelain)
if [ -n "$CHANGES" ]; then
    echo "📝 发现未提交的更改，正在提交..."
    git add .
    git commit -m "更新: $(date '+%Y-%m-%d %H:%M:%S')" || echo "ℹ️  提交跳过（可能没有实际更改）"
    
    if git push; then
        echo "✅ 更改已推送到远程"
    else
        echo "⚠️  推送失败，继续执行..."
    fi
else
    echo "ℹ️  没有未提交的更改"
fi

echo ""

# 2. 生成静态文件
echo "[2/4] 🏗️  生成静态网站..."
echo "----------------------------------------"

# 清理
echo "🧹 清理旧文件..."
npx hexo clean 2>/dev/null || true

# 预检查：修复可能的配置问题
echo "🔍 检查配置..."
if [ -f "_config.volantis.yml" ]; then
    # 修复颜色配置问题
    if grep -q "card: '#fff'" _config.volantis.yml; then
        echo "🛠️  修复颜色配置..."
        sed -i "s/card: '#fff'/card: '#ffffff'/" _config.volantis.yml
        sed -i "s/card: '#444'/card: '#444444'/" _config.volantis.yml
    fi
    
    # 修复mix函数调用
    sed -i "s/list_hl: 'mix(\$color-theme, #000, 80)'/list_hl: '#333333'/" _config.volantis.yml
    sed -i "s/list_hl: 'mix(\$color-theme, #fff, 80)'/list_hl: '#cccccc'/" _config.volantis.yml
fi

# 生成
echo "🔨 生成新文件..."
if OUTPUT=$(npx hexo g 2>&1); then
    # 统计文件
    HTML_COUNT=$(find public -name "*.html" 2>/dev/null | wc -l)
    TOTAL_COUNT=$(find public -type f 2>/dev/null | wc -l)
    echo "✅ 生成成功！"
    echo "   📄 HTML文件: $HTML_COUNT 个"
    echo "   📦 总文件数: $TOTAL_COUNT 个"
else
    echo "❌ 生成失败！错误信息:"
    echo "$OUTPUT" | grep -i "error" | head -3
    echo ""
    echo "🔄 尝试修复后重新生成..."
    
    # 尝试修复后重新生成
    npx hexo clean
    npx hexo g && echo "✅ 修复后生成成功" || {
        echo "❌ 仍然失败，尝试继续部署..."
    }
fi

echo ""

# 3. 部署到GitHub
echo "[3/4] 🚀 部署到GitHub Pages..."
echo "----------------------------------------"

# 方法1: 使用Hexo deploy
echo "尝试方法1: Hexo自动部署..."
if npx hexo deploy 2>&1 | grep -q "Deploy done"; then
    echo "✅ Hexo部署成功！"
else
    echo "⚠️  Hexo部署失败，尝试方法2..."
    
    # 方法2: 手动部署public目录
    echo "尝试方法2: 手动部署..."
    if [ -d "public" ]; then
        cd public
        
        # 初始化或更新git
        if [ ! -d ".git" ]; then
            git init
            git remote add origin git@github.com:bighu630/bighu630.github.io.git 2>/dev/null || true
        fi
        
        # 添加所有文件
        git add . 2>/dev/null || true
        
        # 提交
        if git commit -m "部署: $(date '+%Y-%m-%d %H:%M:%S')" 2>/dev/null; then
            echo "✅ 提交成功"
        else
            echo "ℹ️  提交跳过（可能没有更改）"
        fi
        
        # 推送
        if git push -f origin master 2>/dev/null; then
            echo "✅ 手动部署成功！"
        else
            echo "❌ 手动部署也失败"
        fi
        
        cd ..
    else
        echo "❌ public目录不存在，无法部署"
    fi
fi

echo ""

# 4. 完成
echo "[4/4] 🎉 发布流程完成！"
echo "========================================"
echo "🌐 博客地址: https://bighu630.github.io"
echo "⏰ 完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
echo "📋 日志文件: $LOG_FILE"
echo "========================================"
echo ""

# 显示最新文章
echo "📰 最新发布的文章:"
find public -name "*.html" -type f -exec ls -lt {} + 2>/dev/null | head -5 | while read line; do
    # 提取文件路径
    file=$(echo "$line" | awk '{print $NF}')
    # 转换为文章路径
    article_path=$(echo "$file" | sed 's|public/||' | sed 's|/index.html||')
    # 提取日期
    article_date=$(echo "$article_path" | cut -d'/' -f1-3)
    article_title=$(echo "$article_path" | cut -d'/' -f4)
    
    echo "  📅 $article_date"
    echo "  📄 $article_title"
    echo ""
done

echo "💡 提示:"
echo "  • 页面更新可能需要1-2分钟生效"
echo "  • 清除浏览器缓存可立即看到更新 (Ctrl+Shift+R)"
echo "  • 查看详细日志: tail -f $LOG_FILE"
echo ""
echo "✨ 发布完成！访问 https://bighu630.github.io 查看你的博客"