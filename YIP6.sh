#!/bin/bash

# 函数用于生成 IPv6 地址
generate_ipv6_address() {
    local prefix="$1"
    local suffix=$RANDOM

    # 计算后缀的16进制表示，并确保是4位
    suffix_hex=$(printf "%04x" $suffix)

    # 生成完整的 IPv6 地址
    echo "${prefix}${suffix_hex}"
}

# 函数用于获取用户输入
read_user_input() {
    local ipv6_prefix
    local num_addresses

    # 提示用户输入 IPv6 前缀
    while true; do
        read -p "请输入 IPv6 前缀（例如: 2a0f:7803:fac0:0008::/64）: " ipv6_prefix
        if validate_ipv6_prefix "$ipv6_prefix"; then
            break
        else
            echo "错误: IPv6 前缀格式无效。请重新输入。"
        fi
    done

    # 提示用户输入地址数量
    while true; do
        read -p "请输入要生成的 IPv6 地址数量: " num_addresses
        if [[ "$num_addresses" =~ ^[0-9]+$ ]] && [ "$num_addresses" -gt 0 ]; then
            break
        else
            echo "错误: 地址数量无效。请输入正整数。"
        fi
    done

    echo "IPv6 前缀: $ipv6_prefix"
    echo "要生成的 IPv6 地址数量: $num_addresses"

    # 返回输入的值
    echo "$ipv6_prefix"
    echo "$num_addresses"
}

# 函数用于验证 IPv6 前缀格式
validate_ipv6_prefix() {
    local prefix="$1"
    if [[ "$prefix" =~ ^([0-9a-fA-F:]+)(/([0-9]+))?$ ]]; then
        local prefix_part="${BASH_REMATCH[1]}"
        local netmask="${BASH_REMATCH[2]}"
        return 0
    else
        return 1
    fi
}

# 主函数
main() {
    local ipv6_prefix
    local num_addresses

    # 获取用户输入
    ipv6_prefix=$(read_user_input)
    num_addresses=$(read_user_input)

    # 检查 IPv6 前缀格式
    if ! validate_ipv6_prefix "$ipv6_prefix"; then
        echo "错误: IPv6 前缀格式无效。"
        exit 1
    fi

    local prefix_part="${ipv6_prefix%/*}"
    local netmask="${ipv6_prefix#*/}"

    # 获取活动网卡
    local interface=$(ip -o link show | awk '/state UP/ {print $2}' | sed 's/://')
    if [ -z "$interface" ]; then
        echo "未找到活动网卡。"
        exit 1
    fi

    echo "使用网络接口: $interface"

    # 生成 IPv6 地址并添加到配置文件
    for i in $(seq 1 $num_addresses); do
        local ipv6_address=$(generate_ipv6_address "$prefix_part")

        # 将 IPv6 地址添加到接口配置文件
        echo "正在将 IPv6 地址 $ipv6_address 添加到接口 $interface 的配置文件"
        echo "iface $interface inet6 static" >> /etc/network/interfaces.d/$interface.cfg
        echo "address $ipv6_address" >> /etc/network/interfaces.d/$interface.cfg
        echo "netmask $netmask" >> /etc/network/interfaces.d/$interface.cfg
    done

    # 更新路由配置
    if [[ "$netmask" ]]; then
        echo "正在添加 IPv6 默认路由"
        echo "up route -6 add default gw ${prefix_part}1" >> /etc/network/interfaces.d/$interface.cfg
    fi

    echo "IPv6 地址已添加到 $interface 接口的配置文件中，将在系统重启后保持有效。"
}

# 调用主函数
main "$@"
