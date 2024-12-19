#!/bin/bash
# VPS 管理脚本

# -----------------------------------------------------------------------------
# 函数定义
# -----------------------------------------------------------------------------

# 主菜单函数
display_main_menu() {
    clear
    echo "========================================="
    echo -e "               \e[1;96mVPS管理脚本\e[0m"
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
    echo -e "\e[1;34m主机名:\e[0m \e[32m$(hostname)\e[0m"
    echo -e "\e[1;34m系统版本:\e[0m \e[32m$(lsb_release -ds 2>/dev/null || grep PRETTY_NAME /etc/os-release | cut -d '"' -f2)\e[0m"
    echo -e "\e[1;34mLinux版本:\e[0m \e[32m$(uname -r)\e[0m"
    echo "-------------"
    echo -e "\e[1;34mCPU架构:\e[0m \e[32m$(uname -m)\e[0m"
    echo -e "\e[1;34mCPU型号:\e[0m \e[32m$(lscpu | grep 'Model name' | sed 's/Model name:[ \t]*//')\e[0m"
    echo -e "\e[1;34mCPU核心数:\e[0m \e[32m$(nproc)\e[0m"
    echo -e "\e[1;34mCPU频率:\e[0m \e[32m$(lscpu | grep 'CPU MHz' | awk -F: '{print $2}' | xargs) MHz\e[0m"
    echo "-------------"
    echo -e "\e[1;34mCPU占用:\e[0m \e[32m$(top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}')%\e[0m"
    echo -e "\e[1;34m系统负载:\e[0m \e[32m$(uptime | awk -F'load average:' '{print $2}' | sed 's/ //g')\e[0m"
    local mem_info=$(free -m | awk '/Mem:/ {total=$2; used=$3; if (total > 0) printf "%.2f/%.2f MB (%.2f%%)", used, total, used*100/total; else print "数据不可用"}')
    echo -e "\e[1;34m物理内存:\e[0m \e[32m$mem_info \e[0m"
    local swap_info=$(free -m | awk '/Swap:/ {total=$2; used=$3; if (total > 0) printf "%.0fMB/%.0fMB (%.0f%%)", used, total, used*100/total; else print "数据不可用" }')
    echo -e "\e[1;34m虚拟内存:\e[0m \e[32m$swap_info\e[0m"
     
    echo -e "\e[1;34m硬盘占用:\e[0m \e[32m$(df -h / | awk '/\// {print $3 "/" $2 " (" $5 ")"}')\e[0m"
    echo "-------------"
    local NET_INTERFACE=$(ip -o link show | awk -F': ' '$2 != "lo" {print $2}' | head -n 1)
    if [ -n "$NET_INTERFACE" ]; then
        local RX_BYTES=$(cat /sys/class/net/$NET_INTERFACE/statistics/rx_bytes)
        local TX_BYTES=$(cat /sys/class/net/$NET_INTERFACE/statistics/tx_bytes)
        local RX_MB=$(awk "BEGIN {printf \"%.2f\", $RX_BYTES / 1024 / 1024}")
        local TX_MB=$(awk "BEGIN {printf \"%.2f\", $TX_BYTES / 1024 / 1024}")
        echo -e "\e[1;34m网络接口:\e[0m \e[32m$NET_INTERFACE\e[0m"
        echo -e "\e[1;34m总接收:\e[0m \e[32m${RX_MB} MB\e[0m"
        echo -e "\e[1;34m总发送:\e[0m \e[32m${TX_MB} MB\e[0m"
    else
        echo -e "\e[1;31m未检测到有效的网络接口！\e[0m"
    fi
    echo "-------------"
    echo -e "\e[1;34m网络算法:\e[0m \e[32m$(sysctl net.ipv4.tcp_congestion_control | awk '{print $3}')\e[0m"
    echo "-------------"
    echo -e "\e[1;34m运营商:\e[0m \e[32m$(curl -s ipinfo.io/org | sed 's/^ *//;s/ *$//')\e[0m"
    echo -e "\e[1;34mIPv4地址:\e[0m \e[32m$(curl -s ipv4.icanhazip.com)\e[0m"
    echo -e "\e[1;34mDNS地址:\e[0m \e[32m$(cat /etc/resolv.conf | grep nameserver | awk '{print $2}' | xargs | sed 's/ /, /g')\e[0m"
    echo -e "\e[1;34m地理位置:\e[0m \e[32m$(curl -s ipinfo.io/city), $(curl -s ipinfo.io/country)\e[0m"
    echo -e "\e[1;34m系统时间:\e[0m \e[32m$(timedatectl | grep 'Local time' | awk '{print $3, $4, $5}')\e[0m"
    echo "-------------"
    echo -e "\e[1;34m运行时长:\e[0m \e[32m$(uptime -p | sed 's/up //')\e[0m"
    echo "-------------"
    read -n 1 -s -r -p "按任意键返回..."
}

