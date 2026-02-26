#!/bin/bash

# ============================================
# 服务器环境升级与维护脚本
# 功能：自动化升级操作系统、内核、容器环境、编程语言和常用服务
# 版本：3.1
# 最后更新：2026-01-20
# ============================================

# ================= 重要声明 =================
# 免责声明：本脚本仅供学习和参考使用。在生产环境使用前，请在测试环境充分验证。
# 使用本脚本即表示您已了解并接受相关风险，作者不承担因使用本脚本导致的任何责任。
# 安全提示：请确保从可信来源下载脚本，并确保有系统完整备份。
# ============================================

# ============================================
# 第一部分：一键安装模式
# ============================================

# 脚本安装位置
SCRIPT_INSTALL_DIR="/usr/local/bin"
SCRIPT_NAME="serverboost"
SCRIPT_PATH="$SCRIPT_INSTALL_DIR/$SCRIPT_NAME"
SCRIPT_URL="https://shell.umrc.cn/scripts/serverboost.sh"
SCRIPT_VERSION="3.1"

# 所有文件都放在 /serverboost/ 目录下
INSTALL_BASE_DIR="/serverboost"
CONFIG_DIR="$INSTALL_BASE_DIR/config"
LOG_DIR="$INSTALL_BASE_DIR/logs"
BACKUP_DIR="$INSTALL_BASE_DIR/backups"
CACHE_DIR="$INSTALL_BASE_DIR/cache"

# 显示使用说明
show_usage() {
    clear
    cat << EOF
============================================
服务器环境升级与维护脚本 v$SCRIPT_VERSION
============================================

✅脚本安装完成！

 文件位置：
  主程序: $SCRIPT_PATH
  数据目录: $INSTALL_BASE_DIR/
    ├── config/     # 配置文件
    ├── logs/       # 运行日志
    ├── backups/    # 备份文件
    └── cache/      # 缓存文件

 使用方法(命令)：
  1. 启动交互式菜单：
     sudo serverboost

  2. 全自动升级模式：
     sudo serverboost --auto

  3. 自定义升级模式：
     sudo serverboost --custom

  4. 查看帮助信息：
     serverboost --help

  5. 更新脚本到最新版：
     sudo serverboost --update

  6. 卸载脚本：
     sudo serverboost --uninstall

 快速开始：
  推荐先查看系统信息：
  sudo serverboost --info

  然后选择升级模式：
  sudo serverboost

⚠️ 注意：
  1. 建议在业务低峰期执行升级
  2. 确保有系统完整备份
  3. 执行过程中不要中断脚本

 支持：
  官网: https://shell.umrc.cn
  脚本: $SCRIPT_URL

现在您可以运行: sudo serverboost
============================================
EOF
}

# 显示脚本信息
show_info() {
    cat << EOF
服务器环境升级与维护脚本 v$SCRIPT_VERSION

文件位置:
  主程序: $SCRIPT_PATH
  数据目录: $INSTALL_BASE_DIR/

使用方法:
  sudo serverboost          # 启动交互式菜单
  sudo serverboost --auto   # 全自动模式
  sudo serverboost --custom # 自定义模式
  serverboost --help        # 查看帮助

已安装: $(if [ -f "$SCRIPT_PATH" ]; then echo "是"; else echo "否"; fi)

检查安装:
  主程序: $(if [ -f "$SCRIPT_PATH" ]; then echo "✓ 已安装"; else echo "✗ 未安装"; fi)
  数据目录: $(if [ -d "$INSTALL_BASE_DIR" ]; then echo "✓ 已创建"; else echo "✗ 未创建"; fi)
EOF
    exit 0
}

# 显示帮助信息
show_help() {
    cat << EOF
服务器环境升级与维护脚本 v$SCRIPT_VERSION

使用方法:
  serverboost [选项]

选项:
  --install           安装脚本到系统
  --uninstall         从系统卸载脚本
  --update            更新脚本到最新版本
  --info              显示脚本信息
  --help              显示此帮助信息
  --auto              全自动模式（不显示菜单）
  --custom            自定义模式

快速安装:
  1. 一键安装脚本:
     sudo bash -c 'cd /tmp && (curl -sSL $SCRIPT_URL -o serverboost.sh || wget -q $SCRIPT_URL -O serverboost.sh) && chmod +x serverboost.sh && bash serverboost.sh'

  2. 或使用更简短的命令:
     bash <(curl -sSL $SCRIPT_URL || wget -q $SCRIPT_URL -O -)

  3. 使用脚本:
     sudo serverboost

  4. 全自动升级:
     sudo serverboost --auto

  5. 查看帮助:
     serverboost --help

安装位置:
  主程序: $SCRIPT_PATH
  数据目录: $INSTALL_BASE_DIR/
EOF
    exit 0
}

