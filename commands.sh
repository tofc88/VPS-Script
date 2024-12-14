#!/bin/bash
# VPS 管理脚本

# 主菜单函数
display_main_menu() {
    clear
    echo "========================================="
    echo " VPS 管理脚本 "
    echo "========================================="
    echo "1) 系统配置"
    echo "2) 校准时间"
    echo "3) 更新系统"
    echo "4) 清理系统"
    echo "5) 开启BBR"
    echo "6) 申请证书"
    echo "7) 安装Xray"
    echo "8) 安装hysteria2"
    echo "9) 安装1Panel"
    echo "0) 退出脚本"
    echo "========================================="
}

# 显示系统信息
view_vps_info() {
    echo "系统信息查询"
    echo "-------------"
    local hostname; hostname=$(hostname)
    local os_version; os_version=$(lsb_release -ds 2>/dev/null || grep PRETTY_NAME /etc/os-release | cut -d '"' -f2)
    local kernel_version; kernel_version=$(uname -r)
    local cpu_arch; cpu_arch=$(uname -m)
    local model_name; model_name=$(lscpu | grep 'Model name' | sed 's/Model name:[ \t]*//')
    local cpu_cores; cpu_cores=$(nproc)
    local cpu_mhz; cpu_mhz=$(lscpu | grep 'CPU MHz' | awk -F: '{print $2}')
    local cpu_usage; cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')
    local load_avg; load_avg=$(uptime | awk -F'load average:' '{print $2}' | xargs)
    local memory_usage; memory_usage=$(free -m | awk '/Mem:/ {printf "%.2f/%.2f MB (%.2f%%)", $3, $2, $3/$2*100}')
    local swap_usage; swap_usage=$(free -m | awk '/Swap:/ {printf "%.0fMB/%.0fMB (%.0f%%)", $3, $2, $3/$2*100}')
    local disk_usage; disk_usage=$(df -h / | awk '/\// {print $3 "/" $2 " (" $5 ")"}')
    local rx_total; rx_total=$(ifconfig | grep 'RX packets' | awk '{print $5/1024/1024 " MB"}' | head -n1)
    local tx_total; tx_total=$(ifconfig | grep 'TX packets' | awk '{print $5/1024/1024 " MB"}' | head -n1)
    local congestion_control; congestion_control=$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')
    local provider; provider=$(curl -s ipinfo.io/org)
    local ipv4_address; ipv4_address=$(curl -s ipv4.icanhazip.com)
    local dns_addresses; dns_addresses=$(awk '/nameserver/ {print $2}' /etc/resolv.conf | xargs)
    local location; location=$(curl -s ipinfo.io/city), $(curl -s ipinfo.io/country)
    local system_time; system_time=$(timedatectl | grep "Local time" | awk '{print $3, $4}')
    local uptime; uptime=$(uptime -p | sed 's/up //')

    echo "主机名:      $hostname"
    echo "系统版本:    $os_version"
    echo "Linux版本:   $kernel_version"
    echo "-------------"

    echo "CPU架构:     $cpu_arch"
    echo "CPU型号:     $model_name"
    echo "CPU核心数:   $cpu_cores"
    echo "CPU频率:     ${cpu_mhz}MHz"
    echo "-------------"

    echo "CPU占用:     $cpu_usage%"
    echo "系统负载:    $load_avg"
    echo "物理内存:    $memory_usage"
    echo "虚拟内存:    $swap_usage"
    echo "硬盘占用:    $disk_usage"
    echo "-------------"

    echo "总接收:      $rx_total"
    echo "总发送:      $tx_total"
    echo "-------------"

    echo "网络算法:    $congestion_control"
    echo "-------------"

    echo "运营商:      $provider"
    echo "IPv4地址:    $ipv4_address"
    echo "DNS地址:     $dns_addresses"
    echo "地理位置:    $location"
    echo "系统时间:    $system_time"
    echo "-------------"

    echo "运行时长:    $uptime"
}

# 时间校准
calibrate_time() {
    echo -e "\n[校准时间]"
    sudo timedatectl set-timezone Asia/Shanghai
    sudo timedatectl set-ntp true
    echo "时间校准完成，当前时区为 Asia/Shanghai"
}

# 系统更新
update_system() {
    echo -e "\n[更新系统]"
    sudo apt update -y && sudo apt full-upgrade -y
    sudo apt autoremove -y && sudo apt autoclean -y
    echo "系统更新完成！"
}