# 系统优化
display_system_optimization_menu() {
    while true; do
        echo "========================================="
    echo -e "               \e[1;32m系统优化\e[0m       "
        echo "========================================="
        echo "1) 校准时间"
        echo "2) 更新系统"
        echo "3) 清理系统"
        echo "4) 开启BBR"
        echo "5) ROOT登录"
        echo "0) 返回主菜单"
        echo "========================================="
        read -p "请选择功能 [1-0]: " opt_choice
        case "$opt_choice" in
            1) calibrate_time ;;
            2) update_system ;;
            3) clean_system ;;
            4) enable_bbr ;;
            5) root_login ;;
            0) return ;;
            *) echo "无效选项，请重新输入。" ;;
        esac
    done
}

# 时间校准
calibrate_time() {
    echo -e "\n[校准时间]"
    sudo timedatectl set-timezone Asia/Shanghai
    sudo timedatectl set-ntp true
    echo -e "\e[32m时间校准完成，当前时区为 Asia/Shanghai。\e[0m"
    read -n 1 -s -r -p "按任意键返回..."
    echo
}

# 系统更新
update_system() {
    echo -e "\n[更新系统]"
    sudo apt update -y && sudo apt full-upgrade -y
    sudo apt autoremove -y && sudo apt autoclean -y
    echo -e "\e[32m系统更新完成！\e[0m"
    read -n 1 -s -r -p "按任意键返回..."
    echo
}

# 系统清理
clean_system() {
    echo -e "\n[清理系统]"
    sudo apt autoremove --purge -y
    sudo apt clean -y && sudo apt autoclean -y
    sudo journalctl --rotate && sudo journalctl --vacuum-time=10m
    sudo journalctl --vacuum-size=50M
    echo -e "\e[32m系统清理完成！\e[0m"
    read -n 1 -s -r -p "按任意键返回..."
    echo
}

# 开启 BBR
enable_bbr() {
    echo -e "\n[开启BBR]"
    if sysctl net.ipv4.tcp_congestion_control | grep -q 'bbr'; then
    echo -e "\e[32mBBR已开启！\e[0m"
    else
        echo "net.core.default_qdisc = fq" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv4.tcp_congestion_control = bbr" | sudo tee -a /etc/sysctl.conf
        sudo sysctl -p
    echo -e "\e[32mBBR已开启！\e[0m"
    fi
    read -n 1 -s -r -p "按任意键返回..."
    echo
}

# ROOT登录
root_login() {
    while true; do
        echo "========================================="
        echo -e "               \e[1;34mROOT登录\e[0m   "
        echo "========================================="
        echo "1) 设置密码"
        echo "2) 编辑配置（修改 PermitRootLogin 与 PasswordAuthentication 为 yes）"
        echo "3) 重启服务"
        echo "0) 返回上级菜单"
        echo "========================================="
        read -p "请选择功能 [1-0]: " root_choice
        case "$root_choice" in
            1) sudo passwd root ;;
            2) 
                sudo nano /etc/ssh/sshd_config 
                read -n 1 -s -r -p "按任意键返回..."
                ;;
            3)
                sudo systemctl restart sshd.service
                read -n 1 -s -r -p "按任意键返回..."
                ;;
            0) return ;;
            *) echo "无效选项，请重新输入。" ;;
        esac
    done
}