# 创建目录结构
create_directories() {
    echo "创建目录结构..."
    
    # 创建所有需要的目录
    mkdir -p "$INSTALL_BASE_DIR"
    mkdir -p "$CONFIG_DIR"
    mkdir -p "$LOG_DIR"
    mkdir -p "$BACKUP_DIR"
    mkdir -p "$CACHE_DIR"
    
    # 设置权限
    chmod 755 "$INSTALL_BASE_DIR"
    chmod 750 "$CONFIG_DIR"
    chmod 755 "$LOG_DIR"
    chmod 755 "$BACKUP_DIR"
    chmod 755 "$CACHE_DIR"
    
    # 创建日志子目录
    mkdir -p "$LOG_DIR/upgrade"
    mkdir -p "$LOG_DIR/install"
}

# 安装脚本到系统
install_script() {
    echo "正在安装服务器环境升级与维护脚本..."
    
    # 检查是否为root用户
    if [[ $EUID -ne 0 ]]; then
        echo "错误: 需要root权限安装脚本"
        echo "请使用: sudo $0"
        exit 1
    fi
    
    # 创建目录结构
    create_directories
    
    # 备份旧脚本（如果存在）
    if [ -f "$SCRIPT_PATH" ]; then
        echo "备份旧版本脚本..."
        BACKUP_FILE="$BACKUP_DIR/script-backup-$(date +%Y%m%d_%H%M%S).sh"
        cp "$SCRIPT_PATH" "$BACKUP_FILE"
        echo "旧脚本已备份到: $BACKUP_FILE"
    fi
    
    # 获取脚本内容
    echo "下载脚本..."
    if command -v wget >/dev/null 2>&1; then
        wget -q -O "$SCRIPT_PATH" "$SCRIPT_URL"
    elif command -v curl >/dev/null 2>&1; then
        curl -fsSL -o "$SCRIPT_PATH" "$SCRIPT_URL"
    else
        echo "错误: 需要 wget 或 curl 下载脚本"
        echo "请手动下载: $SCRIPT_URL"
        exit 1
    fi
    
    if [ ! -f "$SCRIPT_PATH" ] || [ ! -s "$SCRIPT_PATH" ]; then
        echo "错误: 下载脚本失败"
        exit 1
    fi
    
    # 设置权限
    echo "设置执行权限..."
    chmod +x "$SCRIPT_PATH"
    
    # 创建符号链接到/usr/bin（可选）
    if [ ! -L "/usr/bin/serverboost" ]; then
        ln -sf "$SCRIPT_PATH" "/usr/bin/serverboost" 2>/dev/null || true
    fi
    
    # 创建默认配置文件
    if [ ! -f "$CONFIG_DIR/config.sh" ]; then
        cat > "$CONFIG_DIR/config.sh" << 'EOF'
# 服务器环境升级与维护脚本配置文件

# 需要保留的旧内核数量
KEEP_OLD_KERNELS=2

# 需要升级的编程语言版本
PYTHON_VERSION="3.11"
NODE_VERSION="20"
PHP_VERSION="8.2"

# 需要重启的服务列表
SERVICES_TO_RESTART=("nginx" "apache2" "mysql" "postgresql" "redis-server" "docker")

# 自动模式设置
AUTO_UPGRADE_OS="yes"
AUTO_UPGRADE_KERNEL="yes"
AUTO_UPGRADE_DOCKER="yes"
AUTO_UPGRADE_PODMAN="yes"
AUTO_UPGRADE_PYTHON="yes"
AUTO_UPGRADE_NODEJS="yes"
AUTO_UPGRADE_PHP="yes"
EOF
        chmod 644 "$CONFIG_DIR/config.sh"
    fi
    
    # 记录安装日志
    echo "$(date): 脚本安装完成" >> "$LOG_DIR/install/install.log"
    echo "版本: $SCRIPT_VERSION" >> "$LOG_DIR/install/install.log"
    
    # 显示使用说明
    show_usage
    
    # 询问是否立即执行
    echo ""
    read -p "是否立即运行脚本？(y/N): " run_now
    if [[ "$run_now" == "y" || "$run_now" == "Y" ]]; then
        # 切换到已安装的脚本
        echo "正在启动脚本..."
        sleep 2
        exec "$SCRIPT_PATH"
    else
        echo ""
        echo "您可以在需要时运行: sudo serverboost"
        exit 0
    fi
}

