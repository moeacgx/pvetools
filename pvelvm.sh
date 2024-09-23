#!/bin/bash

# 查找新的硬盘
NEW_DISK=$(lsblk -dpn | grep -E '^/dev/sd[b-z]' | awk '{print $1}' | tail -n 1)

if [ -z "$NEW_DISK" ]; then
  echo "未找到新硬盘，跳过后续操作。"
  exit 0
fi

echo "检测到新硬盘：$NEW_DISK"

# 自动分区整个硬盘
echo -e "n\np\n1\n\n\nw" | fdisk "$NEW_DISK"

# 刷新分区表
partprobe "$NEW_DISK"

# 创建物理卷
if pvcreate "${NEW_DISK}1"; then
  echo "成功创建物理卷：${NEW_DISK}1"
else
  echo "物理卷 ${NEW_DISK}1 已存在，跳过创建。"
fi

# 获取卷组名称
VG_NAME=$(vgs --noheadings -o vg_name | xargs)

if [ -z "$VG_NAME" ]; then
  echo "未找到卷组。"
  exit 1
fi

echo "卷组名称：$VG_NAME"

# 将新分区添加到卷组
if vgextend "$VG_NAME" "${NEW_DISK}1"; then
  echo "成功将 ${NEW_DISK}1 添加到卷组：$VG_NAME"
else
  echo "${NEW_DISK}1 已经在卷组 $VG_NAME 中，跳过添加。"
fi

# 获取逻辑卷名称
LV_NAME=$(lvs --noheadings -o lv_name | xargs)

if [ -z "$LV_NAME" ]; then
  echo "未找到逻辑卷。"
  exit 1
fi

echo "逻辑卷名称：$LV_NAME"

# 扩展逻辑卷，使用新硬盘的空间
if lvextend -l +100%FREE "/dev/$VG_NAME/$LV_NAME"; then
  echo "成功扩展逻辑卷：$LV_NAME"
else
  echo "逻辑卷 $LV_NAME 已经使用了所有可用空间，跳过扩展。"
fi

# 检测文件系统类型
FS_TYPE=$(blkid -o value -s TYPE "/dev/$VG_NAME/$LV_NAME")

if [ "$FS_TYPE" == "ext4" ]; then
    echo "扩展 ext4 文件系统..."
    if resize2fs "/dev/$VG_NAME/$LV_NAME"; then
        echo "成功扩展文件系统：$LV_NAME"
    else
        echo "文件系统 $LV_NAME 已经是最大，跳过扩展。"
    fi
elif [ "$FS_TYPE" == "xfs" ]; then
    echo "扩展 xfs 文件系统..."
    if xfs_growfs "/dev/$VG_NAME/$LV_NAME"; then
        echo "成功扩展文件系统：$LV_NAME"
    else
        echo "文件系统 $LV_NAME 扩展失败。"
    fi
else
    echo "未知的文件系统类型: $FS_TYPE，无法扩展。"
    exit 1
fi

echo "新硬盘 $NEW_DISK 已分区、格式化，并成功添加到 LVM 卷组和逻辑卷中。"