# 申请证书
apply_certificate() {
    while true; do
        echo "========================================="
        echo -e "               \e[1;32m申请证书\e[0m     "
        echo "========================================="
        echo "1) 安装脚本"
        echo "2) 申请证书"
        echo "3) 更换服务器"
        echo "4) 安装证书"
        echo "5) 卸载脚本"
        echo "0) 返回主菜单"
        echo "========================================="
        read -p "请选择功能 [1-0]: " cert_choice
        case "$cert_choice" in
            1)
                read -p "请输入邮箱地址: " email
                # Check if cron is installed
                if ! command -v crontab &> /dev/null; then
                    echo "正在检测cron是否安装..."
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
                            echo "不支持的包管理器，请手动安装cron。"
                            continue
                        fi
                    else
                      echo "不支持的操作系统，请手动安装cron。"
                      continue
                    fi
                    echo "cron安装完成。"
                fi
                curl https://get.acme.sh | sh -s email="$email"
                echo -e "\e[32macme.sh 安装完成！\e[0m"
                read -n 1 -s -r -p "按任意键返回..."
                echo
                ;;
            2)
                read -p "请输入域名: " domain
                ~/.acme.sh/acme.sh --issue --standalone -d "$domain"
                echo -e "\e[32m证书申请完成！\e[0m"
                read -n 1 -s -r -p "按任意键返回..."
                echo
                ;;
            3)
                ~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
                echo -e "\e[32m已切换至Let's Encrypt服务！\e[0m"
                read -n 1 -s -r -p "按任意键返回..."
                echo
                ;;
            4)
                read -p "请输入域名: " domain
                read -p "请输入证书安装路径（默认: /path/to）: " install_path
                install_path=${install_path:-/path/to}
                mkdir -p "$install_path" && \
                ~/.acme.sh/acme.sh --installcert -d "$domain" \
    --key-file "$install_path/private.key" --fullchain-file "$install_path/fullchain.crt" && \
                sudo chmod 644 "$install_path/fullchain.crt" "$install_path/private.key"
                if [[ $? -eq 0 ]]; then
                echo -e "\e[32m证书安装完成！路径: $install_path\e[0m"
                else
                echo "证书安装失败，请检查输入。"
                fi
                read -n 1 -s -r -p "按任意键返回..."
                echo
                ;;
            5)
                ~/.acme.sh/acme.sh --uninstall
                echo -e "\e[32macme.sh已卸载。\e[0m"
                read -n 1 -s -r -p "按任意键返回..."
                echo
                ;;
            0)
                return
                ;;
            *)
                echo "无效选项，请重新输入。"
                ;;
        esac
    done
}

# 安装Xray
install_xray() {
    while true; do
        echo "========================================="
    echo -e "               \e[1;32m安装Xray\e[0m       "
        echo "========================================="
        echo "1) VLESS-WS-TLS"
        echo "2) VLESS-TCP-REALITY"
        echo "0) 返回主菜单"
        echo "========================================="
        read -p "请选择功能 [1-0]: " opt_choice
        case "$opt_choice" in
            1) install_xray_tls ;;
            2) install_xray_reality ;;
            0) return ;;
            *) echo "无效选项，请重新输入。" ;;
        esac
    done
}

