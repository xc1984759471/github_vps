#!/bin/bash
set -e

MIN_SIZE_GB=50
STORAGE_SUBDIR="docker-windows-storage"

echo "🔍 检测大容量数据盘..."

# 优先检查 /tmp（Codespaces / GitPod 常见挂载点）
TMP_DEV=""
TMP_SIZE_GB=0
if mountpoint -q /tmp 2>/dev/null; then
    TMP_DEV=$(findmnt -n -o SOURCE -T /tmp 2>/dev/null || df -P /tmp | awk 'NR==2{print $1}')
    TMP_SIZE_KB=$(df -P /tmp | awk 'NR==2{print $2}')
    TMP_SIZE_GB=$((TMP_SIZE_KB / 1024 / 1024))
fi

# 扫描所有真实块设备（排除系统盘、overlay、loop 等虚拟盘）
readarray -t CANDIDATES < <(df -P -x tmpfs -x devtmpfs -x overlay -x proc -x sysfs -x cgroup2 -x cgroup 2>/dev/null | awk 'NR>1 {
    if ($1 ~ /^\/dev\/loop/ || $1 ~ /^\/dev\/ram/) next
    if ($6 == "/" || $6 == "/vscode" || $6 == "/workspaces" || $6 == "/boot") next
    size_gb = int($2 / 1024 / 1024)
    if (size_gb >= 50) print size_gb, $1, $6
}' | sort -rn)

TARGET_MOUNT=""
TARGET_DEV=""

# 如果 /tmp 挂载在大容量真实设备上，优先用它（避免重复挂载）
if [ -n "$TMP_DEV" ] && [[ "$TMP_DEV" == /dev/* ]] && [ "$TMP_SIZE_GB" -ge "$MIN_SIZE_GB" ]; then
    TARGET_MOUNT="/tmp"
    TARGET_DEV="$TMP_DEV"
    echo "✅ 使用 /tmp（设备: $TMP_DEV, 容量: ${TMP_SIZE_GB}G）"
else
    if [ ${#CANDIDATES[@]} -eq 0 ]; then
        echo "❌ 未检测到 >=${MIN_SIZE_GB}G 的数据盘"
        exit 1
    fi
    read -r MAX_GB MAX_DEV MAX_MNT <<< "${CANDIDATES[0]}"
    TARGET_MOUNT="$MAX_MNT"
    TARGET_DEV="$MAX_DEV"
    echo "✅ 使用数据盘: $MAX_DEV -> $TARGET_MOUNT (${MAX_GB}G)"
fi

# 创建 storage 目录（实际存放 qcow2 磁盘镜像）
STORAGE_PATH="$TARGET_MOUNT/$STORAGE_SUBDIR"
mkdir -p "$STORAGE_PATH"
echo "📂 Storage 路径: $STORAGE_PATH"

# 当前目录生成 docker-compose.yml
CURRENT_DIR=$(pwd)
COMPOSE_FILE="$CURRENT_DIR/docker-compose.yml"

# 如果已存在则备份
if [ -f "$COMPOSE_FILE" ]; then
    BACKUP="$CURRENT_DIR/docker-compose.yml.bak.$(date +%s)"
    mv "$COMPOSE_FILE" "$BACKUP"
    echo "💾 已备份原配置: $BACKUP"
fi

# 检查可用空间
AVAIL_GB=$(df -P "$TARGET_MOUNT" | awk 'NR==2{print int($4/1024/1024)}')
echo "   可用空间: ${AVAIL_GB}G"

TOTAL_NEEDED=74  # 64G + 10G
if [ "$AVAIL_GB" -lt "$TOTAL_NEEDED" ]; then
    echo ""
    echo "⚠️  警告: 可用空间仅 ${AVAIL_GB}G，但虚拟磁盘配置了 ${TOTAL_NEEDED}G（稀疏格式，实际占用取决于 Windows 内写入量）"
    echo "    如果 Windows 内部使用超过 ${AVAIL_GB}G，磁盘将会写满！"
    echo ""
fi

# 生成 docker-compose.yml
cat > "$COMPOSE_FILE" << EOF
services:
  windows:
    image: dockurr/windows
    container_name: windows
    environment:
      VERSION: "11"
      USERNAME: "MASTER"
      PASSWORD: "admin@123"
      RAM_SIZE: "4G"
      CPU_CORES: "4"
      DISK_SIZE: "64G"
      DISK2_SIZE: "10G"
    devices:
      - /dev/kvm
      - /dev/net/tun
    cap_add:
      - NET_ADMIN
    ports:
      - "8006:8006"
      - "3389:3389/tcp"
      - "3389:3389/udp"
    volumes:
      - ${STORAGE_PATH}:/storage
    stop_grace_period: 2m
EOF

echo "✅ 已生成: $COMPOSE_FILE"

# 检测 docker compose 命令（新版插件优先）
if docker compose version &>/dev/null; then
    COMPOSE_CMD="docker compose"
elif docker-compose version &>/dev/null; then
    COMPOSE_CMD="docker-compose"
else
    echo "❌ 未检测到 docker compose 或 docker-compose，请安装 Docker"
    exit 1
fi

echo ""
echo "🚀 执行: $COMPOSE_CMD -f docker-compose.yml up"
echo ""

# 直接启动
$COMPOSE_CMD -f "$COMPOSE_FILE" up

echo ""
echo "🎉 启动完成！"
echo "   管理界面: http://localhost:8006"
echo "   RDP 连接: localhost:3389 (用户名: MASTER)"
echo "   数据存储: $STORAGE_PATH"
echo ""
echo "💡 提示: Windows 磁盘镜像实际存储在 $STORAGE_PATH"
echo "   （宿主机设备: $TARGET_DEV）"