# 卸载脚本
uninstall_script() {
    echo "正在卸载服务器环境升级与维护脚本..."
    
    # 检查是否为root用户
    if [[ $EUID -ne 0 ]]; then
        echo "错误: 需要root权限卸载脚本"
        echo "请使用: sudo serverboost --uninstall"
        exit 1
    fi
    
    echo "以下文件和目录将被处理:"
    echo "  $SCRIPT_PATH"
    echo "  $INSTALL_BASE_DIR/"
    echo ""
    
    read -p "确认卸载？(y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "卸载已取消"
        return 1
    fi
    
    # 删除主程序
    if [ -f "$SCRIPT_PATH" ]; then
        echo "删除主程序: $SCRIPT_PATH"
        rm -f "$SCRIPT_PATH"
    fi
    
    # 删除符号链接（如果有）
    if [ -L "/usr/bin/serverboost" ]; then
        echo "删除符号链接: /usr/bin/serverboost"
        rm -f "/usr/bin/serverboost"
    fi
    
    # 询问是否删除数据目录
    read -p "是否删除数据目录 $INSTALL_BASE_DIR/ 及其所有内容？(y/N): " confirm_data
    if [[ "$confirm_data" == "y" || "$confirm_data" == "Y" ]]; then
        if [ -d "$INSTALL_BASE_DIR" ]; then
            echo "删除数据目录: $INSTALL_BASE_DIR/"
            rm -rf "$INSTALL_BASE_DIR"
        fi
    else
        echo "保留数据目录: $INSTALL_BASE_DIR/"
        echo "您可以稍后手动删除: sudo rm -rf /serverboost"
    fi
    
    echo ""
    echo "卸载完成！"
    echo "感谢使用服务器环境升级与维护脚本。"
    
    # 记录卸载日志（如果日志目录还存在）
    if [ -d "$LOG_DIR" ]; then
        echo "$(date): 脚本卸载完成" >> "$LOG_DIR/install/uninstall.log" 2>/dev/null || true
    fi
    exit 0
}

# 更新脚本
update_script() {
    echo "正在更新服务器环境升级与维护脚本..."
    
    # 检查是否为root用户
    if [[ $EUID -ne 0 ]]; then
        echo "错误: 需要root权限更新脚本"
        echo "请使用: sudo serverboost --update"
        exit 1
    fi
    
    if [ ! -f "$SCRIPT_PATH" ]; then
        echo "错误: 脚本未安装"
        echo "请先安装: curl -fsSL $SCRIPT_URL | sudo bash"
        exit 1
    fi
    
    # 确保目录存在
    create_directories
    
    # 备份当前版本
    BACKUP_FILE="$BACKUP_DIR/script-backup-$(date +%Y%m%d_%H%M%S).sh"
    echo "备份当前版本: $BACKUP_FILE"
    cp "$SCRIPT_PATH" "$BACKUP_FILE"
    
    # 下载新版本
    echo "下载最新版本..."
    if command -v wget >/dev/null 2>&1; then
        wget -q -O "$SCRIPT_PATH.new" "$SCRIPT_URL"
    elif command -v curl >/dev/null 2>&1; then
        curl -fsSL -o "$SCRIPT_PATH.new" "$SCRIPT_URL"
    else
        echo "错误: 需要 wget 或 curl 下载更新"
        exit 1
    fi
    
    if [ ! -f "$SCRIPT_PATH.new" ] || [ ! -s "$SCRIPT_PATH.new" ]; then
        echo "错误: 下载更新失败"
        exit 1
    fi
    
    # 检查新版本是否有效
    if ! grep -q "服务器环境升级与维护脚本" "$SCRIPT_PATH.new"; then
        echo "错误: 下载的文件不是有效的脚本"
        rm -f "$SCRIPT_PATH.new"
        exit 1
    fi
    
    # 替换旧版本
    mv "$SCRIPT_PATH.new" "$SCRIPT_PATH"
    chmod +x "$SCRIPT_PATH"
    
    echo ""
    echo "============================================"
    echo "更新完成！"
    echo "============================================"
    echo "脚本已更新到最新版本"
    echo "旧版本已备份到: $BACKUP_FILE"
    echo ""
    echo "现在您可以运行: sudo serverboost"
    echo "============================================"
    
    # 记录更新日志
    echo "$(date): 脚本更新完成，备份: $BACKUP_FILE" >> "$LOG_DIR/install/update.log"
    exit 0
}