# 安装VLESS-WS-TLS
install_xray_tls() {
    while true; do
        echo "========================================="
        echo -e "               \e[1;34mVLESS-WS-TLS\e[0m   "
        echo "========================================="
        echo "1) 安装/升级"
        echo "2) 编辑配置（添加UUID）"
        echo "3) 重启服务"
        echo "4) 生成链接"
        echo "5) 卸载服务"
        echo "0) 返回主菜单"
        echo "========================================="
        read -p "请选择功能 [1-0]: " xray_choice
        case "$xray_choice" in
            1)
                bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install && \
                    sudo curl -o /usr/local/etc/xray/config.json "https://raw.githubusercontent.com/XTLS/Xray-examples/refs/heads/main/VLESS-TCP-TLS-WS%20(recommended)/config_server.jsonc" && \
                echo -e "\e[32mXray 安装/升级完成！以下是uuid：\e[0m"
                echo -e "\e[31m$(xray uuid)\e[0m"
                read -n 1 -s -r -p "按任意键返回..."
                echo
                ;;
            2)
                sudo nano /usr/local/etc/xray/config.json
                read -n 1 -s -r -p "按任意键返回..."
                echo
                ;;
            3)
                sudo systemctl restart xray && \
                sudo systemctl status xray
                ;;
            4)
                CONFIG_PATH="/usr/local/etc/xray/config.json"
                extract_field() {
                    local pattern=$1
                    local match=$2
                    grep -aPo "\"$pattern\":\s*$match" "$CONFIG_PATH" | head -n 1 | sed -E "s/\"$pattern\":\s*//;s/^\"//;s/\"$//"
}
                extract_list_field() {
                    local list_parent=$1
                    local list_field=$2
                    grep -aPoz "\"$list_parent\":\s*\[\s*\{[^}]*\}\s*\]" "$CONFIG_PATH" | grep -aPo "\"$list_field\":\s*\"[^\"]*\"" | head -n 1 | sed -E "s/\"$list_field\":\s*\"([^\"]*)\"/\1/"
}
                get_domain_from_cert() {
                    local cert_file=$1
                    openssl x509 -in "$cert_file" -text -noout | grep -aPo "DNS:[^,]*" | sed 's/DNS://' | head -n 1 ||
                    openssl x509 -in "$cert_file" -text -noout | grep -aPo "CN=[^ ]*" | sed 's/CN=//'
}
                get_public_ip() {
                    curl -s https://api.ipify.org || echo "127.0.0.1"
}
                UUID=$(extract_list_field "clients" "id")
                PORT=$(extract_field "port" "\d+")
                WS_PATH=$(extract_field "path" "\"[^\"]*\"")
                TLS=$(extract_field "security" "\"[^\"]*\"")
                CERT_PATH=$(extract_list_field "certificates" "certificateFile")
                if [[ -z "$CERT_PATH" ]]; then
                    echo "Error: CERT_PATH not found in config.json"
                    exit 1
                fi
                DOMAIN=$(get_domain_from_cert "$CERT_PATH")
                SNI=${DOMAIN:-"your.domain.net"}
                HOST=${DOMAIN:-"your.domain.net"}
                ADDRESS=$(get_public_ip)
                WS_PATH=${WS_PATH:-"/"}
                TLS=${TLS:-"tls"}
                PORT=${PORT:-"443"}
                vless_uri="vless://${UUID}@${ADDRESS}:${PORT}?encryption=none&security=${TLS}&sni=${SNI}&type=ws&host=${HOST}&path=${WS_PATH}#Xray"
                echo -e "\e[32mVLESS链接如下：\e[0m"
                echo -e "\e[93m$vless_uri\e[0m"
                read -n 1 -s -r -p "按任意键返回..."
                echo
                ;;
            5)
                bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove --purge
                echo -e "\e[32mXray已卸载。\e[0m"
                read -n 1 -s -r -p "按任意键返回..."
                echo
                ;;
            0)
                return 
                ;;
            *)
                echo "无效选项，请重新输入。"
                ;;
        esac
    done
}

