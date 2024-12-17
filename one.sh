#!/bin/bash
# VPS 管理脚本

# 主菜单函数
display_main_menu() {
    clear
    echo "========================================="
    echo "          VPS 管理脚本          "
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
    # 显示主机信息
    echo -e "\e[1;34m主机名:\e[0m \e[32m$(hostname)\e[0m"
    echo -e "\e[1;34m系统版本:\e[0m \e[32m$(lsb_release -ds 2>/dev/null || grep PRETTY_NAME /etc/os-release | cut -d '"' -f2)\e[0m"
    echo -e "\e[1;34mLinux版本:\e[0m \e[32m$(uname -r)\e[0m"
    echo "-------------"

    # 显示CPU信息
    echo -e "\e[1;34mCPU架构:\e[0m \e[32m$(uname -m)\e[0m"
    echo -e "\e[1;34mCPU型号:\e[0m \e[32m$(lscpu | grep 'Model name' | sed 's/Model name:[ \t]*//')\e[0m"
    echo -e "\e[1;34mCPU核心数:\e[0m \e[32m$(nproc)\e[0m"
    echo -e "\e[1;34mCPU频率:\e[0m \e[32m$(lscpu | grep 'CPU MHz' | awk -F: '{print $2}' | xargs) MHz\e[0m"
    echo "-------------"

    # 显示系统资源信息
    echo -e "\e[1;34mCPU占用:\e[0m \e[32m$(top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}')%\e[0m"
    echo -e "\e[1;34m系统负载:\e[0m \e[32m$(uptime | awk -F'load average:' '{print $2}' | sed 's/ //g')\e[0m"
    
    # 物理内存处理
    mem_info=$(free -m | awk '/Mem:/ {total=$2; used=$3; if (total > 0) printf "%.2f/%.2f MB (%.2f%%)", used, total, used*100/total; else print "数据不可用"}')
    echo -e "\e[1;34m物理内存:\e[0m \e[32m$mem_info \e[0m"
    
    # 虚拟内存处理
    swap_info=$(free -m | awk '/Swap:/ {total=$2; used=$3; if (total > 0) printf "%.0fMB/%.0fMB (%.0f%%)", used, total, used*100/total; else print "数据不可用" }')
    echo -e "\e[1;34m虚拟内存:\e[0m \e[32m$swap_info\e[0m"
     
    echo -e "\e[1;34m硬盘占用:\e[0m \e[32m$(df -h / | awk '/\// {print $3 "/" $2 " (" $5 ")"}')\e[0m"
    echo "-------------"

    # 显示网络信息
    NET_INTERFACE=$(ip -o link show | awk -F': ' '$2 != "lo" {print $2}' | head -n 1)
    if [ -n "$NET_INTERFACE" ]; then
        RX_BYTES=$(cat /sys/class/net/$NET_INTERFACE/statistics/rx_bytes)
        TX_BYTES=$(cat /sys/class/net/$NET_INTERFACE/statistics/tx_bytes)
        RX_MB=$(awk "BEGIN {printf \"%.2f\", $RX_BYTES / 1024 / 1024}")
        TX_MB=$(awk "BEGIN {printf \"%.2f\", $TX_BYTES / 1024 / 1024}")
        echo -e "\e[1;34m网络接口:\e[0m \e[32m$NET_INTERFACE\e[0m"
        echo -e "\e[1;34m总接收:\e[0m \e[32m${RX_MB} MB\e[0m"
        echo -e "\e[1;34m总发送:\e[0m \e[32m${TX_MB} MB\e[0m"
    else
        echo -e "\e[1;31m未检测到有效的网络接口！\e[0m"
    fi
    echo "-------------"

    # 显示网络协议
    echo -e "\e[1;34m网络算法:\e[0m \e[32m$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')\e[0m"
    echo "-------------"

    # 显示运营商和地理位置
    echo -e "\e[1;34m运营商:\e[0m \e[32m$(curl -s ipinfo.io/org | sed 's/^ *//;s/ *$//')\e[0m"
    echo -e "\e[1;34mIPv4地址:\e[0m \e[32m$(curl -s ipv4.icanhazip.com)\e[0m"
    echo -e "\e[1;34mDNS地址:\e[0m \e[32m$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | xargs | sed 's/ /, /g')\e[0m"
    echo -e "\e[1;34m地理位置:\e[0m \e[32m$(curl -s ipinfo.io/city), $(curl -s ipinfo.io/country)\e[0m"
    echo -e "\e[1;34m系统时间:\e[0m \e[32m$(timedatectl | grep 'Local time' | awk '{print $3, $4, $5}')\e[0m"
    echo "-------------"

    # 显示系统运行时长
    echo -e "\e[1;34m运行时长:\e[0m \e[32m$(uptime -p | sed 's/up //')\e[0m"
    echo "-------------"

    # 等待用户输入
    read -n 1 -s -r -p "按任意键返回菜单..."
}