# ============================================
# 第二部分：参数处理
# ============================================

# 检查参数
case "$1" in
    --install|-i)
        install_script
        ;;
    --uninstall|-u)
        uninstall_script
        ;;
    --update|-U)
        update_script
        ;;
    --info|-I)
        show_info
        ;;
    --help|-h)
        show_help
        ;;
    --auto|-a)
        RUN_MODE="auto"
        ;;
    --custom|-c)
        RUN_MODE="custom"
        ;;
    "")
        # 无参数，默认交互模式
        RUN_MODE="interactive"
        ;;
    *)
        echo "错误: 未知参数 '$1'"
        echo "使用 --help 查看帮助"
        exit 1
        ;;
esac

# ============================================
# 第三部分：管道执行检测
# ============================================

# 检测是否通过管道执行
if [ -t 0 ]; then
    # 从终端执行（交互模式）
    if [ -z "$RUN_MODE" ]; then
        RUN_MODE="interactive"
    fi
    
    # 检查是否已安装
    if [ "$0" = "bash" ] || [ "$0" = "/bin/bash" ]; then
        # 通过管道执行，直接安装
        install_script
    fi
else
    # 通过管道执行（如 wget -O - URL | sudo bash）
    # 直接安装
    install_script
fi

# ============================================
# 第四部分：主脚本功能（安装后才执行）
# ============================================

# 加载配置文件（如果存在）
if [ -f "$CONFIG_DIR/config.sh" ]; then
    source "$CONFIG_DIR/config.sh"
fi

# 配置默认值
KEEP_OLD_KERNELS=${KEEP_OLD_KERNELS:-2}
PYTHON_VERSION=${PYTHON_VERSION:-"3.11"}
NODE_VERSION=${NODE_VERSION:-"20"}
PHP_VERSION=${PHP_VERSION:-"8.2"}
SERVICES_TO_RESTART=("nginx" "apache2" "mysql" "postgresql" "redis-server" "docker")

# ============================================
# 显示主菜单
# ============================================

show_main_menu() {
    clear
    echo "============================================"
    echo "    服务器环境升级与维护脚本"
    echo "    版本: $SCRIPT_VERSION"
    echo "============================================"
    echo ""
    echo "请选择操作："
    echo ""
    echo "1. 全自动模式 - 快速升级所有组件"
    echo "2. 自定义模式 - 选择要升级的组件"
    echo "3. 查看当前系统信息"
    echo "4. 查看脚本说明"
    echo "5. 更新脚本到最新版本"
    echo "6. 卸载脚本"
    echo "7. 退出脚本"
    echo ""
    echo "============================================"
}

# ============================================
# 全自动模式
# ============================================

auto_mode() {
    UPGRADE_OS=${AUTO_UPGRADE_OS:-"yes"}
    UPGRADE_KERNEL=${AUTO_UPGRADE_KERNEL:-"yes"}
    UPGRADE_DOCKER=${AUTO_UPGRADE_DOCKER:-"yes"}
    UPGRADE_PODMAN=${AUTO_UPGRADE_PODMAN:-"yes"}
    UPGRADE_PYTHON=${AUTO_UPGRADE_PYTHON:-"yes"}
    UPGRADE_NODEJS=${AUTO_UPGRADE_NODEJS:-"yes"}
    UPGRADE_PHP=${AUTO_UPGRADE_PHP:-"yes"}
    
    echo "已选择全自动模式，将升级所有组件。"
    echo "升级列表：操作系统、内核、Docker、Podman、Python、Node.js、PHP"
    echo ""
    
    # 确认执行
    read -p "确认开始全自动升级？(y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "操作已取消"
        return 1
    fi
    
    show_warning
    execute_upgrade
}

# ============================================
# 自定义模式 - 选择组件
# ============================================