# 安装VLESS-TCP-REALITY
install_xray_reality() {
    while true; do
        echo "========================================="
        echo -e "               \e[1;34mVLESS-TCP-REALITY\e[0m   "
        echo "========================================="
        echo "1) 安装/升级"
        echo "2) 编辑配置（添加UUID、域名及私钥）"
        echo "3) 重启服务"
        echo "4) 生成链接"
        echo "5) 卸载服务"
        echo "0) 返回主菜单"
        echo "========================================="
        read -p "请选择功能 [1-0]: " xray_choice
        case "$xray_choice" in
            1)
                bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install && \
                    sudo curl -o /usr/local/etc/xray/config.json "https://raw.githubusercontent.com/XTLS/Xray-examples/refs/heads/main/VLESS-TCP-XTLS-Vision-REALITY/config_server.jsonc" && \
                echo -e "\e[32mXray 安装/升级完成！"
                echo -e "\e[32m以下是UUID：\e[0m"
                echo -e "\e[31m$(xray uuid)\e[0m"
                echo -e "\e[32m以下是私钥：\e[0m"
                keys=$(xray x25519)
                export PRIVATE_KEY=$(echo "$keys" | head -n 1 | awk '{print $3}' | sed 's/^-//')
                export PUBLIC_KEY=$(echo "$keys" | tail -n 1 | awk '{print $3}' | sed 's/^-//')
                echo -e "\e[33m$PRIVATE_KEY\e[0m"                
                echo -e "\e[32m以下是shortIds：\e[0m"                
                echo -e "\e[34m$(openssl rand -hex 8)\e[0m"
                read -n 1 -s -r -p "按任意键返回..."
                echo
                ;;
            2)
                sudo nano /usr/local/etc/xray/config.json
                read -n 1 -s -r -p "按任意键返回..."
                echo
                ;;
            3)
                sudo systemctl restart xray && \
                sudo systemctl status xray
                ;;
            4)
                CONFIG_PATH="/usr/local/etc/xray/config.json"
                remove_spaces_and_quotes() {
                    echo "$1" | sed 's/[[:space:]]*$//;s/^ *//;s/^"//;s/"$//'
}
                extract_field() {
                    local pattern=$1
                    local match=$2
                    grep -aPo "\"$pattern\":\s*$match" "$CONFIG_PATH" | head -n 1 | sed -E "s/\"$pattern\":\s*//;s/^\"//;s/\"$//"
}
                extract_server_name() {
                    local result=$(grep -aA 2 "\"serverNames\": \[" "$CONFIG_PATH" | awk 'NR==2{gsub(/^\s+|\s*\/\/.*$/,"");split($0,a,","); for (i in a) {gsub(/^[\"\s]+|[\"\s]+$/,"",a[i]);printf "%s ",a[i]}}')
                    if [[ -n "$result" ]]; then
                        remove_spaces_and_quotes "$result"
                    fi
}
                extract_list_field() {
                    local list_parent=$1
                    local list_field=$2
                    if [[ "$list_field" == "shortIds" || "$list_field" == "serverNames" ]]; then
                        local result=$(grep -aA 2 "\"$list_field\": \[" "$CONFIG_PATH" | awk 'NR==2{gsub(/^\s+|\s*\/\/.*$/,"");split($0,a,","); for (i in a) {gsub(/^[\"\s]+|[\"\s]+$/,"",a[i]);printf "%s ",a[i]}}')
                        if [[ -n "$result" ]]; then
                            remove_spaces_and_quotes "$result"
                        fi
                    else
                        grep -aPoz "\"$list_parent\":\s*\[\s*\{[^}]*\}\s*\]" "$CONFIG_PATH" | grep -aPo "\"$list_field\":\s*\"[^\"]*\"" | head -n 1 | sed -E "s/\"$list_field\":\s*\"([^\"]*)\"/\1/"
                    fi
}
                get_public_ip() {
                    curl -s https://api.ipify.org || echo "127.0.0.1"
}
                UUID=$(extract_list_field "clients" "id")
                PORT=$(extract_field "port" "\d+")
                TLS=$(extract_field "security" "\"[^\"]*\"")
                SERVER_NAME=$(extract_server_name)
                SHORT_IDS=$(extract_list_field "realitySettings" "shortIds")
                SNI=${SERVER_NAME:-"your.domain.net"}
                ADDRESS=$(get_public_ip)
                PORT=${PORT:-"443"}
                FLOW=$(extract_field "flow" "\"[^\"]*\"")
                SID=${SHORT_IDS:-""}
                vless_uri="vless://${UUID}@${ADDRESS}:${PORT}?encryption=none&flow=${FLOW}&security=reality&sni=${SNI}&fp=chrome&sid=${SID}&type=tcp&headerType=none#Xray"
                echo -e "\e[32mVLESS链接如下：\e[0m"
                echo -e "\e[93m$vless_uri\e[0m"
                echo -e "\e[32m以下是公钥：\e[0m"
                echo -e "\e[33m$PUBLIC_KEY\e[0m"                
                read -n 1 -s -r -p "按任意键返回..."
                echo
                ;;
            5)
                bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ remove --purge
                echo -e "\e[32mXray已卸载。\e[0m"
                read -n 1 -s -r -p "按任意键返回..."
                echo
                ;;
            0)
                return 
                ;;
            *)
                echo "无效选项，请重新输入。"
                ;;
        esac
    done
}