# 系统优化
display_system_optimization_menu() {
    while true; do
        echo "========================================="
        echo "          系统优化          "
        echo "========================================="
        echo "1) 校准时间"
        echo "2) 更新系统"
        echo "3) 清理系统"
        echo "4) 开启BBR"
        echo "5) ROOT登录"
        echo "6) 返回主菜单"
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
    read -n 1 -s -r -p "按任意键返回菜单..."
}

# 系统更新
update_system() {
    echo -e "\n[更新系统]"
    sudo apt update -y && sudo apt full-upgrade -y
    sudo apt autoremove -y && sudo apt autoclean -y
    echo "系统更新完成！"
    read -n 1 -s -r -p "按任意键返回菜单..."
}

# 系统清理
clean_system() {
    echo -e "\n[清理系统]"
    sudo apt autoremove --purge -y
    sudo apt clean -y && sudo apt autoclean -y
    sudo journalctl --rotate && sudo journalctl --vacuum-time=10m
    sudo journalctl --vacuum-size=50M
    echo "系统清理完成！"
    read -n 1 -s -r -p "按任意键返回菜单..."
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
    read -n 1 -s -r -p "按任意键返回菜单..."
}

# ROOT登录
root_login() {
    while true; do
        echo "========================================="
        echo "          ROOT 登录          "
        echo "========================================="
        echo "1) 设置密码"
        echo "2) 编辑配置：修改 PermitRootLogin 与 PasswordAuthentication 为 yes"
        echo "3) 重启服务"
        echo "4) 返回上级菜单"
        echo "========================================="
        read -p "请选择功能 [1-4]: " root_choice
        case "$root_choice" in
            1) sudo passwd root ;;
            2) sudo nano /etc/ssh/sshd_config ;;
            3)
              sudo systemctl restart sshd.service
              echo "ROOT 登录开启成功"
              read -n 1 -s -r -p "按任意键返回菜单..."
              return
              ;;
            4) return ;;
            *) echo "无效选项，请重新输入。" ;;
        esac
    done
}

