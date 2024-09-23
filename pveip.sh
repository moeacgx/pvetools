#!/bin/bash

# 定义文件路径
CONFIG_FILE="/etc/netplan/00-installer-config.yaml"

# 查询当前的内网 IPv4 和 IPv6 地址
CURRENT_IPV4=$(ip -4 addr show scope global | grep inet | awk '{print $2}')
CURRENT_IPV6=$(ip -6 addr show scope global | grep inet6 | awk '{print $2}')

# 查询公网 IPv6 地址
PUBLIC_IPV6=$(curl -6 -s https://ifconfig.co)

# 显示当前的内网 IPv4 和 IPv6 地址
echo "当前的内网 IPv4 地址是: $CURRENT_IPV4"
echo "当前的内网 IPv6 地址是: $CURRENT_IPV6"

# 显示公网 IPv6 地址
echo "当前的公网 IPv6 地址是: $PUBLIC_IPV6"

# 提示用户输入新的 IPv4 和 IPv6 地址
read -p "请输入新的 IPv4 地址（例如：192.168.1.125/24）: " NEW_IPV4
read -p "请输入新的 IPv6 地址（例如：2a01:4f8:221:38d9::125/64）: " NEW_IPV6

# 备份原配置文件
sudo cp $CONFIG_FILE "${CONFIG_FILE}.bak"

# 读取文件并逐行处理，替换旧的 IPv4 和 IPv6 地址
sudo awk -v new_ipv4="$NEW_IPV4" -v new_ipv6="$NEW_IPV6" '
{
    if ($0 ~ /192\.168\.1\.250\/24/) {
        sub(/192\.168\.1\.250\/24/, new_ipv4);
    }
    if ($0 ~ /2a01:4f8:221:38d9::250\/64/) {
        sub(/2a01:4f8:221:38d9::250\/64/, new_ipv6);
    }
    print;
}
' "$CONFIG_FILE" | sudo tee "$CONFIG_FILE" > /dev/null

# 提示用户文件已修改，并应用 netplan 配置
echo "网络配置文件已修改为："
echo "IPv4: $NEW_IPV4"
echo "IPv6: $NEW_IPV6"

# 应用新的网络配置
sudo netplan apply

# 重启网络服务
sudo systemctl start netplan-ovs-cleanup.service

echo "网络配置已应用并重启。"
