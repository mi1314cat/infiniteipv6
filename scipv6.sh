#!/bin/bash

# 获取用户输入
read -p "请输入 IPv6 网络地址: " ipv6_network
read -p "请输入要生成的地址数量 (默认 15): " num_addresses
read -p "请输入目标网络位数 (默认 128): " target_network_bits

# 验证 IPv6 地址格式
if ! [[ $ipv6_network =~ ^([0-9a-fA-F]{1,4}:){7}([0-9a-fA-F]{1,4})$ ]]; then
    echo "无效的 IPv6 地址格式"
    exit 1
fi

# 设置默认值
num_addresses=${num_addresses:-15}
target_network_bits=${target_network_bits:-128}

# 输出命令
echo "bash ipv6.sh $ipv6_network $num_addresses $target_network_bits"
