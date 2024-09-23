#!/bin/bash

# 查找新的硬盘
NEW_DISK=$(lsblk -dpn | grep -E '^/dev/(sd[b-z]|nvme[0-9]n[1-9])' | awk '{print $1}' | tail -n 1)

if [ -z "$NEW_DISK" ]; then
  echo "未找到新硬盘。"
  exit 1
fi

echo "检测到新硬盘：$NEW_DISK"

# 使用 parted 自动分区整个硬盘
parted -s "$NEW_DISK" mklabel gpt
parted -s "$NEW_DISK" mkpart primary 0% 100%

# 刷新分区表
partprobe "$NEW_DISK"

# 创建物理卷
pvcreate "${NEW_DISK}1"

# 获取卷组名称（如果有多个卷组，提示用户选择）
VG_NAME=$(vgs --noheadings -o vg_name | xargs)
if [ -z "$VG_NAME" ]; then
  echo "未找到卷组。"
  exit 1
fi

echo "卷组名称：$VG_NAME"

# 将新分区添加到卷组
vgextend "$VG_NAME" "${NEW_DISK}1"

# 获取逻辑卷名称（如果有多个逻辑卷，提示用户选择）
LV_NAME=$(lvs --noheadings -o lv_name | xargs)
if [ -z "$LV_NAME" ]; then
  echo "未找到逻辑卷。"
  exit 1
fi

echo "逻辑卷名称：$LV_NAME"

# 扩展逻辑卷，使用新硬盘的空间
lvextend -l +100%FREE "/dev/$VG_NAME/$LV_NAME"

# 检测文件系统类型并扩展文件系统
FS_TYPE=$(blkid -o value -s TYPE "/dev/$VG_NAME/$LV_NAME")

if [ "$FS_TYPE" == "ext4" ]; then
  resize2fs "/dev/$VG_NAME/$LV_NAME"
elif [ "$FS_TYPE" == "xfs" ]; then
  xfs_growfs "/dev/$VG_NAME/$LV_NAME"
else
  echo "不支持的文件系统类型：$FS_TYPE"
  exit 1
fi

echo "新硬盘 $NEW_DISK 已分区、格式化，并成功添加到 LVM 卷组和逻辑卷中。"