# 安装hysteria2
install_hysteria2() {
    while true; do    
        echo "========================================="
        echo -e "           \e[1;32m安装hysteria2\e[0m  "
        echo "========================================="
        echo "1) 安装/升级"
        echo "2) 编辑配置（添加域名）"
        echo "3) 重启服务"
        echo "4) 生成链接"        
        echo "5) 端口跳跃"
        echo "6) 卸载服务"
        echo "0) 返回主菜单"
        echo "========================================="
        read -p "请选择功能 [1-0]: " hysteria_choice
        case "$hysteria_choice" in
            1)
                bash <(curl -fsSL https://get.hy2.sh/) && \
                sudo systemctl enable --now hysteria-server.service && \
                sysctl -w net.core.rmem_max=16777216
                sysctl -w net.core.wmem_max=16777216
                echo -e "\e[32mhysteria2 安装/升级完成！\e[0m"
                read -n 1 -s -r -p "按任意键返回..."
                echo
                ;;
            2)
                sudo nano /etc/hysteria/config.yaml
                read -n 1 -s -r -p "按任意键返回..."
                echo
                ;;
            3)
                sudo systemctl restart hysteria-server.service && \
                sudo systemctl status hysteria-server.service
                ;;
            4)
                config_file="/etc/hysteria/config.yaml"
                get_domain_from_cert() {
                    local cert_file=$1
                    openssl x509 -in "$cert_file" -text -noout | grep -Po "DNS:[^,]*" | head -n 1 | sed 's/DNS://' ||
                    openssl x509 -in "$cert_file" -text -noout | grep -Po "CN=[^ ]*" | sed 's/CN=//'
}
                if [ ! -f "$config_file" ]; then
                    echo "Error: Config file not found at $config_file"
                    exit 1
                fi
                port=$(grep "^listen:" "$config_file" | awk -F: '{print $3}' || echo "443")
                password=$(grep "^  password:" "$config_file" | awk '{print $2}')
                domain=$(grep "domains:" "$config_file" -A 1 | tail -n 1 | tr -d " -")
                if [ -z "$domain" ]; then
                    cert_path=$(grep "cert:" "$config_file" | awk '{print $2}' | tr -d '"')
                    if [ -z "$cert_path" ] || [ ! -f "$cert_path" ]; then
                        echo "Error: No domain or certificate path found or certificate file not found."
                        exit 1
                    fi
                    domain=$(get_domain_from_cert "$cert_path")
                    if [ -z "$domain" ]; then
                        echo "Error: Failed to extract domain from certificate"
                        exit 1
                    fi
                fi
                hysteria2_uri="hysteria2://$password@$domain:$port?insecure=0#hysteria"
                echo -e "\e[32mhysteria2 链接如下：\e[0m"
                echo -e "\e[93m$hysteria2_uri\e[0m"
                read -n 1 -s -r -p "按任意键返回..."
                echo
                ;;
            5)
                default_redirect_port=443
                default_start_port=60000
                default_end_port=65535
                config_file="/etc/hysteria/config.yaml"
                redirect_port=$(
                if [[ -f "$config_file" ]]; then
                    grep 'listen:' "$config_file" | awk -F':' '{print $NF}'
                fi
)
                [[ -z "$redirect_port" || ! "$redirect_port" =~ ^[0-9]+$ || "$redirect_port" -lt 1 || "$redirect_port" -gt 65535 ]] && redirect_port="$default_redirect_port"
                read -p "请输入起始端口号 (按 Enter 使用默认值 60000): " start_port
                [[ -z "$start_port" ]] && start_port="$default_start_port"
                [[ "$start_port" =~ ^[0-9]+$ && "$start_port" -ge 1 && "$start_port" -le 65535 ]] || { echo "起始端口号无效, 使用默认值 60000"; start_port="$default_start_port"; }
                read -p "请输入结束端口号 (按 Enter 使用默认值 65535): " end_port
                [[ -z "$end_port" ]] && end_port="$default_end_port"
                [[ "$end_port" =~ ^[0-9]+$ && "$end_port" -ge 1 && "$end_port" -le 65535 && "$end_port" -ge "$start_port" ]] || { echo "结束端口号无效，使用默认值 65535"; end_port="$default_end_port"; }
                interfaces=($(ip -o link | awk -F': ' '{if ($2 != "lo") print $2}'))
                [[ ${#interfaces[@]} -eq 0 ]] && { echo "未找到网络接口，无法执行 iptables 命令。"; exit 1; }
                selected_interface="${interfaces[0]}"
                iptables_command="iptables -t nat -A PREROUTING -i $selected_interface -p udp --dport $start_port:$end_port -j REDIRECT --to-ports $redirect_port"
                if eval "$iptables_command"; then
                echo -e "\e[32m端口跳跃设置成功!\e[0m"
                else
                echo "iptables命令执行失败。"
                exit 1
                fi
                read -n 1 -s -r -p "按任意键返回..."
                echo
                ;;
            6)
                bash <(curl -fsSL https://get.hy2.sh/) --remove && \
                rm -rf /etc/hysteria
                userdel -r hysteria
                rm -f /etc/systemd/system/multi-user.target.wants/hysteria-server.service
                rm -f /etc/systemd/system/multi-user.target.wants/hysteria-server@*.service
                systemctl daemon-reload                
                echo -e "\e[32mhysteria2 已卸载。\e[0m"
                read -n 1 -s -r -p "按任意键返回..."
                echo
                ;;
            0)
                return
                ;;
            *)
                echo "无效选项，请重新输入。"
                ;;
        esac
    done
}

