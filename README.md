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
bash <(curl -sSL https://shell.umrc.cn/scripts/serverboost.sh || wget -q https://shell.umrc.cn/scripts/serverboost.sh -O -)
```
>全程无需人工干预，适合快速操作。
> 
## 命令参考
启动菜单
v3.1
sudo serverboost
启动交互式菜单界面

立即执行
自动模式
v3.1
sudo serverboost --auto
全自动升级所有组件

无人值守
自定义模式
v3.1
sudo serverboost --custom
自定义选择升级组件

灵活配置
系统信息
v3.1
serverboost --info
显示系统信息和脚本状态

状态监测
更新脚本
v3.1
sudo serverboost --update
更新到最新版本

自动更新
卸载脚本
v3.1
sudo serverboost --uninstall
从系统移除脚本
安全移除

ServerBoost 一键服务器升级脚本 | 版本 2.0 | 最后更新 2024-01-15
本脚本由 balareshe 开发维护，遵循开源协议发布，仅供学习和合法用途使用。
© 2024-2026 ServerBoost 项目组. 保留所有权利.

本脚本按"原样"提供，不附带任何明示或暗示的保证。使用本脚本所产生的任何风险由用户自行承担。
在生产环境使用前，请务必在测试环境进行充分测试，并备份重要数据。
