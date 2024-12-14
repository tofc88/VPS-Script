#!/bin/bash
sh_v="1.0.0"

# 脚本标题与功能说明
SCRIPT_TITLE="常用命令脚本"

# 函数：打印菜单
print_menu() {
  clear
  echo "========================================="
  echo "$SCRIPT_TITLE"
  echo "========================================="
  echo "请选择要执行的操作："
  echo "1) 校准时间"
  echo "2) 更新系统"
  echo "3) 清理系统"
  echo "4) 开启BBR加速"
  echo "5) 申请证书"
  echo "6) 安装Xray"
  echo "7) 安装hysteria2"
  echo "8) 退出脚本"
  echo "========================================="
}

# 等待用户按任意键返回
wait_for_key() {
  read -n 1 -s -r -p "按任意键返回主菜单..."
  echo
}

# 校准时间
calibrate_time() {
  echo -e "\n[校准时间]"
  sudo timedatectl set-timezone Asia/Shanghai
  if sudo timedatectl set-ntp true; then
    echo "时间同步已完成，当前时区设置为 Asia/Shanghai。"
  else
    echo "时间同步失败，请检查网络连接！"
  fi
}

# 更新系统
update_system() {
  echo -e "\n[更新系统]"
  if sudo apt update -y && sudo apt full-upgrade -y && sudo apt autoremove -y && sudo apt autoclean -y; then
    echo "系统更新完成！"
  else
    echo "系统更新失败，请检查错误日志。"
  fi
}

# 清理系统
clean_system() {
  echo -e "\n[清理系统]"
  sudo apt autoremove --purge -y && sudo apt clean -y && sudo apt autoclean -y
  sudo apt remove --purge $(dpkg -l | awk '/^rc/ {print $2}') -y
  sudo journalctl --rotate && sudo journalctl --vacuum-time=1s && sudo journalctl --vacuum-size=50M
  sudo apt remove --purge $(dpkg -l | awk '/^ii linux-(image|headers)-[^ ]+/{print $2}' | grep -v $(uname -r | sed 's/-.*//')) -y
  echo "系统清理完成！"
}

# 开启BBR加速
enable_bbr() {
  echo -e "\n[开启BBR加速]"
  if sysctl net.ipv4.tcp_congestion_control | grep -q 'bbr'; then
    echo "BBR 已经开启，无需重复操作。"
  else
    echo -e "net.core.default_qdisc = fq\nnet.ipv4.tcp_congestion_control = bbr" | sudo tee -a /etc/sysctl.conf
    sudo sysctl -p
    echo "BBR 已启用，请重新启动系统以生效！"
  fi
}

# 申请证书
apply_certificate() {
  while true; do
    echo -e "\n[申请证书子菜单]"
    echo "1) 安装脚本"
    echo "2) 申请证书"
    echo "3) 更换服务器"
    echo "4) 安装证书"
    echo "5) 卸载脚本"
    echo "6) 返回主菜单"
    read -p "请选择操作（1-6）: " cert_choice
    case "$cert_choice" in
      1)
        read -p "请输入您的邮箱地址: " email
        if curl https://get.acme.sh | sh -s email="$email"; then
          echo "acme.sh 安装成功"
        else
          echo "acme.sh 安装失败"
        fi
        ;;
      2)
        read -p "请输入您的域名: " domain
        /root/.acme.sh/acme.sh --issue --standalone -d "$domain"
        ;;
      3)
        /root/.acme.sh/acme.sh --set-default-ca --server letsencrypt
        ;;
      4)
        read -p "请输入证书路径: " path
        /root/.acme.sh/acme.sh --installcert -d "$domain" --key-file "$path/private.key" --fullchain-file "$path/cert.crt"
        ;;
      5)
        /root/.acme.sh/acme.sh --uninstall && rm -r ~/.acme.sh
        ;;
      6)
        break
        ;;
      *)
        echo "无效输入，请重新选择！"
        ;;
    esac
    wait_for_key
  done
}

# 安装 Xray
install_xray() {
  echo -e "\n[安装 Xray]"
  bash -c "$(curl -L https://github.com/XTLS/Xray-install/raw/main/install-release.sh)" @ install
}

# 安装 hysteria2
install_hysteria2() {
  echo -e "\n[安装 hysteria2]"
  bash <(curl -fsSL https://get.hy2.sh/)
}

# 主菜单循环
while true; do
  print_menu
  read -p "请输入操作编号（1-8）: " choice
  case "$choice" in
    1) calibrate_time ;;
    2) update_system ;;
    3) clean_system ;;
    4) enable_bbr ;;
    5) apply_certificate ;;
    6) install_xray ;;
    7) install_hysteria2 ;;
    8)
      echo "退出脚本，感谢使用！"
      exit 0
      ;;
    *)
      echo "无效输入，请重新选择！"
      ;;
  esac
  wait_for_key
done
