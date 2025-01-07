#!/bin/bash

# 函数用于执行所有操作
generate_ipv6_addresses() {
    local ipv6_prefix
    local num_addresses

    # 获取用户输入
    read -p "请输入 IPv6 前缀（例如: 2a0f:7803:fac0:0008::/64）: " ipv6_prefix
    read -p "请输入要生成的 IPv6 地址数量: " num_addresses

    # 检查 IPv6 前缀格式
    if ! [[ "$ipv6_prefix" =~ ^([0-9a-fA-F:]+)(/([0-9]+))?$ ]]; then
        echo "错误: IPv6 前缀格式无效。"
        return 1
    fi

    local prefix_part="${ipv6_prefix%/*}"
    local netmask="${ipv6_prefix#*/}"

    # 获取活动网卡
    local interface=$(ip -o link show | awk '/state UP/ {print $2}' | sed 's/://')
    if [ -z "$interface" ]; then
        echo "未找到活动网卡。"
        return 1
    fi

    echo "使用网络接口: $interface"
    echo "IPv6 前缀: $ipv6_prefix"
    echo "要生成的 IPv6 地址数量: $num_addresses"

    # 生成随机 IPv6 地址并添加到网卡配置文件
    for i in $(seq 0 $((num_addresses - 1))); do
        local ipv6_address=$(generate_ipv6_address "$prefix_part")

        # 将 IPv6 地址添加到网卡配置文件
        echo "正在将 IPv6 地址 $ipv6_address 添加到接口 $interface 的配置文件"
        echo "address $ipv6_address" >> /etc/network/interfaces.d/$interface.cfg
        echo "netmask $netmask" >> /etc/network/interfaces.d/$interface.cfg
    done

    # 更新路由配置（如果需要）
    if [[ "$netmask" ]]; then
        echo "正在添加 IPv6 默认路由"
        echo "up route -6 add default gw ${prefix_part}1" >> /etc/network/interfaces.d/$interface.cfg
    fi

    echo "IPv6 地址已添加到 $interface 接口的配置文件中，将在系统重启后保持有效。"
}

# 主函数
main() {
    local ipv6_prefix
    local num_addresses

    # 显示欢迎信息
    echo "欢迎使用 IPv6 地址生成器！"
    echo "此脚本将帮助您生成并配置 IPv6 地址。"

    # 获取用户输入
    read_user_input

    # 执行操作
    generate_ipv6_addresses

    # 提示用户重启系统
    echo "IPv6 地址已配置完成。"
    read -p "请重启系统以应用新的 IPv6 配置。按下 Enter 键继续..."

    # 重启系统
    sudo reboot
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
}

# 函数用于验证 IPv6 前缀格式
validate_ipv6_prefix() {
    local prefix="$1"
    if [[ "$prefix" =~ ^([0-9a-fA-F:]+)(/([0-9]+))?$ ]]; then
        return 0
    else
        return 1
    fi
}

# 调用主函数
main "$@"
