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
    echo "9) 退出脚本"
    echo "========================================="
}

# 系统配置查看
view_vps_info() {
    echo "\n[系统配置]"
    echo "================= 操作系统和内核 ================="
    lsb_release -a 2>/dev/null || cat /etc/*release
    uname -a

    echo "\n================= CPU 信息 ================="
    lscpu | grep -E 'Model name|Socket|Core|Thread|CPU MHz|Architecture'

    echo "\n================= 内存信息 ================="
    free -h

    echo "\n================= 磁盘信息 ================="
    df -hT --total | grep -v tmpfs

    echo "\n================= 网络信息 ================="
    ip addr show
    echo "公共 IP 地址：$(curl -s https://api.ipify.org)"

    echo "\n================= 测试网络连通性 ================="
    ping -c 4 google.com || echo "无法连接到 Google，请检查网络连接"

    echo "\n================= 已安装的软件包 ================="
    echo "软件包数量：$(dpkg -l | wc -l)"
}

# 时间校准
calibrate_time() {
    echo "\n[校准时间]"
    sudo cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    sudo ntpdate time.windows.com
    echo "时间校准完成，当前时区为 Asia/Shanghai"
}

# 系统更新
update_system() {
    echo "\n[更新系统]"
    sudo apt update -y && sudo apt full-upgrade -y
    sudo apt autoremove -y && sudo apt autoclean -y
    echo "系统更新完成！"
}

# 系统清理
clean_system() {
    echo "\n[清理系统]"
    sudo apt autoremove --purge -y
    sudo apt clean -y && sudo apt autoclean -y
    sudo journalctl --rotate && sudo journalctl --vacuum-time=1s
    sudo journalctl --vacuum-size=50M
    echo "系统清理完成！"
}

# 开启 BBR
enable_bbr() {
    echo "\n[开启BBR]"
    if sysctl net.ipv4.tcp_congestion_control | grep -q 'bbr'; then
        echo "BBR 已开启。"
    else
        echo "net.core.default_qdisc = fq" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv4.tcp_congestion_control = bbr" | sudo tee -a /etc/sysctl.conf
        sudo sysctl -p
        echo "BBR 已启用，重启系统后生效。"
    fi
}

# 申请证书
apply_certificate() {
    while true; do
        echo "\n[申请证书]"
        echo "1) 安装脚本"
        echo "2) 申请证书"
        echo "3) 更换服务器"
        echo "4) 安装证书"
        echo "5) 卸载脚本"
        echo "6) 返回主菜单"
        read -p "请输入数字 [1-6]: " cert_choice
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
                read -p "请输入域名: " domain
                read -p "请输入证书安装路径: " path
                ~/.acme.sh/acme.sh --installcert -d $domain \
                    --key-file $path/private.key --fullchain-file $path/cert.crt
                echo "证书安装完成！"
                ;;
            5)
                ~/.acme.sh/acme.sh --uninstall
                echo "acme.sh 已卸载。"
                ;;
            6)
                break
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
        echo "\n[安装 Xray]"
        echo "1) 安装/升级"
        echo "2) 编辑配置"
        echo "3) 重启服务"
        echo "4) 查看状态"
        echo "5) 卸载服务"
        echo "6) 返回主菜单"
        read -p "请输入数字 [1-6]: " xray_choice
        case "$xray_choice" in
            1)
                bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
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
                break
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
        echo "\n[安装 hysteria2]"
        echo "1) 安装/升级"
        echo "2) 编辑配置"
        echo "3) 重启服务"
        echo "4) 查看状态"
        echo "5) 开机自启"
        echo "6) 卸载服务"
        echo "7) 返回主菜单"
        read -p "请输入数字 [1-7]: " hysteria_choice
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
                break
                ;;
            *)
                echo "无效选项，请重新输入。"
                ;;
        esac
    done
}

# 主循环
while true; do
    display_main_menu
    read -p "请输入数字 [1-9] 选择功能: " choice
    case "$choice" in
        1) view_vps_info ;;
        2) calibrate_time ;;
        3) update_system ;;
        4) clean_system ;;
        5) enable_bbr ;;
        6) apply_certificate ;;
        7) install_xray ;;
        8) install_hysteria2 ;;
        9)
            echo "退出脚本，感谢使用！"
            exit 0
            ;;
        *)
            echo "无效选项，请输入数字 1-9！"
            ;;
    esac
    read -n 1 -s -r -p "按任意键返回主菜单..."
done
