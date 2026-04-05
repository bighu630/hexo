#!/bin/bash
# 测试部署脚本（不实际执行）

echo "🔧 测试部署脚本功能..."
echo ""

# 测试1: 检查脚本权限
echo "1. 检查脚本权限:"
ls -la updata.sh updata-fixed.sh update-improved.sh | awk '{print $1, $9}'
echo ""

# 测试2: 检查Git状态
echo "2. 检查Git状态:"
git status --short
echo ""

# 测试3: 检查Hexo环境
echo "3. 检查Hexo环境:"
if npx hexo version &> /dev/null; then
    echo "✅ Hexo可用"
else
    echo "❌ Hexo不可用"
fi
echo ""

# 测试4: 检查配置文件
echo "4. 检查配置文件:"
if [ -f "_config.yml" ]; then
    echo "✅ _config.yml 存在"
else
    echo "❌ _config.yml 不存在"
fi

if [ -f "_config.volantis.yml" ]; then
    echo "✅ _config.volantis.yml 存在"
    
    # 检查颜色配置
    echo "   检查颜色配置:"
    if grep -q "card: '#fff'" _config.volantis.yml; then
        echo "   ⚠️  发现短格式颜色，需要修复"
    else
        echo "   ✅ 颜色格式正常"
    fi
else
    echo "❌ _config.volantis.yml 不存在"
fi
echo ""

# 测试5: 检查public目录
echo "5. 检查public目录:"
if [ -d "public" ]; then
    echo "✅ public目录存在"
    echo "   文件数量: $(find public -type f 2>/dev/null | wc -l)"
else
    echo "❌ public目录不存在"
fi
echo ""

# 测试6: 模拟脚本执行
echo "6. 模拟脚本执行（前几步）:"
echo "   [模拟] git pull --rebase"
echo "   [模拟] npx hexo clean"
echo "   [模拟] npx hexo g"
echo "   [模拟] npx hexo deploy"
echo ""

# 测试7: 显示最新文章
echo "7. 最新文章列表:"
find source/_posts -name "*.md" -type f -exec ls -lt {} + 2>/dev/null | head -5 | while read line; do
    file=$(echo "$line" | awk '{print $NF}')
    date=$(echo "$line" | awk '{print $6, $7, $8}')
    title=$(basename "$file" .md)
    echo "   📅 $date - $title"
done
echo ""

echo "🎯 测试完成！"
echo "建议操作:"
echo "1. 运行 ./updata.sh 进行完整发布"
echo "2. 或运行 ./update-improved.sh --dry-run 进行干运行测试"
echo "3. 查看 DEPLOY-README.md 获取详细说明"