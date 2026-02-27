# Hexo博客发布工具说明

## 📁 可用脚本

### 1. `updata.sh` - 主发布脚本（推荐）
```bash
./updata.sh
```
**特点**：
- 简单直接，一键发布
- 自动修复常见错误（如Stylus颜色配置）
- 提供详细的进度反馈
- 包含备用部署方案

### 2. `update-improved.sh` - 高级发布脚本
```bash
# 基本用法
./update-improved.sh

# 干运行模式（测试）
./update-improved.sh --dry-run

# 只部署，不更新源码
./update-improved.sh --only-deploy

# 跳过Git操作，只生成网站
./update-improved.sh --skip-git

# 强制模式
./update-improved.sh --force
```

**特点**：
- 完整的错误处理和日志记录
- 支持多种运行模式
- 环境检查和安全验证
- 详细的部署报告

### 3. `updata-fixed.sh` - 修复版脚本
```bash
./updata-fixed.sh
```
**特点**：
- 介于简单和高级之间
- 更好的错误恢复
- 手动部署备用方案

## 🚀 快速开始

### 最简单的发布方式：
```bash
cd /home/ivhu/文档/hexo
./updata.sh
```

### 如果遇到问题，尝试：
```bash
# 使用高级脚本的干运行模式检查问题
./update-improved.sh --dry-run

# 只生成网站，不部署
./update-improved.sh --skip-git

# 手动检查Git状态
git status
git pull --rebase
```

## 🔧 常见问题解决

### 1. Git相关错误
**问题**：`git pull`失败
**解决**：
```bash
# 保存本地更改
git stash

# 强制更新
git fetch --all
git reset --hard origin/$(git branch --show-current)

# 恢复本地更改
git stash pop
```

### 2. Hexo生成错误
**问题**：Stylus颜色错误
**解决**：脚本已自动修复，或手动修改：
```bash
# 修复颜色配置
sed -i "s/card: '#fff'/card: '#ffffff'/" _config.volantis.yml
sed -i "s/card: '#444'/card: '#444444'/" _config.volantis.yml
```

### 3. 部署失败
**问题**：`hexo deploy`失败
**解决**：使用备用方案
```bash
cd public
git add .
git commit -m "手动部署"
git push -f origin master
cd ..
```

## 📊 脚本功能对比

| 功能 | updata.sh | update-improved.sh | updata-fixed.sh |
|------|-----------|-------------------|-----------------|
| 一键发布 | ✅ | ✅ | ✅ |
| 错误处理 | 基础 | 完整 | 中等 |
| 日志记录 | 简单 | 详细 | 简单 |
| 干运行模式 | ❌ | ✅ | ❌ |
| 环境检查 | ❌ | ✅ | ❌ |
| 自动修复 | ✅ | ✅ | ✅ |
| 备用方案 | ✅ | ✅ | ✅ |
| 进度显示 | ✅ | ✅ | ✅ |

## 🎯 推荐使用场景

### 日常发布
```bash
# 使用主脚本
./updata.sh
```

### 调试问题
```bash
# 使用高级脚本检查
./update-improved.sh --dry-run

# 查看日志
tail -f deploy.log
```

### 批量操作
```bash
# 只更新内容，不发布
./update-improved.sh --skip-git

# 只发布，不更新
./update-improved.sh --only-deploy
```

## ⚙️ 配置说明

### Git配置检查
脚本会检查以下配置：
```bash
git config --global user.name "Your Name"
git config --global user.email "your.email@example.com"
```

### Hexo配置
确保以下文件存在：
- `_config.yml` - Hexo主配置
- `_config.volantis.yml` - 主题配置
- `package.json` - 依赖配置

### 部署配置
在`_config.yml`中：
```yaml
deploy:
  type: git
  repo: git@github.com:bighu630/bighu630.github.io.git
  branch: master
  message: '自动部署'
```

## 📝 使用示例

### 示例1：正常发布流程
```bash
$ ./updata.sh
========================================
Hexo博客发布工具
开始时间: 2026-02-27 19:56:47
========================================

[1/4] 🔄 更新博客源码...
✅ 源码更新成功

[2/4] 🏗️  生成静态网站...
🧹 清理旧文件...
🔨 生成新文件...
✅ 生成完成！共 235 个页面

[3/4] 🚀 部署到GitHub Pages...
✅ 部署成功！

[4/4] 🎉 发布完成！
========================================
🌐 博客地址: https://bighu630.github.io
⏰ 完成时间: 2026-02-27 19:57:12
📊 生成统计:
   - HTML文件: 216 个
   - 总文件数: 1245 个
========================================

最新文章:
  📄 2026/02/27/PostgreSQL慢查询故障排查实战
  📄 2026/02/27/Chainlink-链下计算机制深入解析
  📄 2025/06/30/bg一面面经
```

