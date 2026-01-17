#!/bin/bash

# ============================================
# 服务器环境升级与维护脚本 - 一键安装版本
# 功能：升级操作系统、容器环境、编程语言和常用服务
# 版本：2.1
# 最后更新：2024-01-15
# 一键安装命令：
# wget -O - https://example.com/scripts/system-upgrade.sh | sudo bash
# 或
# curl -fsSL https://example.com/scripts/system-upgrade.sh | sudo bash
# ============================================

# 配置区域
BACKUP_DIR="/var/backups/system-upgrade-$(date +%Y%m%d)"
LOG_FILE="/var/log/system-upgrade-$(date +%Y%m%d).log"
EMAIL_NOTIFY="admin@example.com"  # 设置接收通知的邮箱

# 需要保留的旧内核数量
KEEP_OLD_KERNELS=2

# 需要升级的编程语言版本
PYTHON_VERSION="3.11"  # 指定目标Python版本
NODE_VERSION="20"      # 指定目标Node.js版本
PHP_VERSION="8.2"      # 指定目标PHP版本

# 需要重启的服务列表
SERVICES_TO_RESTART=("nginx" "apache2" "mysql" "postgresql" "redis-server" "docker")

# ============================================
# 初始化函数
# ============================================

init() {
    echo "============================================"
    echo "服务器环境升级与维护脚本"
    echo "开始时间: $(date)"
    echo "============================================"
    
    # 检查是否为root用户
    if [[ $EUID -ne 0 ]]; then
        echo "错误: 此脚本需要root权限运行" | tee -a "$LOG_FILE"
        exit 1
    fi
    
    # 显示安全警告
    echo "安全提示: 此脚本将从远程下载并立即执行"
    echo "如果您尚未验证脚本内容，请按 Ctrl+C 退出"
    echo "5秒后继续执行..."
    sleep 5
    
    # 创建备份目录
    mkdir -p "$BACKUP_DIR"
    
    # 创建日志文件
    touch "$LOG_FILE"
    
    # 记录系统信息
    echo "系统信息:" | tee -a "$LOG_FILE"
    echo "- 主机名: $(hostname)" | tee -a "$LOG_FILE"
    echo "- 系统版本: $(cat /etc/os-release | grep PRETTY_NAME | cut -d= -f2)" | tee -a "$LOG_FILE"
    echo "- 内核版本: $(uname -r)" | tee -a "$LOG_FILE"
    echo "- 开始时间: $(date)" | tee -a "$LOG_FILE"
    echo "============================================" | tee -a "$LOG_FILE"
}

# ============================================
# 备份函数
# ============================================

backup_system() {
    echo "开始系统备份..." | tee -a "$LOG_FILE"
    
    # 备份关键配置文件
    echo "备份配置文件..." | tee -a "$LOG_FILE"
    cp -r /etc/nginx "$BACKUP_DIR/etc-nginx" 2>/dev/null || true
    cp -r /etc/apache2 "$BACKUP_DIR/etc-apache2" 2>/dev/null || true
    cp -r /etc/mysql "$BACKUP_DIR/etc-mysql" 2>/dev/null || true
    cp -r /etc/postgresql "$BACKUP_DIR/etc-postgresql" 2>/dev/null || true
    cp /etc/hosts "$BACKUP_DIR/hosts" 2>/dev/null || true
    cp /etc/resolv.conf "$BACKUP_DIR/resolv.conf" 2>/dev/null || true
    
    # 备份当前包列表
    echo "备份包列表..." | tee -a "$LOG_FILE"
    if command -v apt &> /dev/null; then
        dpkg --get-selections > "$BACKUP_DIR/package-list.txt"
    elif command -v yum &> /dev/null; then
        rpm -qa > "$BACKUP_DIR/package-list.txt"
    fi
    
    # 备份重要数据目录
    echo "备份重要数据..." | tee -a "$LOG_FILE"
    tar -czf "$BACKUP_DIR/var-www.tar.gz" /var/www 2>/dev/null || true
    tar -czf "$BACKUP_DIR/opt-apps.tar.gz" /opt 2>/dev/null || true
    
    echo "备份完成，保存到: $BACKUP_DIR" | tee -a "$LOG_FILE"
}