custom_mode() {
    clear
    echo "============================================"
    echo "    自定义升级模式 - 选择要升级的组件"
    echo "============================================"
    echo ""
    echo "请选择要升级的组件（输入 y/n 或直接回车选择默认值）:"
    echo ""
    
    # 默认值
    UPGRADE_OS="yes"
    UPGRADE_KERNEL="yes"
    UPGRADE_DOCKER="yes"
    UPGRADE_PODMAN="yes"
    UPGRADE_PYTHON="yes"
    UPGRADE_NODEJS="yes"
    UPGRADE_PHP="yes"
    
    # 操作系统升级
    read -p "1. 升级操作系统和软件包? [Y/n] " choice
    if [[ "$choice" =~ ^[Nn]$ ]]; then
        UPGRADE_OS="no"
    fi
    
    # 内核管理
    read -p "2. 升级和管理内核（清理旧内核）? [Y/n] " choice
    if [[ "$choice" =~ ^[Nn]$ ]]; then
        UPGRADE_KERNEL="no"
    fi
    
    # Docker升级
    read -p "3. 升级Docker和Docker Compose? [Y/n] " choice
    if [[ "$choice" =~ ^[Nn]$ ]]; then
        UPGRADE_DOCKER="no"
    fi
    
    # Podman升级
    read -p "4. 升级Podman? [Y/n] " choice
    if [[ "$choice" =~ ^[Nn]$ ]]; then
        UPGRADE_PODMAN="no"
    fi
    
    # Python升级
    read -p "5. 升级Python到 $PYTHON_VERSION? [Y/n] " choice
    if [[ "$choice" =~ ^[Nn]$ ]]; then
        UPGRADE_PYTHON="no"
    fi
    
    # Node.js升级
    read -p "6. 升级Node.js到 $NODE_VERSION? [Y/n] " choice
    if [[ "$choice" =~ ^[Nn]$ ]]; then
        UPGRADE_NODEJS="no"
    fi
    
    # PHP升级
    read -p "7. 升级PHP到 $PHP_VERSION? [Y/n] " choice
    if [[ "$choice" =~ ^[Nn]$ ]]; then
        UPGRADE_PHP="no"
    fi
    
    echo ""
    echo "============================================"
    echo "您选择的配置:"
    echo "  操作系统升级: $UPGRADE_OS"
    echo "  内核管理: $UPGRADE_KERNEL"
    echo "  Docker升级: $UPGRADE_DOCKER"
    echo "  Podman升级: $UPGRADE_PODMAN"
    echo "  Python升级: $UPGRADE_PYTHON"
    echo "  Node.js升级: $UPGRADE_NODEJS"
    echo "  PHP升级: $UPGRADE_PHP"
    echo "============================================"
    echo ""
    
    read -p "确认开始升级? (y/n): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo "操作已取消"
        return 1
    fi
    
    show_warning
    execute_upgrade
}

# ============================================
# 显示系统信息
# ============================================

show_system_info() {
    clear
    echo "============================================"
    echo "        当前系统信息"
    echo "============================================"
    echo ""
    
    echo "操作系统信息:"
    echo "- 主机名: $(hostname)"
    echo "- 系统版本: $(cat /etc/os-release 2>/dev/null | grep PRETTY_NAME | cut -d= -f2 | tr -d '"' || echo '未知')"
    echo "- 内核版本: $(uname -r)"
    echo "- 系统架构: $(uname -m)"
    echo ""
    
    echo "系统负载:"
    uptime
    echo ""
    
    echo "内存使用:"
    free -h
    echo ""
    
    echo "磁盘使用情况:"
    df -h / | tail -1
    echo ""
    
    echo "已安装的服务:"
    for service in "${SERVICES_TO_RESTART[@]}"; do
        if systemctl list-unit-files | grep -q "$service.service" 2>/dev/null; then
            echo "- $service: 已安装"
        else
            echo "- $service: 未安装"
        fi
    done
    echo ""
    
    read -p "按回车键返回主菜单..."
}

# ============================================
# 显示脚本说明
# ============================================

show_script_info() {
    clear
    echo "============================================"
    echo "        脚本使用说明"
    echo "============================================"
    echo ""
    echo "脚本功能:"
    echo "✓ 升级操作系统和软件包"
    echo "✓ 升级和管理内核（清理旧内核）"
    echo "✓ 升级容器环境（Docker/Docker Compose）"
    echo "✓ 升级Podman（如果已安装）"
    echo "✓ 升级Python到 $PYTHON_VERSION"
    echo "✓ 升级Node.js到 $NODE_VERSION"
    echo "✓ 升级PHP到 $PHP_VERSION"
    echo "✓ 重启相关系统服务"
    echo "✓ 执行清理工作"
    echo ""
    echo "安装后使用: sudo serverboost"
    echo ""
    read -p "按回车键返回主菜单..."
}