### 示例2：遇到错误时的处理
```bash
$ ./updata.sh
...
❌ 生成失败，检查错误信息:
ERROR expected rgba or hsla, but got ident:$color-card
🛠️  修复颜色配置...
✅ 生成完成！共 235 个页面
...
```

## 🔄 集成到工作流

### 1. 写作后自动发布
```bash
#!/bin/bash
# write-and-publish.sh

# 1. 创建新文章
npx hexo new "文章标题"

# 2. 编辑文章
vim source/_posts/文章标题.md

# 3. 发布
./updata.sh
```

### 2. 定时自动发布
```cron
# 每天凌晨2点自动发布
0 2 * * * cd /home/ivhu/文档/hexo && ./updata.sh >> /var/log/hexo-deploy.log 2>&1
```

### 3. Git钩子自动发布
```bash
# .git/hooks/post-commit
#!/bin/bash
cd /home/ivhu/文档/hexo
./updata.sh
```

## 🛡️ 安全建议

### 1. 备份重要文件
```bash
# 备份配置
cp _config.yml _config.yml.backup
cp _config.volantis.yml _config.volantis.yml.backup

# 备份文章
tar -czf posts-backup-$(date +%Y%m%d).tar.gz source/_posts/
```

### 2. 版本控制
```bash
# 提交所有更改
git add .
git commit -m "备份: $(date '+%Y-%m-%d')"

# 推送到远程
git push
```

### 3. 恢复策略
```bash
# 恢复配置
cp _config.yml.backup _config.yml
cp _config.volantis.yml.backup _config.volantis.yml

# 重新生成
npx hexo clean
npx hexo g
```

## 📈 性能优化

### 1. 减少生成时间
```bash
# 跳过不需要的页面
# 在 _config.yml 中添加
skip_render:
  - "drafts/**"
  - "private/**"
```

### 2. 优化图片
```bash
# 使用图片压缩
find source/images -name "*.jpg" -exec convert {} -quality 85 {} \;
```

### 3. 缓存优化
```bash
# 清理缓存
rm -rf .cache
rm -rf db.json
```

## 🎨 自定义脚本

### 创建个性化脚本
```bash
#!/bin/bash
# my-deploy.sh

# 自定义变量
BLOG_DIR="/home/ivhu/文档/hexo"
LOG_FILE="$BLOG_DIR/deploy-$(date +%Y%m%d).log"

# 执行发布
cd "$BLOG_DIR"
./updata.sh 2>&1 | tee "$LOG_FILE"

# 发送通知
echo "博客已更新: https://bighu630.github.io" | mail -s "博客更新通知" ivhu@foxmail.com
```

## ❓ 常见问题

### Q1: 脚本没有执行权限？
```bash
chmod +x updata.sh update-improved.sh updata-fixed.sh
```

### Q2: 如何查看详细日志？
```bash
# 查看部署日志
tail -f deploy.log

# 查看Hexo生成日志
npx hexo g --debug
```

### Q3: 如何回滚到上一个版本？
```bash
# 在public目录中
cd public
git log --oneline
git reset --hard <commit-hash>
git push -f origin master
```

### Q4: 网站更新后看不到变化？
- GitHub Pages需要1-2分钟更新
- 清除浏览器缓存：Ctrl+Shift+R
- 使用无痕模式访问

## 📞 支持与反馈

### 问题报告
```bash
# 收集调试信息
./update-improved.sh --dry-run > debug.log 2>&1
npx hexo version >> debug.log
git status >> debug.log
```

### 功能建议
欢迎提出改进建议：
1. 记录在 `DEPLOY-README.md` 中
2. 或直接修改脚本文件

### 更新脚本
```bash
# 从Git更新脚本
git pull origin master

# 手动更新
cp update-improved.sh updata.sh
```

---

**最后更新**: 2026-02-27  
**适用版本**: Hexo 6.x, Volantis 5.x  
**维护者**: ivhu