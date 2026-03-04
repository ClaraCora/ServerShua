#!/bin/bash
# install.sh

# 确保以 root 权限运行
if [ "$EUID" -ne 0 ]; then
  echo -e "\e[31m[错误] 请使用 root 权限运行此脚本 (例如: sudo bash install.sh)\e[0m"
  exit 1
fi

echo "开始安装 Shua 流量消耗工具..."

# 1. 创建程序主目录
mkdir -p /opt/shua

# 2. 复制核心文件到主目录 (假设当前在项目源码目录下运行)
cp worker.sh /opt/shua/
cp shua.sh /opt/shua/
# 如果 config.conf 不存在则创建一个空的
cp config.conf /opt/shua/ 2>/dev/null || touch /opt/shua/config.conf

# 3. 赋予执行权限
chmod +x /opt/shua/worker.sh
chmod +x /opt/shua/shua.sh

# 4. 创建快捷命令软链接，实现全局呼出
ln -sf /opt/shua/shua.sh /usr/local/bin/shua

# 5. 配置并启动 Systemd 服务
cp shua.service /etc/systemd/system/
systemctl daemon-reload
# 默认暂不启动服务，等用户在面板配置好链接后再启动
systemctl enable shua.service >/dev/null 2>&1

echo -e "\e[32m[成功] Shua 安装完成！\e[0m"
echo -e "请在终端任意位置输入 \e[33mshua\e[0m 来呼出管理面板并进行配置。"
