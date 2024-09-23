## pvelvm脚本步骤说明：
### 兼容 Ubuntu/Debian

####pvelvm脚本一键运行：

`wget https://raw.githubusercontent.com/moeacgx/pvetools/refs/heads/main/pvelvm.sh -O pvelvm.sh && chmod +x pvelvm.sh && ./pvelvm.sh`

1. 自动查找新硬盘：自动检测未使用的新硬盘设备名。
2. 分区新硬盘：将新硬盘分成一个主分区。
3. 刷新分区表：使用 partprobe 让系统识别新分区。
4. 创建物理卷：将新分区（如 /dev/sdb1）初始化为 LVM 物理卷。
5. 扩展卷组：将新物理卷加入到现有的卷组中。
6. 扩展逻辑卷：将逻辑卷扩展到新硬盘上的空间。
7. 扩展文件系统：根据逻辑卷的文件系统类型（这里默认是 ext4），调整文件系统大小以匹配新空间。
## 执行方法：
1. 保存脚本为 lvm_expand.sh。
2. 赋予脚本执行权限：
`chmod +x lvm_expand.sh`

1. 运行脚本：
`./lvm_expand.sh`

运行后，脚本将自动完成新硬盘的分区、格式化、LVM 添加及逻辑卷扩展。如果你使用的是不同的文件系统，请替换相应的 resize2fs 命令。
