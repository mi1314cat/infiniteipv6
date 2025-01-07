#!/bin/bash

# 使用函数来打印脚本使用说明
print_usage() {
    echo "Usage: $0 <IPv6_PREFIX> <NUMBER_OF_ADDRESSES>"
    echo "Example: $0 2a0f:7803:fac0:0008::/64 10"
    exit 1
}

# 获取用户输入 IPv6 前缀和生成地址的数量
echo "Please enter the IPv6 prefix (e.g., 2a0f:7803:fac0:0008::/64):"
read IPv6_PREFIX
echo "Please enter the number of IPv6 addresses to generate:"
read NUM_ADDRESSES

# 检查 IPv6 前缀格式并提取前缀部分（去掉 /64）
if [[ "$IPv6_PREFIX" =~ ^([0-9a-fA-F:]+)(/([0-9]+))?$ ]]; then
    IPv6_PREFIX="${BASH_REMATCH[1]}"  # 提取前缀部分，去掉子网掩码
else
    echo "Error: Invalid IPv6 prefix format."
    exit 1
fi

# 检查地址个数是否合法
if ! [[ "$NUM_ADDRESSES" =~ ^[0-9]+$ ]] || [ "$NUM_ADDRESSES" -le 0 ]; then
    echo "Error: Invalid number of addresses. It must be a positive integer."
    exit 1
fi

# 获取默认网卡
INTERFACE=$(ip -4 route show default | awk '{print $5}')
if [ -z "$INTERFACE" ]; then
    echo "Error: No active network interface found."
    exit 1
fi

# 检查网卡是否存在
if ! ip link show "$INTERFACE" &>/dev/null; then
    echo "Error: Network interface $INTERFACE does not exist."
    exit 1
fi

echo "Using network interface: $INTERFACE"
echo "IPv6 Prefix: $IPv6_PREFIX"
echo "Number of addresses to add: $NUM_ADDRESSES"

# 生成随机 IPv6 地址并添加到网卡
for i in $(seq 0 $((NUM_ADDRESSES - 1))); do
    # 确保后缀小于 128
    SUFFIX=$((RANDOM % 128))  # 随机生成0-127之间的数字

    # 计算随机后缀的16进制表示，并确保是4位
    SUFFIX_HEX=$(printf "%04x" $SUFFIX)
    
    # 生成完整的 IPv6 地址
    IP="${IPv6_PREFIX}${SUFFIX_HEX}/64"

    # 使用 ip 命令添加 IPv6 地址
    echo "Adding IPv6 address $IP to interface $INTERFACE"
    sudo ip -6 addr add "$IP" dev "$INTERFACE" || { echo "Failed to add $IP"; exit 1; }
done

# 更新路由配置（如果需要）
echo "Adding IPv6 default route"
sudo ip -6 route add default via "${IPv6_PREFIX}1" || { echo "Failed to add default route"; exit 1; }

echo "IPv6 addresses added successfully!"