# ============================================
# 警告和确认函数
# ============================================

show_warning() {
    clear
    echo "============================================"
    echo "            !!! 重要警告 !!!"
    echo "============================================"
    echo ""
    echo "您即将执行系统升级脚本，这会修改您的系统配置。"
    echo ""
    echo "脚本将执行以下操作："
    [ "$UPGRADE_OS" = "yes" ] && echo "✓ 升级操作系统和软件包"
    [ "$UPGRADE_KERNEL" = "yes" ] && echo "✓ 升级和管理内核（清理旧内核）"
    [ "$UPGRADE_DOCKER" = "yes" ] && echo "✓ 升级容器环境（Docker/Docker Compose）"
    [ "$UPGRADE_PODMAN" = "yes" ] && echo "✓ 升级Podman（如果已安装）"
    [ "$UPGRADE_PYTHON" = "yes" ] && echo "✓ 升级Python到 $PYTHON_VERSION"
    [ "$UPGRADE_NODEJS" = "yes" ] && echo "✓ 升级Node.js到 $NODE_VERSION"
    [ "$UPGRADE_PHP" = "yes" ] && echo "✓ 升级PHP到 $PHP_VERSION"
    echo "✓ 重启相关系统服务"
    echo "✓ 执行清理工作"
    echo ""
    
    echo "如果您不想继续，请在5秒内按 Ctrl+C 取消！"
    echo ""
    echo "============================================"
    echo "5秒后开始执行..."
    echo ""
    
    # 5秒倒计时
    for i in {5..1}; do
        echo -ne "倒计时: ${i}秒... 按 Ctrl+C 取消执行\r"
        sleep 1
    done
    echo -ne "开始执行脚本                                      \n"
    echo ""
}

# ============================================
# 初始化函数
# ============================================

init() {
    # 检查是否为root用户
    if [[ $EUID -ne 0 ]]; then
        echo "错误: 此脚本需要root权限运行"
        exit 1
    fi
    
    # 创建本次升级的备份目录
    UPGRADE_BACKUP_DIR="$BACKUP_DIR/system-upgrade-$(date +%Y%m%d_%H%M%S)"
    UPGRADE_LOG_FILE="$LOG_DIR/upgrade/system-upgrade-$(date +%Y%m%d_%H%M%S).log"
    
    mkdir -p "$UPGRADE_BACKUP_DIR"
    touch "$UPGRADE_LOG_FILE"
}

# ============================================
# 备份函数
# ============================================

backup_system() {
    echo "开始系统备份..."
    
    # 备份关键配置文件
    cp -r /etc/nginx "$UPGRADE_BACKUP_DIR/etc-nginx" 2>/dev/null || true
    cp -r /etc/apache2 "$UPGRADE_BACKUP_DIR/etc-apache2" 2>/dev/null || true
    cp -r /etc/mysql "$UPGRADE_BACKUP_DIR/etc-mysql" 2>/dev/null || true
    cp /etc/hosts "$UPGRADE_BACKUP_DIR/hosts" 2>/dev/null || true
    
    # 备份当前包列表
    if command -v apt &> /dev/null; then
        dpkg --get-selections > "$UPGRADE_BACKUP_DIR/package-list.txt"
    elif command -v yum &> /dev/null; then
        rpm -qa > "$UPGRADE_BACKUP_DIR/package-list.txt"
    fi
    
    echo "备份完成，保存到: $UPGRADE_BACKUP_DIR"
}

# ============================================
# 操作系统升级函数
# ============================================

upgrade_os() {
    if [ "$UPGRADE_OS" != "yes" ]; then
        echo "跳过操作系统升级（用户选择）"
        return
    fi
    
    echo "开始操作系统升级..."
    
    if [ -f /etc/debian_version ]; then
        upgrade_debian
    elif [ -f /etc/redhat-release ] || [ -f /etc/centos-release ]; then
        upgrade_centos
    elif [ -f /etc/alpine-release ]; then
        upgrade_alpine
    else
        echo "警告: 未知的Linux发行版"
    fi
    
    echo "操作系统升级完成"
}

