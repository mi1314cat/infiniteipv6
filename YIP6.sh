#!/bin/bash

# 打印使用说明
print_usage() {
    echo "用法: $0 <IPv6_PREFIX> <生成地址数量>"
    echo "示例: $0 2a0f:7803:fac0:0008::/64 10"
    exit 1
}

# 获取用户输入 IPv6 前缀和生成地址的数量
echo "请输入 IPv6 前缀（例如: 2a0f:7803:fac0:0008::/64）:"
read IPv6_PREFIX
echo "请输入要生成的 IPv6 地址数量:"
read NUM_ADDRESSES

# 检查 IPv6 前缀格式
if [[ "$IPv6_PREFIX" =~ ^([0-9a-fA-F:]+)(/([0-9]+))?$ ]]; then
    PREFIX="${BASH_REMATCH[1]}"  # 提取前缀部分
    NETMASK="${BASH_REMATCH[2]}"  # 提取子网掩码部分
else
    echo "错误: IPv6 前缀格式无效。"
    exit 1
fi

# 检查地址个数是否合法
if ! [[ "$NUM_ADDRESSES" =~ ^[0-9]+$ ]] || [ "$NUM_ADDRESSES" -le 0 ]; then
    echo "错误: 地址个数无效。必须是正整数。"
    exit 1
fi

# 获取活动网卡
INTERFACE=$(ip -o link show | awk '/state UP/ {print $2}' | sed 's/://')

if [ -z "$INTERFACE" ]; then
    echo "错误: 未找到活动网卡。"
    exit 1
fi

# 检查网卡是否存在
if ! ip link show "$INTERFACE" &>/dev/null; then
    echo "错误: 网络接口 $INTERFACE 不存在。"
    exit 1
fi

echo "使用网络接口: $INTERFACE"
echo "IPv6 前缀: $IPv6_PREFIX"
echo "要添加的 IPv6 地址个数: $NUM_ADDRESSES"

# 生成随机 IPv6 地址并添加到网卡
for i in $(seq 0 $((NUM_ADDRESSES - 1))); do
    # 确保后缀小于 128
    SUFFIX=$((RANDOM % 128))  # 随机生成0到127之间的数字

    # 计算随机后缀的16进制表示，并确保是4位
    SUFFIX_HEX=$(printf "%04x" $SUFFIX)
    
    # 生成完整的 IPv6 地址
    IP="${PREFIX}${SUFFIX_HEX}"

    # 使用 ip 命令添加 IPv6 地址
    echo "正在将 IPv6 地址 $IP 添加到接口 $INTERFACE"
    sudo ip -6 addr add "$IP/$NETMASK" dev "$INTERFACE" || { echo "错误: 无法添加 IPv6 地址 $IP"; exit 1; }
done

# 更新路由配置（如果需要）
echo "正在添加 IPv6 默认路由"
sudo ip -6 route add default via "${PREFIX}1" || { echo "错误: 无法添加默认路由"; exit 1; }

echo "IPv6 地址成功添加，并且会在系统重启后保持有效！"