# ============================================
# 操作系统升级函数
# ============================================

upgrade_os() {
    echo "开始操作系统升级..." | tee -a "$LOG_FILE"
    
    # 检测发行版
    if [ -f /etc/debian_version ]; then
        upgrade_debian
    elif [ -f /etc/redhat-release ] || [ -f /etc/centos-release ]; then
        upgrade_centos
    elif [ -f /etc/alpine-release ]; then
        upgrade_alpine
    else
        echo "警告: 未知的Linux发行版" | tee -a "$LOG_FILE"
    fi
    
    echo "操作系统升级完成" | tee -a "$LOG_FILE"
}

upgrade_debian() {
    echo "检测到Debian/Ubuntu系统，开始升级..." | tee -a "$LOG_FILE"
    
    # 更新包列表
    apt-get update | tee -a "$LOG_FILE"
    
    # 升级现有包
    DEBIAN_FRONTEND=noninteractive apt-get upgrade -y | tee -a "$LOG_FILE"
    
    # 执行发行版升级（如果可用）
    if [ -f /usr/bin/do-release-upgrade ]; then
        echo "执行发行版升级..." | tee -a "$LOG_FILE"
        # 使用非交互模式，根据需要调整
        # do-release-upgrade -f DistUpgradeViewNonInteractive
    else
        DEBIAN_FRONTEND=noninteractive apt-get dist-upgrade -y | tee -a "$LOG_FILE"
    fi
    
    # 清理旧包
    apt-get autoremove -y | tee -a "$LOG_FILE"
    apt-get autoclean | tee -a "$LOG_FILE"
}

upgrade_centos() {
    echo "检测到CentOS/RHEL系统，开始升级..." | tee -a "$LOG_FILE"
    
    # 更新所有包
    yum update -y | tee -a "$LOG_FILE"
    
    # 清理缓存
    yum clean all | tee -a "$LOG_FILE"
    
    # 升级EPEL仓库（如果已安装）
    if yum list installed epel-release &>/dev/null; then
        yum update epel-release -y | tee -a "$LOG_FILE"
    fi
}

upgrade_alpine() {
    echo "检测到Alpine Linux系统，开始升级..." | tee -a "$LOG_FILE"
    
    # 更新包索引并升级
    apk update | tee -a "$LOG_FILE"
    apk upgrade | tee -a "$LOG_FILE"
}

# ============================================
# 内核管理函数
# ============================================

manage_kernels() {
    echo "开始内核管理..." | tee -a "$LOG_FILE"
    
    if [ -f /etc/debian_version ]; then
        # Debian/Ubuntu内核管理
        echo "当前内核版本: $(uname -r)" | tee -a "$LOG_FILE"
        
        # 列出所有已安装的内核
        echo "已安装的内核:" | tee -a "$LOG_FILE"
        dpkg --list | grep linux-image | tee -a "$LOG_FILE"
        
        # 自动移除旧内核，保留指定数量
        apt-get autoremove --purge -y | tee -a "$LOG_FILE"
        
    elif [ -f /etc/redhat-release ]; then
        # CentOS/RHEL内核管理
        echo "当前内核版本: $(uname -r)" | tee -a "$LOG_FILE"
        
        # 列出所有已安装的内核
        echo "已安装的内核:" | tee -a "$LOG_FILE"
        rpm -q kernel | tee -a "$LOG_FILE"
        
        # 保留最新内核和指定数量的旧内核
        package-cleanup --oldkernels --count=$KEEP_OLD_KERNELS -y | tee -a "$LOG_FILE"
    fi
    
    echo "内核管理完成" | tee -a "$LOG_FILE"
}

# ============================================
# 容器环境升级函数
# ============================================

