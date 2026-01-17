# serverboost
作为经常折腾服务器的技术爱好者，手动升级系统、维护开发环境、备份数据的过程又繁琐又容易出错。为此，我自制了一款全能服务器维护脚本 `ServerBoost`，支持一键完成系统升级、环境更新、数据备份等核心操作，适配多Linux发行版，实测Ubuntu 22.04完美运行。今天把完整使用教程和脚本源码分享给大家，新手也能轻松上手～

## 🎯 脚本核心亮点
- **多系统兼容**：支持Ubuntu/Debian、CentOS/RHEL、Alpine Linux，自动识别发行版
- **功能全覆盖**：系统升级、内核管理、容器（Docker/Podman）升级、编程语言（Python/Node.js/PHP）更新、数据备份、服务重启一站式完成
- **安全可靠**：执行前自动备份关键配置和数据，全程日志记录，可追溯操作过程
- **灵活适配**：支持一键运行、手动下载执行两种方式，可自定义目标版本和备份目录
- **开源免费**：完整源码公开，可根据需求二次修改

## 🚀 三种运行方式（实测全部可用）
### 方式1：wget 一键执行（推荐）
无需手动创建文件，复制以下命令直接在服务器终端执行，自动下载+运行脚本：
```bash
wget -O - https://shell.umrc.cn/scripts/serverboost-wget.sh | sudo bash
```
> 原理：`wget -O -` 将脚本内容直接输出到终端，通过管道交给 `sudo bash` 执行，全程无需人工干预，适合快速操作。

### 方式2：curl 一键执行（备用方案）
如果服务器未安装 `wget`，使用 `curl` 命令替代，同样一键完成：
```bash
curl -fsSL https://shell.umrc.cn/scripts/serverboost-wget.sh | sudo bash
```
> 说明：`-fsSL` 参数确保静默下载、跟随重定向，避免网络波动导致的执行失败，兼容性更强。

### 方式3：手动下载执行（自定义修改/本地测试）
如果需要调整脚本配置（如修改目标版本、备份目录），或想本地测试后再执行，推荐手动下载方式：
1. **下载脚本到服务器**：
```bash
# 方式A：wget下载
wget https://shell.umrc.cn/scripts/serverboost-wget.sh

# 方式B：curl下载（无wget时用）
curl -fsSL -o serverboost-wget.sh https://shell.umrc.cn/scripts/serverboost-wget.sh
```
2. **自定义配置（可选）**：
用文本编辑器打开脚本，修改目标版本、备份目录等参数：
```bash
vim serverboost-wget.sh
```
核心可配置项（修改示例）：
```bash
# 配置区域
BACKUP_DIR="/mnt/backups/system-upgrade-$(date +%Y%m%d)"  # 自定义备份目录
LOG_FILE="/var/log/system-upgrade-$(date +%Y%m%d).log"    # 日志存储路径
EMAIL_NOTIFY="your-email@example.com"  # 接收通知的邮箱

KEEP_OLD_KERNELS=2  # 保留旧内核数量

PYTHON_VERSION="3.12"  # 目标Python版本
NODE_VERSION="21"      # 目标Node.js版本
PHP_VERSION="8.3"      # 目标PHP版本

SERVICES_TO_RESTART=("nginx" "apache2" "mysql" "redis-server" "docker")  # 需要重启的服务
```
3. **赋予执行权限**：
```bash
chmod +x serverboost-wget.sh
```
4. **以root权限运行**：
```bash
sudo ./serverboost-wget.sh
```

ServerBoost 一键服务器升级脚本 | 版本 2.0 | 最后更新 2024-01-15
本脚本由 balareshe 开发维护，遵循开源协议发布，仅供学习和合法用途使用。
© 2024-2026 ServerBoost 项目组. 保留所有权利.

本脚本按"原样"提供，不附带任何明示或暗示的保证。使用本脚本所产生的任何风险由用户自行承担。
在生产环境使用前，请务必在测试环境进行充分测试，并备份重要数据。
