# 1. 停止并禁用后台服务
systemctl stop shua.service
systemctl disable shua.service

# 2. 删除 Systemd 配置文件并重载守护进程
rm -f /etc/systemd/system/shua.service
systemctl daemon-reload

# 3. 删除全局的快捷呼出软链接
rm -f /usr/local/bin/shua

# 4. 删除项目主目录（包含所有脚本、配置和统计日志）
rm -rf /opt/shua

echo -e "\e[32m[成功] Shua 已彻底卸载并清理完毕！\e[0m"
