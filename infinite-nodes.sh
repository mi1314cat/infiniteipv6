#!/bin/bash
generate_ipv6() {
wget https://github.com/mi1314cat/reality_xray/raw/refs/heads/main/ipv6.sh
read -p "前置脚本已完成回车继续"
clear
# 获取用户输入
ip a
read -p "请输入 IPv6 网络地址: " ipv6_network
read -p "请输入要生成的地址数量 (默认 15): " num_addresses
read -p "请输入目标网络位数 (默认 128): " target_network_bits

# 验证 IPv6 地址格式
if ! [[ $ipv6_network =~ ^([0-9a-fA-F]{1,4}:){7}([0-9a-fA-F]{1,4})/([1-9]?[0-9]{0,2}|1[0-1][0-9]{2}|12[0-8])$ ]]; then
    echo "无效的 IPv6 地址格式或网络前缀长度"
    exit 1
fi

# 设置默认值
num_addresses=${num_addresses:-15}
target_network_bits=${target_network_bits:-128}

# 输出命令
echo "bash ipv6.sh $ipv6_network $num_addresses $target_network_bits"
echo "bash ipv6.sh $ipv6_network $num_addresses $target_network_bits > ipv6.txt"
}
# 删除生成的文件的前五行
trim_file() {
    echo "正在删除前五行..."
    sed -i '1,5d' ipv6.txt
}
# 生成临时ipv6
assign_ipv6() {
wget https://github.com/mi1314cat/reality_xray/raw/refs/heads/main/assign_ipv6.sh
read -p "前置脚本已完成回车继续"
clear
ip a 

read -p "请输入ipv6网络接口: " network_interface

echo "bash assign_ipv6.sh $network_interface ipv6.txt"
}
generate_nodes() {

bash -c "$(curl -s -L https://github.com/mi1314cat/reality_xray/raw/refs/heads/main/reality_xray_ip.sh)"
}



main() {
    generate_ipv6
    trim_file
    assign_ipv6
    generate_nodes
}

main
		


















