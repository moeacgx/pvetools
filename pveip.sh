#!/bin/bash

# 定义文件路径
CONFIG_FILE="/etc/netplan/00-installer-config.yaml"

# 提示用户输入新的 IPv4 和 IPv6 地址
read -p "请输入新的 IPv4 地址（例如：192.168.1.125/24）: " NEW_IPV4
read -p "请输入新的 IPv6 地址（例如：2a01:4f8:221:38d9::125/64）: " NEW_IPV6

# 使用 sed 命令替换文件中的 IPv4 和 IPv6 地址
sudo sed -i "s|192.168.1.250/24|$NEW_IPV4|g" $CONFIG_FILE
sudo sed -i "s|2a01:4f8:221:38d9::250/64|$NEW_IPV6|g" $CONFIG_FILE

# 提示用户文件已修改，并应用 netplan 配置
echo "网络配置文件已修改为："
echo "IPv4: $NEW_IPV4"
echo "IPv6: $NEW_IPV6"

# 应用新的网络配置
sudo netplan apply

# 重启网络服务
sudo systemctl start netplan-ovs-cleanup.service

echo "网络配置已应用并重启。"