upgrade_debian() {
    echo "检测到Debian/Ubuntu系统，开始升级..."
    
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y
    DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y
    apt-get autoremove -y
    apt-get autoclean
}

upgrade_centos() {
    echo "检测到CentOS/RHEL系统，开始升级..."
    
    yum update -y
    yum clean all
}

upgrade_alpine() {
    echo "检测到Alpine Linux系统，开始升级..."
    
    apk update
    apk upgrade
}

# ============================================
# 内核管理函数
# ============================================

manage_kernels() {
    if [ "$UPGRADE_KERNEL" != "yes" ]; then
        echo "跳过内核管理（用户选择）"
        return
    fi
    
    echo "开始内核管理..."
    
    if [ -f /etc/debian_version ]; then
        echo "清理旧内核（保留最新的 $KEEP_OLD_KERNELS 个）..."
        apt-get autoremove --purge -y
    elif [ -f /etc/redhat-release ]; then
        if command -v package-cleanup &> /dev/null; then
            package-cleanup --oldkernels --count=$KEEP_OLD_KERNELS -y
        fi
    fi
    
    echo "内核管理完成"
}

# ============================================
# 容器环境升级函数
# ============================================

upgrade_docker() {
    if [ "$UPGRADE_DOCKER" != "yes" ]; then
        echo "跳过Docker升级（用户选择）"
        return
    fi
    
    if ! command -v docker &> /dev/null; then
        echo "Docker未安装，跳过升级"
        return
    fi
    
    echo "开始Docker升级..."
    
    docker stop $(docker ps -q) 2>/dev/null || true
    
    if [ -f /etc/debian_version ]; then
        apt-get install --only-upgrade docker.io -y
    elif [ -f /etc/redhat-release ]; then
        yum update docker -y
    fi
    
    systemctl start docker 2>/dev/null || true
    docker start $(docker ps -aq) 2>/dev/null || true
    
    echo "Docker升级完成"
}

upgrade_podman() {
    if [ "$UPGRADE_PODMAN" != "yes" ]; then
        echo "跳过Podman升级（用户选择）"
        return
    fi
    
    if ! command -v podman &> /dev/null; then
        echo "Podman未安装，跳过升级"
        return
    fi
    
    echo "开始Podman升级..."
    
    if [ -f /etc/debian_version ]; then
        apt-get install --only-upgrade podman -y
    elif [ -f /etc/redhat-release ]; then
        yum update podman -y
    fi
    
    echo "Podman升级完成"
}

# ============================================
# 编程语言环境升级函数
# ============================================

upgrade_python() {
    if [ "$UPGRADE_PYTHON" != "yes" ]; then
        echo "跳过Python升级（用户选择）"
        return
    fi
    
    echo "开始Python环境升级..."
    
    if [ -f /etc/debian_version ]; then
        apt-get install python$PYTHON_VERSION python$PYTHON_VERSION-venv python$PYTHON_VERSION-dev -y
    elif [ -f /etc/redhat-release ]; then
        yum install python$PYTHON_VERSION -y
    fi
    
    python3 -m pip install --upgrade pip setuptools wheel
    
    echo "Python升级完成"
}

upgrade_nodejs() {
    if [ "$UPGRADE_NODEJS" != "yes" ]; then
        echo "跳过Node.js升级（用户选择）"
        return
    fi
    
    echo "开始Node.js环境升级..."
    
    if command -v n &> /dev/null; then
        n $NODE_VERSION
    else
        curl -L https://raw.githubusercontent.com/tj/n/master/bin/n -o /tmp/n 2>/dev/null || true
        if [ -f "/tmp/n" ]; then
            bash /tmp/n $NODE_VERSION
            rm /tmp/n
        fi
    fi
    
    npm install -g npm
    
    echo "Node.js升级完成"
}

upgrade_php() {
    if [ "$UPGRADE_PHP" != "yes" ]; then
        echo "跳过PHP升级（用户选择）"
        return
    fi
    
    echo "开始PHP环境升级..."
    
    if [ -f /etc/debian_version ]; then
        apt-get install software-properties-common -y
        add-apt-repository ppa:ondrej/php -y
        apt-get update
        apt-get install php$PHP_VERSION php$PHP_VERSION-fpm php$PHP_VERSION-cli \
            php$PHP_VERSION-mysql php$PHP_VERSION-curl php$PHP_VERSION-gd \
            php$PHP_VERSION-mbstring php$PHP_VERSION-xml php$PHP_VERSION-zip -y
    elif [ -f /etc/redhat-release ]; then
        yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm
        yum-config-manager --enable remi-php$PHP_VERSION
        yum update php -y
    fi
    
    echo "PHP升级完成"
}

