#!/bin/bash

# 检查是否提供了足够的参数
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <IPv6_PREFIX> <NUMBER_OF_ADDRESSES>"
    echo "Example: $0 2a0f:7803:fac0:0008:: 10"
    exit 1
fi

# 获取输入的 IPv6 网段和地址个数
IPv6_PREFIX=$1
NUM_ADDRESSES=$2

# 检查 IPv6 前缀格式是否有效
if ! [[ "$IPv6_PREFIX" =~ ^[0-9a-fA-F:]+$ ]]; then
    echo "Invalid IPv6 prefix format: $IPv6_PREFIX"
    exit 1
fi

# 获取网卡名称，尝试获取活动接口
INTERFACE=$(ip -4 route show default | awk '{print $5}')
if [ -z "$INTERFACE" ]; then
    echo "No active network interface found."
    exit 1
fi

# 检查网卡是否存在
if ! ip link show "$INTERFACE" &>/dev/null; then
    echo "Network interface $INTERFACE does not exist."
    exit 1
fi

# 生成 IPv6 地址并添加到网卡
for i in $(seq 0 $((NUM_ADDRESSES - 1))); do
    # 计算每个地址的后缀，后缀以16进制递增，填充到4位
    SUFFIX=$(printf "%04x" $i)
    
    # 生成完整的 IPv6 地址
    IP="${IPv6_PREFIX}${SUFFIX}"

    # 使用 ip 命令添加 IPv6 地址
    echo "Adding IPv6 address $IP to interface $INTERFACE"
    sudo ip -6 addr add "$IP/64" dev "$INTERFACE" || { echo "Failed to add $IP"; exit 1; }
done

# 更新路由配置（如果需要）
echo "Adding IPv6 default route"
sudo ip -6 route add default via "${IPv6_PREFIX}1" || { echo "Failed to add default route"; exit 1; }

echo "IPv6 addresses added successfully!"
