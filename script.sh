#!/bin/bash
# VPS 管理脚本

# 主菜单函数
display_main_menu() {
    clear
    echo "========================================="
    echo " VPS 管理脚本 "
    echo "========================================="
    echo "1) 系统信息"
    echo "2) 系统优化"
    echo "3) 申请证书"
    echo "4) 安装Xray"
    echo "5) 安装hysteria2"
    echo "6) 安装1Panel"
    echo "0) 退出脚本"
    echo "========================================="
}

# 系统信息
view_vps_info() {
    echo "系统信息查询"
    echo "-------------"
    echo "主机名:       $(hostname)"
    echo "系统版本:     $(lsb_release -ds 2>/dev/null || grep PRETTY_NAME /etc/os-release | cut -d '"' -f2)"
    echo "Linux版本:    $(uname -r)"
    echo "-------------"

    echo "CPU架构:      $(uname -m)"
    echo "CPU型号:      $(lscpu | grep 'Model name' | sed 's/Model name:[ \t]*//')"
    echo "CPU核心数:    $(nproc)"
    echo "CPU频率:      $(lscpu | grep 'CPU MHz' | awk -F: "/MHz/ {print \$2}") MHz"
    echo "-------------"

    echo "CPU占用:      $(top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}')%"
    echo "系统负载:     $(uptime | awk -F'load average:' '{print $2}' | xargs)"
    echo "物理内存:     $(free -m | awk '/Mem:/ {printf "%.2f/%.2f MB (%.2f%%)", $3, $2, $3/$2*100}')"
    echo "虚拟内存:     $(free -m | awk '/Swap:/ {printf "%.0fMB/%.0fMB (%.0f%%)", $3, $2, $3/$2*100}')"
    echo "硬盘占用:     $(df -h / | awk '/\// {print $3 "/" $2 " (" $5 ")"}')"
    echo "-------------"

    echo "总接收:       $(ifconfig | grep 'RX packets' | awk '{print $5/1024/1024 " MB"}' | head -n1)"
    echo "总发送:       $(ifconfig | grep 'TX packets' | awk '{print $5/1024/1024 " MB"}' | head -n1)"
    echo "-------------"

    echo "网络算法:     $(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')"
    echo "-------------"

    echo "运营商:       $(curl -s ipinfo.io/org)"
    echo "IPv4地址:     $(curl -s ipv4.icanhazip.com)"
    echo "DNS地址:      $(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | xargs)"
    echo "地理位置:     $(curl -s ipinfo.io/city), $(curl -s ipinfo.io/country)"
    echo "系统时间:     $(timedatectl | grep "Local time" | awk '{print $3, $4, $5}')"
    echo "-------------"

    echo "运行时长:     $(uptime -p | sed 's/up //')"
}

# 系统优化
display_system_optimization_menu() {
    while true; do
        echo "========================================="
        echo " 系统优化 "
        echo "========================================="
        echo "1) 校准时间"
        echo "2) 更新系统"
        echo "3) 清理系统"
        echo "4) 开启BBR"
        echo "5) ROOT登录"
        echo "6) 返回上级菜单"
        echo "========================================="
        read -p "请选择功能 [1-6]: " opt_choice
        case "$opt_choice" in
            1) calibrate_time ;;
            2) update_system ;;
            3) clean_system ;;
            4) enable_bbr ;;
            5) root_login ;;
            6) return ;;
            *) echo "无效选项，请重新输入。" ;;
        esac
    done
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
        echo "BBR 已启用。"
    fi
}

# ROOT登录
root_login() {
    while true; do
        echo "========================================="
        echo " ROOT登录 "
        echo "========================================="
        echo "1) 设置密码"
        echo "2) 编辑配置：修改PermitRootLogin与PasswordAuthentication为 yes"
        echo "3) 重启服务"
        echo "4) 返回上级菜单"
        echo "========================================="        
        read -p "请选择功能 [1-4]: " root_choice
        case "$root_choice" in
            1) sudo passwd root ;;
            2) sudo nano /etc/ssh/sshd_config ;;
            3) sudo systemctl restart sshd.service ;;
            4) return ;;
            *) echo "无效选项，请重新输入。" ;;
        esac
    done
}

# 申请证书
apply_certificate() {
    while true; do    
    echo "========================================="
    echo " 申请证书 "
    echo "========================================="
    echo "1) 安装脚本"
    echo "2) 申请证书"
    echo "3) 更换服务器"
    echo "4) 安装证书"
    echo "5) 卸载脚本"
    echo "6) 返回主菜单"
    echo "========================================="
    read -p "请选择功能 [1-6]: " cert_choice
    case "$cert_choice" in
        1)
            read -p "请输入邮箱地址: " email
            curl https://get.acme.sh | sh -s email=$email
            echo "acme.sh 安装完成！"
            ;;
        2)
            read -p "请输入域名: " domain
            ~/.acme.sh/acme.sh --issue --standalone -d $domain
            echo "证书申请完成！"
            ;;
        3)
            ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
            echo "已切换至 Let's Encrypt 服务。"
            ;;
        4)
            mkdir /path/to
            ~/.acme.sh/acme.sh --installcert -d $domain \
                --key-file /path/to/private.key --fullchain-file /path/to/fullchain.crt
            echo "证书安装完成！"
            ;;
        5)
            ~/.acme.sh/acme.sh --uninstall
            echo "acme.sh 已卸载。"
            ;;
        6)
            return
            ;;
        *)
            echo "无效选项，请重新输入。"
            ;;
    esac
    done    
}

