#!/usr/bin/env bash
blue(){
    echo -e "\033[34m\033[01m$1\033[0m"
}
green(){
    echo -e "\033[32m\033[01m$1\033[0m"
}
red(){
    echo -e "\033[31m\033[01m$1\033[0m"
}
yellow(){
    echo -e "\033[33m\033[01m$1\033[0m"
}

apt-get install curl
domain=$(openssl rand -hex 8)
password=$(openssl rand -hex 16)
obfs=$(openssl rand -hex 6)
path="/root/hysteria"
ip=$(curl -4 -s -m 8 ip.sb)
port=$(($(od -An -N2 -i /dev/random) % (65534 - 10001) + 10001))

function hysteria_install(){
mkdir hysteria
cd ./hysteria
wget https://github.com/HyNetwork/hysteria/releases/download/v1.0.4/hysteria-linux-amd64
chmod +x hysteria-linux-amd64
# 生成CAkey
openssl genrsa -out hysteria.ca.key 2048
# 生成CA证书
openssl req -new -x509 -days 3650 -key hysteria.ca.key -subj "/C=CN/ST=GD/L=SZ/O=Hysteria, Inc./CN=Hysteria Root CA" -out hysteria.ca.crt

openssl req -newkey rsa:2048 -nodes -keyout hysteria.server.key -subj "/C=CN/ST=GD/L=SZ/O=Hysteria, Inc./CN=*.${domain}.com" -out hysteria.server.csr
# 签发服务端用的证书
openssl x509 -req -extfile <(printf "subjectAltName=DNS:${domain}.com,DNS:www.${domain}.com") -days 3650 -in hysteria.server.csr -CA hysteria.ca.crt -CAkey hysteria.ca.key -CAcreateserial -out hysteria.server.crt

echo "block all udp/443" > /${path}/yugogoServer.acl

cat > ./client.json <<EOF
{
    "server": "${ip}:${port}",
    "protocol": "udp",
    "alpn": "h3", 
    "auth_str": "${password}",
    "up_mbps": 20,
    "down_mbps": 100,
    "socks5": {
        "listen": "127.0.0.1:10808",
        "timeout" : 300,
        "disable_udp": false
    },
    "http": {
        "listen": "127.0.0.1:10809",
        "timeout" : 300,
        "disable_udp": false
    },
    "server_name": "www.${domain}.com",
    "acl": "acl/routes.acl",
    "mmdb": "acl/Country.mmdb",
    "auth_str": "${password}",
    "insecure": true,
    "recv_window_conn": 11010048,
    "recv_window": 44040192,
    "disable_mtu_discovery": true,
    "resolver": "119.29.29.29:53",
    "retry": 3,
    "retry_interval": 3
}
EOF


cat > ./server.json <<EOF
{
    "listen": ":${port}",
    "protocol": "udp",
    "disable_udp": false,
    "cert": "${path}/hysteria.server.crt",
    "key": "${path}/hysteria.server.key" ,
    "auth": {
        "mode": "password",
        "config": {
            "password": "${password}"
        }
    },
    "alpn": "h3",
    "acl": "${path}/yugogoServer.acl",
    "recv_window_conn": 11010048,
    "recv_window_client": 44040192,
    "max_conn_client": 4096,
    "disable_mtu_discovery": true,
    "resolve_preference": "46",
    "resolver": "8.8.8.8:53"
}
EOF

nohup /root/hysteria/hysteria-linux-amd64 -c /root/hysteria/server.json server >/dev/null 2>/dev/null &
green "=========="
    yellow " hysteria安装成功并已启动"
    green "=========="
    yellow "请下载/root/hysteria/client.json到本地结合V2rayN运行"
}

remove_hysteria(){
pkill hysteria
rm -rf /root/hysteria*
green "=========="
    green " 卸载完成"
    green "=========="
    green "hysteria has been deleted."
}


function menu()
{
clear
    green " ======================================================"
    green " 描述：hysteria一键安装脚本"
    green " 系统：仅支持debian"
    green " 作者：Littleyu  www.yugogo.xyz"
    green " YouTuBe频道：Littleyu科学上网"
    green " ======================================================"
    echo
    yellow " 1. 安装hysteria服务端"
    yellow " 2. 卸载hysteria"
    yellow " 0. Exit"
    echo
    read -p "输入数字:" num
    case "$num" in
    1)
    hysteria_install
    ;;
    2)
    remove_hysteria
    ;;
    0)
    exit 1
    ;;
    *)
    clear
    red "Enter a correct number"
    sleep 2s
    menu
    ;;
    esac
}

menu