# ============================================
# 服务重启函数
# ============================================

restart_services() {
    echo "开始重启服务..."
    
    for service in "${SERVICES_TO_RESTART[@]}"; do
        if systemctl list-unit-files | grep -q "$service.service" 2>/dev/null; then
            echo "重启服务: $service"
            systemctl restart "$service" 2>/dev/null || true
        fi
    done
    
    echo "服务重启完成"
}

# ============================================
# 清理函数
# ============================================

cleanup() {
    echo "开始清理..."
    
    if [ -f /etc/debian_version ]; then
        apt-get clean
    elif [ -f /etc/redhat-release ]; then
        yum clean all
    fi
    
    rm -rf /tmp/* 2>/dev/null || true
    rm -rf /var/tmp/* 2>/dev/null || true
    
    echo "清理完成"
}

# ============================================
# 报告函数
# ============================================

generate_report() {
    clear
    echo "============================================"
    echo "          升级完成报告"
    echo "============================================"
    echo ""
    echo "✅系统升级已成功完成！"
    echo ""
    echo " 升级摘要:"
    echo "- 备份文件: $UPGRADE_BACKUP_DIR"
    echo "- 升级时间: $(date)"
    echo ""
    echo " 已执行的升级:"
    [ "$UPGRADE_OS" = "yes" ] && echo "✓ 操作系统升级"
    [ "$UPGRADE_KERNEL" = "yes" ] && echo "✓ 内核管理"
    [ "$UPGRADE_DOCKER" = "yes" ] && echo "✓ Docker升级"
    [ "$UPGRADE_PODMAN" = "yes" ] && echo "✓ Podman升级"
    [ "$UPGRADE_PYTHON" = "yes" ] && echo "✓ Python升级"
    [ "$UPGRADE_NODEJS" = "yes" ] && echo "✓ Node.js升级"
    [ "$UPGRADE_PHP" = "yes" ] && echo "✓ PHP升级"
    echo "✓ 服务重启"
    echo "✓ 系统清理"
    echo ""
    echo " 建议:"
    echo "1. 检查关键服务是否正常运行"
    echo "2. 验证应用程序功能"
    echo "3. 查看备份文件是否完整"
    echo ""
    echo " 下次使用: sudo serverboost"
    echo "============================================"
    
    read -p "按回车键返回主菜单..."
}

# ============================================
# 执行升级流程
# ============================================

execute_upgrade() {
    init
    backup_system
    
    # 根据用户选择执行相应的升级步骤
    upgrade_os
    manage_kernels
    upgrade_docker
    upgrade_podman
    upgrade_python
    upgrade_nodejs
    upgrade_php
    
    # 后续步骤
    restart_services
    cleanup
    generate_report
}

# ============================================
# 主函数
# ============================================

main() {
    # 检查是否为root用户
    if [[ $EUID -ne 0 ]]; then
        echo "错误: 此脚本需要root权限运行"
        echo "请使用: sudo serverboost"
        exit 1
    fi
    
    # 确保目录存在
    create_directories
    
    # 主菜单循环
    while true; do
        show_main_menu
        
        read -p "请选择操作 (1-7): " choice
        
        case $choice in
            1)
                auto_mode
                ;;
            2)
                custom_mode
                ;;
            3)
                show_system_info
                ;;
            4)
                show_script_info
                ;;
            5)
                # 更新脚本
                update_script
                ;;
            6)
                # 卸载脚本
                uninstall_script
                ;;
            7)
                clear
                echo "感谢使用服务器环境升级与维护脚本，再见！"
                echo ""
                exit 0
                ;;
            *)
                echo "无效选择，请重新输入！"
                sleep 2
                ;;
        esac
    done
}

# ============================================
# 脚本入口
# ============================================

# 如果脚本是通过安装的，直接进入主函数
if [ -f "$SCRIPT_PATH" ] && [ "$0" = "$SCRIPT_PATH" ]; then
    # 已安装的脚本，直接进入主函数
    if [ "$RUN_MODE" = "auto" ]; then
        auto_mode
    elif [ "$RUN_MODE" = "custom" ]; then
        custom_mode
    else
        main
    fi
else
    # 未安装的脚本，直接安装
    install_script
fi