# 安装1Panel
install_1panel() {
    while true; do
        echo "========================================="
        echo -e "               \e[1;32m安装1Panel\e[0m "
        echo "========================================="
        echo "1) 安装面板"
        echo "2) 安装防火墙"
        echo "3) 卸载防火墙"
        echo "4) 卸载面板"
        echo "0) 返回主菜单"
        echo "========================================="
        read -p "请选择功能 [1-0]: " panel_choice
        case "$panel_choice" in
            1)
                curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh && sudo bash quick_start.sh
                echo -e "\e[32m1Panel安装完成！\e[0m"
                read -n 1 -s -r -p "按任意键返回..."
                echo
                ;;
            2)
                sudo apt install ufw
                echo -e "\e[32mufw安装完成！\e[0m"
                read -n 1 -s -r -p "按任意键返回..."
                echo
                ;;
            3)
                sudo apt remove -y ufw && sudo apt purge -y ufw && sudo apt autoremove -y
                echo -e "\e[32mufw卸载完成。\e[0m"
                read -n 1 -s -r -p "按任意键返回..."
                echo
                ;;
            4)
                sudo systemctl stop 1panel && sudo 1pctl uninstall && sudo rm -rf /var/lib/1panel /etc/1panel /usr/local/bin/1pctl && sudo journalctl --vacuum-time=3d
                sudo systemctl stop docker && sudo apt-get purge -y docker-ce docker-ce-cli containerd.io && \
                    sudo find / \( -name "1panel*" -or -name "docker*" -or -name "containerd*" -or -name "compose*" \) -exec rm -rf {} + && \
                    sudo groupdel docker
                echo -e "\e[32m1Panel卸载完成。\e[0m"
                read -n 1 -s -r -p "按任意键返回..."
                echo
                ;;
            0)
                return
                ;;
            *)
                echo "无效选项，请重新输入。"
                ;;
        esac
    done    
}

# -----------------------------------------------------------------------------
# 主脚本循环
# -----------------------------------------------------------------------------

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
            echo -e "\e[32m退出脚本，感谢使用！\e[0m"
            exit 0
            ;;
        *)
            echo "无效选项，请输入数字 1-0！"
            ;;
    esac
done
