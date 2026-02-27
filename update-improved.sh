#!/bin/bash
# 改进的Hexo博客发布脚本
# 功能：自动更新、生成、部署Hexo博客

set -e  # 遇到错误立即退出
set -u  # 使用未定义变量时报错

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志文件
LOG_FILE="deploy.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# 函数：打印带颜色的消息
print_message() {
    local level="$1"
    local message="$2"
    
    case "$level" in
        "INFO")
            echo -e "${BLUE}[INFO]${NC} $message"
            ;;
        "SUCCESS")
            echo -e "${GREEN}[SUCCESS]${NC} $message"
            ;;
        "WARNING")
            echo -e "${YELLOW}[WARNING]${NC} $message"
            ;;
        "ERROR")
            echo -e "${RED}[ERROR]${NC} $message"
            ;;
    esac
    
    # 记录到日志文件
    echo "[$TIMESTAMP] [$level] $message" >> "$LOG_FILE"
}

# 函数：检查命令是否存在
check_command() {
    if ! command -v "$1" &> /dev/null; then
        print_message "ERROR" "命令 '$1' 未找到，请先安装"
        exit 1
    fi
}

# 函数：检查Git配置
check_git_config() {
    local user_name=$(git config --global user.name)
    local user_email=$(git config --global user.email)
    
    if [ -z "$user_name" ] || [ -z "$user_email" ]; then
        print_message "WARNING" "Git用户配置不完整"
        echo "当前配置:"
        echo "  user.name: $user_name"
        echo "  user.email: $user_email"
        echo ""
        echo "请设置Git配置:"
        echo "  git config --global user.name 'Your Name'"
        echo "  git config --global user.email 'your.email@example.com'"
        exit 1
    fi
    
    print_message "INFO" "Git配置检查通过: $user_name <$user_email>"
}

# 函数：检查Hexo环境
check_hexo_env() {
    if [ ! -f "package.json" ]; then
        print_message "ERROR" "当前目录不是Hexo项目根目录"
        exit 1
    fi
    
    if ! npx hexo version &> /dev/null; then
        print_message "ERROR" "Hexo命令不可用，请检查Node.js和Hexo安装"
        exit 1
    fi
    
    print_message "INFO" "Hexo环境检查通过"
}

# 函数：更新主仓库
update_main_repo() {
    print_message "INFO" "开始更新主仓库..."
    
    # 检查是否有未提交的更改
    if [ -n "$(git status --porcelain)" ]; then
        print_message "INFO" "发现未提交的更改，正在提交..."
        git add .
        git commit -m "更新: $TIMESTAMP" || {
            print_message "WARNING" "提交失败，可能没有实际更改"
        }
    fi
    
    # 拉取远程更新
    print_message "INFO" "拉取远程更新..."
    if git pull --rebase; then
        print_message "SUCCESS" "主仓库更新成功"
    else
        print_message "WARNING" "拉取失败，尝试强制拉取..."
        git fetch --all
        git reset --hard origin/$(git branch --show-current)
    fi
    
    # 推送更改
    print_message "INFO" "推送更改到远程..."
    if git push; then
        print_message "SUCCESS" "主仓库推送成功"
    else
        print_message "ERROR" "推送失败，请检查网络或权限"
        exit 1
    fi
}

# 函数：生成静态文件
generate_site() {
    print_message "INFO" "开始生成静态网站..."
    
    # 清理旧文件
    print_message "INFO" "清理旧文件..."
    if npx hexo clean; then
        print_message "SUCCESS" "清理完成"
    else
        print_message "WARNING" "清理过程中有警告"
    fi
    
    # 生成新文件
    print_message "INFO" "生成静态文件..."
    if npx hexo g; then
        print_message "SUCCESS" "静态文件生成成功"
        
        # 检查生成的文件数量
        local file_count=$(find public -type f -name "*.html" | wc -l)
        print_message "INFO" "生成了 $file_count 个HTML文件"
    else
        print_message "ERROR" "生成失败，请检查Hexo配置"
        exit 1
    fi
}

# 函数：部署到GitHub Pages
deploy_to_github() {
    print_message "INFO" "开始部署到GitHub Pages..."
    
    # 使用Hexo的deploy命令
    if npx hexo deploy; then
        print_message "SUCCESS" "部署到GitHub Pages成功"
    else
        print_message "ERROR" "部署失败"
        
        # 尝试手动部署
        print_message "INFO" "尝试手动部署..."
        deploy_manual
    fi
}