# 申请证书
apply_certificate() {
    while true; do
        echo "========================================="
        echo "          申请证书          "
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
                # Check if cron is installed
                if ! command -v crontab &> /dev/null; then
                    echo "正在检测 cron 是否安装..."
                    # Install cron based on the OS (using a basic check)
                    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
                        if command -v apt &> /dev/null; then
                            sudo apt update
                            sudo apt install -y cron
                        elif command -v yum &> /dev/null; then
                            sudo yum install -y cronie
                            sudo systemctl enable crond
                            sudo systemctl start crond
                        elif command -v dnf &> /dev/null; then
                             sudo dnf install -y cronie
                             sudo systemctl enable crond
                             sudo systemctl start crond
                        else
                            echo "不支持的包管理器，请手动安装 cron。"
                            continue
                        fi
                    else
                      echo "不支持的操作系统，请手动安装 cron。"
                      continue
                    fi
                    echo "cron 安装完成。"
                fi
                
                curl https://get.acme.sh | sh -s email="$email"
                echo "acme.sh 安装完成！"
                ;;
            2)
                read -p "请输入域名: " domain
                ~/.acme.sh/acme.sh --issue --standalone -d "$domain"
                echo "证书申请完成！"
                ;;
            3)
                ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
                echo "已切换至 Let's Encrypt 服务。"
                ;;
            4)
                read -p "请输入域名: " domain
                mkdir -p /path/to && \
                ~/.acme.sh/acme.sh --installcert -d $domain \
                    --key-file /path/to/private.key --fullchain-file /path/to/fullchain.crt && \
                sudo chmod 644 /path/to/fullchain.crt /path/to/private.key
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
        echo "          安装 Xray          "
        echo "========================================="
        echo "1) 安装/升级"
        echo "2) 编辑配置：写入UUID"
        echo "3) 重启服务"
        echo "4) 卸载服务"
        echo "5) 返回主菜单"
        echo "========================================="
        read -p "请选择功能 [1-5]: " xray_choice
        case "$xray_choice" in
            1)
                bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install && \
                    sudo curl -o /usr/local/etc/xray/config.json "https://raw.githubusercontent.com/XTLS/Xray-examples/refs/heads/main/VLESS-TCP-TLS-WS%20(recommended)/config_server.jsonc" && \
                echo "Xray 安装/升级完成！以下是uuid："
                xray uuid
                ;;
            2)
                sudo nano /usr/local/etc/xray/config.json
                ;;
            3)
                sudo systemctl restart xray && \
                sudo systemctl status xray
                ;;
            4)
                bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove --purge
                echo "Xray 已卸载。"
                ;;
            5)
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
        echo "          安装 hysteria2          "
        echo "========================================="
        echo "1) 安装/升级"
        echo "2) 编辑配置"
        echo "3) 重启服务"
        echo "4) 卸载服务"
        echo "5) 返回主菜单"
        echo "========================================="
        read -p "请选择功能 [1-5]: " hysteria_choice
        case "$hysteria_choice" in
            1)
                bash <(curl -fsSL https://get.hy2.sh/) && \
                sudo systemctl enable --now hysteria-server.service && \
                sysctl -w net.core.rmem_max=16777216
                sysctl -w net.core.wmem_max=16777216
                echo "hysteria2 安装/升级完成！"
                ;;
            2)
                sudo nano /etc/hysteria/config.yaml
                ;;
            3)
                sudo systemctl restart hysteria-server.service && \
                sudo systemctl status hysteria-server.service
                ;;
            4)
                bash <(curl -fsSL https://get.hy2.sh/) --remove && \
                rm -rf /etc/hysteria
                userdel -r hysteria
                rm -f /etc/systemd/system/multi-user.target.wants/hysteria-server.service
                rm -f /etc/systemd/system/multi-user.target.wants/hysteria-server@*.service
                systemctl daemon-reload                
                echo "hysteria2 已卸载。"
                ;;
            5)
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
        echo "          安装 1Panel          "
        echo "========================================="
        echo "1) 安装面板"
        echo "2) 安装防火墙"
        echo "3) 卸载防火墙"
        echo "4) 卸载面板"
        echo "5) 返回主菜单"
        echo "========================================="
        read -p "请选择功能 [1-5]: " panel_choice
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
                sudo apt remove -y ufw && sudo apt purge -y ufw && sudo apt autoremove -y
                echo "ufw 卸载完成！"
                ;;
            4)
                sudo systemctl stop 1panel && sudo 1pctl uninstall && sudo rm -rf /var/lib/1panel /etc/1panel /usr/local/bin/1pctl && sudo journalctl --vacuum-time=3d
                sudo systemctl stop docker && sudo apt-get purge -y docker-ce docker-ce-cli containerd.io && \
                    sudo find / \( -name "1panel*" -or -name "docker*" -or -name "containerd*" -or -name "compose*" \) -exec rm -rf {} + && \
                    sudo groupdel docker
                echo "1Panel 卸载完成！"
                ;;
            5)
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