# 安装 Xray
install_xray() {
    while true; do
        echo "========================================="
        echo " 安装 Xray "
        echo "========================================="
        echo "1) 安装/升级"
        echo "2) 编辑配置"
        echo "3) 重启服务"
        echo "4) 查看状态"
        echo "5) 卸载服务"
        echo "6) 返回上级菜单"
        echo "========================================="
        read -p "请选择功能 [1-6]: " xray_choice
        case "$xray_choice" in
            1)
                bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install && \
                sudo curl -o /usr/local/etc/xray/config.json "https://raw.githubusercontent.com/XTLS/Xray-examples/refs/heads/main/VLESS-TCP-TLS-WS%20(recommended)/config_server.jsonc"
                echo "Xray 安装/升级完成！"
                ;;
            2)
                sudo nano /usr/local/etc/xray/config.json
                ;;
            3)
                sudo systemctl restart xray
                echo "Xray 已重启。"
                ;;
            4)
                sudo systemctl status xray
                ;;
            5)
                bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove --purge
                echo "Xray 已卸载。"
                ;;
            6)
                return 
                ;;
            *)
                echo "无效选项，请重新输入。"
                ;;
        esac
    done
}

# 安装 hysteria2
install_hysteria2() {
    while true; do    
    echo "========================================="
    echo " 安装 hysteria2 "
    echo "========================================="
    echo "1) 安装/升级"
    echo "2) 编辑配置"
    echo "3) 重启服务"
    echo "4) 查看状态"
    echo "5) 开机自启"
    echo "6) 卸载服务"
    echo "7) 返回主菜单"
    echo "========================================="
    read -p "请选择功能 [1-7]: " hysteria_choice
    case "$hysteria_choice" in
        1)
            bash <(curl -fsSL https://get.hy2.sh/)
            echo "hysteria2 安装/升级完成！"
            ;;
        2)
            sudo nano /etc/hysteria/config.yaml
            ;;
        3)
            sudo systemctl restart hysteria-server.service
            echo "hysteria2 已重启。"
            ;;
        4)
            sudo systemctl status hysteria-server.service
            ;;
        5)
            sudo systemctl enable --now hysteria-server.service
            echo "hysteria2 已设置为开机自启。"
            ;;
        6)
            bash <(curl -fsSL https://get.hy2.sh/) --remove
            echo "hysteria2 已卸载。"
            ;;
        7)
            return
            ;;
        *)
            echo "无效选项，请重新输入。"
            ;;
    esac
    done
}

# 安装 1Panel
install_1panel() {
    while true; do
        echo "========================================="
        echo " 安装 1Panel "
        echo "========================================="
        echo "1) 安装面板"
        echo "2) 安装防火墙"
        echo "3) 卸载面板"
        echo "4) 卸载防火墙"
        echo "5) 卸载 Docker"
        echo "6) 返回主菜单"
        echo "========================================="
        read -p "请选择功能 [1-4]: " panel_choice
        case "$panel_choice" in
            1)
                curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh && sudo bash quick_start.sh
                echo "1Panel 安装完成！"
                ;;
            2)
                sudo apt install ufw
                echo "ufw 安装完成！"
                ;;
            3)
                sudo systemctl stop 1panel && sudo 1pctl uninstall && sudo rm -rf /var/lib/1panel /etc/1panel /usr/local/bin/1pctl && sudo journalctl --vacuum-time=3d
                echo "1Panel 卸载完成！"
                ;;
            4)
                sudo apt remove -y ufw && sudo apt purge -y ufw && sudo apt autoremove -y
                echo "ufw 卸载完成！"
                ;;
            5)
                sudo systemctl stop docker && sudo apt-get purge -y docker-ce docker-ce-cli containerd.io && \
                sudo find / \( -name "docker*" -or -name "containerd*" -or -name "compose*" \) -exec rm -rf {} + && \
                sudo groupdel docker
                echo "Docker 已卸载。"
                ;;
            6)
                return
                ;;
            *)
                echo "无效选项，请重新输入。"
                ;;
    esac
    done    
}

# 主脚本循环
while true; do
    display_main_menu
    read -p "请输入数字 [1-0] 选择功能: " choice
    case "$choice" in
        1) view_vps_info ;;
        2) display_system_optimization_menu ;;
        3) apply_certificate ;;
        4) install_xray ;;
        5) install_hysteria2 ;;
        6) install_1panel ;;
        0)
            echo "退出脚本，感谢使用！"
            exit 0
            ;;
        *)
            echo "无效选项，请输入数字 1-0！"
            ;;
    esac
done