upgrade_docker() {
    if ! command -v docker &> /dev/null; then
        echo "Docker未安装，跳过升级" | tee -a "$LOG_FILE"
        return
    fi
    
    echo "开始Docker升级..." | tee -a "$LOG_FILE"
    
    # 停止所有运行的容器
    echo "停止运行中的容器..." | tee -a "$LOG_FILE"
    docker stop $(docker ps -q) 2>/dev/null || true
    
    # 备份Docker数据
    echo "备份Docker数据..." | tee -a "$LOG_FILE"
    tar -czf "$BACKUP_DIR/docker-data.tar.gz" /var/lib/docker 2>/dev/null || true
    
    # 升级Docker（根据不同发行版）
    if [ -f /etc/debian_version ]; then
        apt-get install --only-upgrade docker.io -y | tee -a "$LOG_FILE"
    elif [ -f /etc/redhat-release ]; then
        yum update docker -y | tee -a "$LOG_FILE"
    fi
    
    # 升级Docker Compose
    if command -v docker-compose &> /dev/null; then
        echo "升级Docker Compose..." | tee -a "$LOG_FILE"
        curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
        chmod +x /usr/local/bin/docker-compose
    fi
    
    # 启动Docker服务
    systemctl start docker
    
    # 启动之前停止的容器
    echo "重新启动容器..." | tee -a "$LOG_FILE"
    docker start $(docker ps -aq) 2>/dev/null || true
    
    echo "Docker升级完成，当前版本: $(docker --version)" | tee -a "$LOG_FILE"
}

upgrade_podman() {
    if ! command -v podman &> /dev/null; then
        echo "Podman未安装，跳过升级" | tee -a "$LOG_FILE"
        return
    fi
    
    echo "开始Podman升级..." | tee -a "$LOG_FILE"
    
    if [ -f /etc/debian_version ]; then
        apt-get install --only-upgrade podman -y | tee -a "$LOG_FILE"
    elif [ -f /etc/redhat-release ]; then
        yum update podman -y | tee -a "$LOG_FILE"
    fi
    
    echo "Podman升级完成，当前版本: $(podman --version)" | tee -a "$LOG_FILE"
}

# ============================================
# 编程语言环境升级函数
# ============================================

upgrade_python() {
    echo "开始Python环境升级..." | tee -a "$LOG_FILE"
    
    # 检查当前Python版本
    CURRENT_PYTHON=$(python3 --version 2>/dev/null || echo "未安装")
    echo "当前Python版本: $CURRENT_PYTHON" | tee -a "$LOG_FILE"
    
    # 根据发行版安装/升级Python
    if [ -f /etc/debian_version ]; then
        apt-get install python$PYTHON_VERSION python$PYTHON_VERSION-venv python$PYTHON_VERSION-dev -y | tee -a "$LOG_FILE"
    elif [ -f /etc/redhat-release ]; then
        yum install python$PYTHON_VERSION -y | tee -a "$LOG_FILE"
    fi
    
    # 升级pip
    echo "升级pip..." | tee -a "$LOG_FILE"
    python3 -m pip install --upgrade pip setuptools wheel | tee -a "$LOG_FILE"
    
    echo "Python升级完成，新版本: $(python3 --version)" | tee -a "$LOG_FILE"
}

upgrade_nodejs() {
    echo "开始Node.js环境升级..." | tee -a "$LOG_FILE"
    
    # 检查当前Node.js版本
    if command -v node &> /dev/null; then
        echo "当前Node.js版本: $(node --version)" | tee -a "$LOG_FILE"
    else
        echo "Node.js未安装" | tee -a "$LOG_FILE"
    fi
    
    # 使用Node版本管理器n升级
    if command -v n &> /dev/null; then
        echo "使用n升级Node.js到版本 $NODE_VERSION..." | tee -a "$LOG_FILE"
        n $NODE_VERSION | tee -a "$LOG_FILE"
    else
        echo "安装n(Node版本管理器)..." | tee -a "$LOG_FILE"
        curl -L https://raw.githubusercontent.com/tj/n/master/bin/n -o /tmp/n
        bash /tmp/n $NODE_VERSION
        rm /tmp/n
        
        # 安装npm
        if ! command -v npm &> /dev/null; then
            apt-get install npm -y 2>/dev/null || yum install npm -y 2>/dev/null || true
        fi
    fi
    
    # 升级npm
    echo "升级npm..." | tee -a "$LOG_FILE"
    npm install -g npm | tee -a "$LOG_FILE"
    
    echo "Node.js升级完成，新版本: $(node --version)" | tee -a "$LOG_FILE"
}