# 系统清理
clean_system() {
    echo -e "\n[清理系统]"
    sudo apt autoremove --purge -y
    sudo apt clean -y && sudo apt autoclean -y
    sudo journalctl --rotate && sudo journalctl --vacuum-time=10m
    sudo journalctl --vacuum-size=50M
    echo "系统清理完成！"
}

# 开启 BBR
enable_bbr() {
    echo -e "\n[开启BBR]"
    if sysctl net.ipv4.tcp_congestion_control | grep -q 'bbr'; then
        echo "BBR 已开启。"
    else
        echo "net.core.default_qdisc = fq" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv4.tcp_congestion_control = bbr" | sudo tee -a /etc/sysctl.conf
        sudo sysctl -p
        echo "BBR 已启用，重启系统后生效。"
    fi
}

# 安装 Xray
install_xray() {
    while true; do
        echo -e "\n[安装 Xray]"
        echo "1) 安装/升级"
        echo "2) 编辑配置"
        echo "3) 重启服务"
        echo "4) 查看状态"
        echo "5) 卸载服务"
        echo "6) 返回主菜单"
        read -r -p "请输入数字 [1-6]: " xray_choice
        case "$xray_choice" in
            1)
                bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
                echo "Xray 安装/升级完成！"
                ;;
            2) sudo nano /usr/local/etc/xray/config.json ;;
            3)
                sudo systemctl restart xray
                echo "Xray 已重启。"
                ;;
            4) sudo systemctl status xray ;;
            5)
                bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove --purge
                echo "Xray 已卸载。"
                ;;
            6) return ;;
            *) echo "无效选项，请重新输入。" ;;
        esac
    done
}

# 安装 hysteria2
install_hysteria2() {
    while true; do
        echo -e "\n[安装 hysteria2]"
        echo "1) 安装/升级"
        echo "2) 编辑配置"
        echo "3) 重启服务"
        echo "4) 查看状态"
        echo "5) 开机自启"
        echo "6) 卸载服务"
        echo "7) 返回主菜单"
        read -r -p "请输入数字 [1-7]: " hysteria_choice
        case "$hysteria_choice" in
            1)
                bash <(curl -fsSL https://get.hy2.sh/)
                echo "hysteria2 安装/升级完成！"
                ;;
            2) sudo nano /etc/hysteria/config.yaml ;;
            3)
                sudo systemctl restart hysteria-server.service
                echo "hysteria2 已重启。"
                ;;
            4) sudo systemctl status hysteria-server.service ;;
            5)
                sudo systemctl enable --now hysteria-server.service
                echo "hysteria2 已设置为开机自启。"
                ;;
            6)
                bash <(curl -fsSL https://get.hy2.sh/) --remove
                echo "hysteria2 已卸载。"
                ;;
            7) return ;;
            *) echo "无效选项，请重新输入。" ;;
        esac
    done
}

# 安装 1Panel
install_1panel() {
    while true; do
        echo -e "\n[安装 1Panel]"
        echo "1) 安装面板"
        echo "2) 卸载面板"
        echo "3) 卸载 Docker"
        echo "4) 返回主菜单"
        read -r -p "请输入数字 [1-4]: " panel_choice
        case "$panel_choice" in
            1)
                curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh && sudo bash quick_start.sh
                echo "1Panel 安装完成！"
                ;;
            2)
                sudo systemctl stop 1panel && sudo 1pctl uninstall && sudo rm -rf /var/lib/1panel /etc/1panel /usr/local/bin/1pctl && sudo journalctl --vacuum-time=3d
                echo "1Panel 卸载完成！"
                ;;
            3)
                sudo systemctl stop docker && sudo apt-get purge -y docker-ce docker-ce-cli containerd.io && sudo rm -rf /var/lib/docker /etc/docker /var/run/docker.sock && sudo groupdel docker
                echo "Docker 已卸载。"
                ;;
            4) return ;;
            *) echo "无效选项，请重新输入。" ;;
        esac
    done
}

# 主循环
while true; do
    display_main_menu
    read -r -p "请输入数字 [1-0] 选择功能: " choice
    case "$choice" in
        1) view_vps_info ;;
        2) calibrate_time ;;
        3) update_system ;;
        4) clean_system ;;
        5) enable_bbr ;;
        6) apply_certificate ;;
        7) install_xray ;;
        8) install_hysteria2 ;;
        9) install_1panel ;;
        0)
            echo "退出脚本，感谢使用！"
            exit 0
            ;;
        *) echo "无效选项，请输入数字 1-0！" ;;
    esac
    if [[ "$choice" != "6" && "$choice" != "7" && "$choice" != "8" && "$choice" != "9" ]]; then
        read -r -n 1 -s -p "按任意键返回主菜单..."
    fi
done
