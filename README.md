#  VPS 管理脚本

## 自用的vps常用命令脚本，适用于debian系统，目前集成以下功能：

- 查看系统配置信息；
- 系统优化：更新、清理、开启BBR及ROOT登录等；
- 域名证书申请；
- Xray官方安装及设置；
- Hysteria2安装及设置；
- 1Panel安装及卸载；
- 其他功能陆续添加中。

## 直接使用命令

```bash
bash <(curl -sL https://raw.githubusercontent.com/sezhai/vps-script/refs/heads/main/one.sh)
\```

## 下载使用命令

### 下载
- ```sudo bash -c 'curl -sL https://raw.githubusercontent.com/sezhai/vps-script/refs/heads/main/one.sh -o /usr/local/sbin/one && chmod +x /usr/local/sbin/one && /usr/local/sbin/one'```
### 运行
- ```one```
### 卸载
- ```sudo rm -f /usr/local/sbin/one```