# 函数：手动部署（备用方案）
deploy_manual() {
    print_message "INFO" "使用手动部署方案..."
    
    cd public
    
    # 初始化git（如果未初始化）
    if [ ! -d ".git" ]; then
        print_message "INFO" "初始化public目录git仓库..."
        git init
        git remote add origin git@github.com:bighu630/bighu630.github.io.git || true
    fi
    
    # 添加所有文件
    git add .
    
    # 提交
    if git commit -m "部署: $TIMESTAMP"; then
        print_message "SUCCESS" "提交成功"
    else
        print_message "WARNING" "提交失败，可能没有更改"
    fi
    
    # 强制推送到GitHub Pages
    print_message "INFO" "推送到GitHub Pages..."
    if git push -f origin master; then
        print_message "SUCCESS" "手动部署成功"
    else
        print_message "ERROR" "手动部署失败"
        exit 1
    fi
    
    cd ..
}

# 函数：验证部署
verify_deployment() {
    print_message "INFO" "验证部署..."
    
    # 等待一段时间让GitHub Pages更新
    print_message "INFO" "等待GitHub Pages更新（10秒）..."
    sleep 10
    
    # 检查网站是否可访问（可选）
    print_message "INFO" "部署验证完成"
    print_message "INFO" "博客地址: https://bighu630.github.io"
}

# 函数：显示帮助
show_help() {
    echo -e "${BLUE}Hexo博客发布脚本${NC}"
    echo "================"
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help     显示帮助信息"
    echo "  -d, --dry-run  干运行模式，不实际执行"
    echo "  -f, --force    强制模式，忽略警告"
    echo "  -s, --skip-git 跳过Git操作，只生成网站"
    echo "  --only-deploy  只部署，不更新和生成"
    echo ""
    echo "示例:"
    echo "  $0             正常发布流程"
    echo "  $0 --dry-run   测试发布流程"
    echo "  $0 --skip-git  只生成网站，不更新Git"
    echo ""
    exit 0
}

# 主函数
main() {
    # 解析参数
    local DRY_RUN=false
    local FORCE=false
    local SKIP_GIT=false
    local ONLY_DEPLOY=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -f|--force)
                FORCE=true
                shift
                ;;
            -s|--skip-git)
                SKIP_GIT=true
                shift
                ;;
            --only-deploy)
                ONLY_DEPLOY=true
                shift
                ;;
            *)
                print_message "ERROR" "未知参数: $1"
                show_help
                ;;
        esac
    done
    
    # 显示开始信息
    echo ""
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}    Hexo博客发布工具 v1.0      ${NC}"
    echo -e "${BLUE}================================${NC}"
    echo "开始时间: $TIMESTAMP"
    echo "日志文件: $LOG_FILE"
    echo ""
    
    # 检查必要命令
    print_message "INFO" "检查系统环境..."
    check_command "git"
    check_command "node"
    check_command "npm"
    
    # 检查Git配置
    check_git_config
    
    # 检查Hexo环境
    check_hexo_env
    
    # 干运行模式
    if [ "$DRY_RUN" = true ]; then
        print_message "INFO" "干运行模式，不执行实际操作"
        echo "将执行以下操作:"
        echo "1. 更新主仓库"
        echo "2. 生成静态网站"
        echo "3. 部署到GitHub Pages"
        echo ""
        exit 0
    fi
    
    # 记录开始时间
    local start_time=$(date +%s)
    
    # 执行发布流程
    if [ "$ONLY_DEPLOY" = true ]; then
        print_message "INFO" "只部署模式，跳过更新和生成"
        deploy_to_github
    else
        if [ "$SKIP_GIT" = false ]; then
            update_main_repo
        else
            print_message "INFO" "跳过Git操作"
        fi
        
        generate_site
        deploy_to_github
    fi
    
    # 验证部署
    verify_deployment
    
    # 计算耗时
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    # 显示总结
    echo ""
    echo -e "${GREEN}================================${NC}"
    echo -e "${GREEN}        发布完成！              ${NC}"
    echo -e "${GREEN}================================${NC}"
    echo -e "总耗时: ${duration}秒"
    echo -e "博客地址: https://bighu630.github.io"
    echo -e "日志文件: $LOG_FILE"
    echo -e "完成时间: $(date '+%Y-%m-%d %H:%M:%S')"
    echo ""
    
    # 显示最新文章
    print_message "INFO" "最新生成的文章:"
    find public -name "*.html" -type f -exec ls -lt {} + | head -5 | while read line; do
        echo "  $line"
    done
}

# 异常处理
trap 'print_message "ERROR" "脚本被中断"; exit 1' INT TERM

# 运行主函数
main "$@"

# 记录完成时间
echo "[$TIMESTAMP] [COMPLETE] 脚本执行完成" >> "$LOG_FILE"