upgrade_php() {
    echo "开始PHP环境升级..." | tee -a "$LOG_FILE"
    
    # 检查当前PHP版本
    if command -v php &> /dev/null; then
        echo "当前PHP版本: $(php --version | head -1)" | tee -a "$LOG_FILE"
    else
        echo "PHP未安装" | tee -a "$LOG_FILE"
    fi
    
    # 根据发行版升级PHP
    if [ -f /etc/debian_version ]; then
        # 添加PHP仓库（对于旧版Debian/Ubuntu）
        apt-get install software-properties-common -y | tee -a "$LOG_FILE"
        add-apt-repository ppa:ondrej/php -y | tee -a "$LOG_FILE"
        apt-get update | tee -a "$LOG_FILE"
        
        # 安装新版本PHP
        apt-get install php$PHP_VERSION php$PHP_VERSION-fpm php$PHP_VERSION-cli \
            php$PHP_VERSION-mysql php$PHP_VERSION-curl php$PHP_VERSION-gd \
            php$PHP_VERSION-mbstring php$PHP_VERSION-xml php$PHP_VERSION-zip -y | tee -a "$LOG_FILE"
            
    elif [ -f /etc/redhat-release ]; then
        # CentOS/RHEL PHP升级
        yum install -y https://rpms.remirepo.net/enterprise/remi-release-7.rpm | tee -a "$LOG_FILE"
        yum-config-manager --enable remi-php$PHP_VERSION | tee -a "$LOG_FILE"
        yum update php -y | tee -a "$LOG_FILE"
    fi
    
    echo "PHP升级完成，新版本: $(php --version | head -1)" | tee -a "$LOG_FILE"
}

# ============================================
# 服务重启函数
# ============================================

restart_services() {
    echo "开始重启服务..." | tee -a "$LOG_FILE"
    
    for service in "${SERVICES_TO_RESTART[@]}"; do
        if systemctl list-unit-files | grep -q "$service.service"; then
            echo "重启服务: $service" | tee -a "$LOG_FILE"
            systemctl restart "$service" 2>/dev/null || true
        fi
    done
    
    echo "服务重启完成" | tee -a "$LOG_FILE"
}

# ============================================
# 清理函数
# ============================================

cleanup() {
    echo "开始清理..." | tee -a "$LOG_FILE"
    
    # 清理包缓存
    if [ -f /etc/debian_version ]; then
        apt-get clean | tee -a "$LOG_FILE"
    elif [ -f /etc/redhat-release ]; then
        yum clean all | tee -a "$LOG_FILE"
    fi
    
    # 清理临时文件
    rm -rf /tmp/* 2>/dev/null || true
    rm -rf /var/tmp/* 2>/dev/null || true
    
    echo "清理完成" | tee -a "$LOG_FILE"
}

# ============================================
# 报告函数
# ============================================

generate_report() {
    echo "============================================" | tee -a "$LOG_FILE"
    echo "升级报告" | tee -a "$LOG_FILE"
    echo "完成时间: $(date)" | tee -a "$LOG_FILE"
    echo "============================================" | tee -a "$LOG_FILE"
    
    # 系统信息
    echo "系统信息:" | tee -a "$LOG_FILE"
    echo "- 内核版本: $(uname -r)" | tee -a "$LOG_FILE"
    echo "- 系统负载: $(uptime)" | tee -a "$LOG_FILE"
    
    # 服务状态
    echo "服务状态:" | tee -a "$LOG_FILE"
    for service in "${SERVICES_TO_RESTART[@]}"; do
        if systemctl list-unit-files | grep -q "$service.service"; then
            status=$(systemctl is-active "$service" 2>/dev/null || echo "unknown")
            echo "- $service: $status" | tee -a "$LOG_FILE"
        fi
    done
    
    # 磁盘空间
    echo "磁盘使用情况:" | tee -a "$LOG_FILE"
    df -h / | tail -1 | tee -a "$LOG_FILE"
    
    echo "升级完成！详细日志请查看: $LOG_FILE" | tee -a "$LOG_FILE"
    echo "备份文件保存在: $BACKUP_DIR" | tee -a "$LOG_FILE"
}

# ============================================
# 主执行流程
# ============================================

main() {
    init
    backup_system
    upgrade_os
    manage_kernels
    upgrade_docker
    upgrade_podman
    upgrade_python
    upgrade_nodejs
    upgrade_php
    restart_services
    cleanup
    generate_report
}

# 执行主函数
main