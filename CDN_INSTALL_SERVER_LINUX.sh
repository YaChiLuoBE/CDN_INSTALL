#开始 如果重新安装就执行以下代码
# rm -fr .bash_profile
# mv .bash_profile.bak .bash_profile
# vi install && chmod +x install && ./install > ~/install.log
# ./install > ~/install.log
#结束 如果重新安装就执行以下代码

###################################################################
###################################################################
yum -y install make wget bzip2
# https://github.com/aristocratos/btop/releases/latest
cd ~
mkdir btop
cd btop
wget https://github.com/aristocratos/btop/releases/download/v1.0.13/btop-1.0.13-linux-x86_64.tbz
tar -jxvf btop-1.0.13-linux-x86_64.tbz
./install.sh
cd ..
rm -fr btop
###################################################################
###################################################################

hostnamectl set-hostname virmach
yum -y update
yum -y install gcc gcc-c++ autoconf libjpeg libjpeg-devel libpng libpng-devel freetype freetype-devel libxml2 libxml2-devel zlib zlib-devel glibc glibc-devel glib2 glib2-devel bzip2 bzip2-devel ncurses ncurses-devel curl curl-devel e2fsprogs e2fsprogs-devel krb5-devel libidn openssl openssl-devel nss_ldap openldap openldap-devel openldap-clients libxslt-devel libevent-devel libtool-ltdl bison libtool
yum -y install wget vim vim-enhanced
yum -y install perl make
cp ~/.bash_profile ~/.bash_profile.bak

mkdir /www
cd /www

wget https://www.openssl.org/source/openssl-1.1.1k.tar.gz
tar zxvf openssl-1.1.1k.tar.gz
rm -fr openssl-1.1.1k.tar.gz
cd openssl-1.1.1k
./config --prefix=/www/openssl
make && make install

cd /www
wget https://ftp.pcre.org/pub/pcre/pcre-8.44.tar.gz
tar zxvf pcre-8.44.tar.gz
rm -fr pcre-8.44.tar.gz
cd pcre-8.44
./configure --prefix=/www/pcre
make && make install

cd /www
wget https://www.zlib.net/zlib-1.2.11.tar.gz
tar zxvf zlib-1.2.11.tar.gz
rm -fr zlib-1.2.11.tar.gz
cd zlib-1.2.11
./configure --prefix=/www/zlib
make && make install

cd /www
# wget https://nginx.org/download/nginx-1.19.10.tar.gz
# tar zxvf nginx-1.19.10.tar.gz
# rm -fr nginx-1.19.10.tar.gz
# cd nginx-1.19.10
wget https://nginx.org/download/nginx-1.20.1.tar.gz
tar zxvf nginx-1.20.1.tar.gz
rm -fr nginx-1.20.1.tar.gz
cd nginx-1.20.1
./configure \
--prefix=/www/nginx \
--conf-path=/www/nginx/conf/nginx.conf \
--pid-path=/www/nginx/logs/nginx.pid \
--with-stream_ssl_module \
--with-http_ssl_module \
--with-openssl=/www/openssl-1.1.1k \
--with-pcre=/www/pcre-8.44 \
--with-zlib=/www/zlib-1.2.11
make && make install

cd /www
cat << EOF > /www/nginx/nginx.service
[Unit]
Description=nginx
After=network.target

[Service]
TimeoutStartSec=0
Type=forking
ExecStart=/www/nginx/sbin/nginx
ExecReload=/www/nginx/sbin/nginx -s reload
ExecStop=/www/nginx/sbin/nginx -s quit
PrivateTmp=true

[Install]
WantedBy=multi-user.target
EOF

cp /www/nginx/conf/nginx.conf /www/nginx/conf/nginx.conf.bak
cat << EOF > /www/nginx/conf/nginx.conf
worker_processes 2;
events {
    worker_connections 1024;
}
http {
    include       mime.types;
    default_type  application/octet-stream;
    sendfile on;
    keepalive_timeout 65;
    server {
        listen       80;
        server_name  localhost;
        location / {
            root   html;
            index  index.html index.htm;
        }
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }
        location /yynb {
            proxy_redirect off;
            proxy_pass http://127.0.0.1:8080;
            proxy_http_version 1.1;
            proxy_set_header Upgrade \$http_upgrade;
            proxy_set_header Connection "upgrade";
            proxy_set_header Host \$http_host;
        }
    }
}
EOF

mkdir -p /www/nginx/ssl
chmod 700 /www/nginx/ssl
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /www/nginx/ssl/yynb.key -out /www/nginx/ssl/yynb.crt

echo "alias n='vim /www/nginx/conf/nginx.conf'" >> ~/.bash_profile
echo "alias nservice='vim /www/nginx/nginx.service'" >> ~/.bash_profile

# 关掉防火墙 否则就不能使用systemctl
systemctl disable firewalld
systemctl stop firewalld
setenforce 0

systemctl enable /www/nginx/nginx.service
systemctl start nginx
systemctl status nginx

###################################################################
###################################################################

cd ~
# https://github.com/v2fly/fhs-install-v2ray
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh)
bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-dat-release.sh)
# bash <(curl -L https://raw.githubusercontent.com/v2fly/fhs-install-v2ray/master/install-release.sh) --remove

echo "alias v='vim /usr/local/etc/v2ray/config.json'" >> ~/.bash_profile
echo "alias vnservice='vim /etc/systemd/system/v2ray.service'" >> ~/.bash_profile


cat << EOF > /usr/local/etc/v2ray/config.json
{
    "log": {
        "access": "/var/log/v2ray/access.log",
        "error": "/var/log/v2ray/error.log",
        "loglevel": "error"
    },

    "inbounds": [
    {
        "port": 8080,
        "listen": "127.0.0.1",
        "protocol": "vmess",
        "settings": {
            "clients": [{
                "id": "8edb118b-c4bc-4d56-e8c0-f57bfdb131f4",
                "alterId": 32
            }]
        },
        "streamSettings":
        {
            "network": "ws",
            "wsSettings": {"path": "/yynb"}
        }
    }
    ],

    "outbounds": [{"protocol": "freedom"}]
}
EOF

systemctl enable /etc/systemd/system/v2ray.service
systemctl start v2ray
systemctl status v2ray

###################################################################
###################################################################
cd ~
#wget https://github.com/fatedier/frp/releases/download/v0.23.3/frp_0.23.3_linux_386.tar.gz
wget https://github.com/fatedier/frp/releases/download/v0.23.3/frp_0.23.3_linux_386.tar.gz
tar zxvf frp_0.23.3_linux_386.tar.gz -C /etc
mv /etc/frp_0.23.3_linux_386 /etc/frp
rm -fr frp_0.23.3_linux_386.tar.gz

cat << EOF > /etc/frp/frps.ini
[common]
bind_port = 7070
token = AAAAB3NzaC1yc2EAAAABJQAAAQEAmAw6vW3NiYOGU5y7pxelO/5V8OE40V18S27LGs8ec0AbA6/1Kk0w7CZSzGjYcHpXnO8VptalvdgUm6FTRc1ZFM50M4VVa+3gXs/zpGls8QjUj5meLr3ChDorgl5mE8u7LiyY0KRDuhq6bxLtsxfrU3kh5j+AKePlXEPZ8nZr34KZvbihlmOGppqfuKLJW6/Hf3kM+T4p0Jkj6hGBSeFEO1MdsRNJrORQ9tQkAeRWOHU9ykKCUbOXuEN1bMcid3hMb3sYXk3WdhPoE0Oyh7evMoBeTlIcS4MuOpuJtYprvkxuxmsSvTVdelMre5UiLPth48FRYZ6AblJD/BY86JTEYQ
log_file = /etc/frp/frps.log
EOF

cat << EOF > /etc/frp/frps.service
[Unit]
Description=frps
[Service]
TimeoutStartSec=0
ExecStart=/etc/frp/frps -c /etc/frp/frps.ini
[Install]
WantedBy=multi-user.target
EOF

systemctl enable /etc/frp/frps.service
systemctl start frps
systemctl status frps

cd ~
echo "alias f='vim /etc/frp/frps.ini'" >> ~/.bash_profile
echo "alias fservice='vim /etc/frp/frps.service'" >> ~/.bash_profile

###################################################################
###################################################################

cd ~
# wget https://dl.bintray.com/htop/source/htop-3.0.2.tar.gz
wget https://github.com/htop-dev/htop/archive/refs/tags/3.1.0.tar.gz
yum install -y gcc ncurses-devel make
tar zxvf 3.1.0.tar.gz
cd htop-3.1.0
./autogen.sh
./configure
make
make install
cd ..
rm -fr 3.1.0.tar.gz
rm -fr htop-3.1.0

###################################################################
###################################################################

cd ~
yum install -y epel-release
yum install -y gcc flex byacc libpcap ncurses ncurses-devel libpcap-devel tcpdump
yum install -y iftop

###################################################################
################################################################### 创建nolog的账号：fred

groupadd fred
useradd -g fred -s /sbin/nologin -M fred
passwd fred
cd /home
mkdir fred
chown root:fred fred
chmod 755 fred
cat << EOF >> /etc/ssh/sshd_config
Subsystem fred internal-sftp

Match User fred
    ChrootDirectory /home/fred
    ForceCommand internal-sftp
    AllowTcpForwarding no
    X11Forwarding no
ChrootDirectory /home/sftp #用户的根目录
EOF

###################################################################
###################################################################

systemctl disable firewalld
systemctl stop firewalld
echo "cat /etc/redhat-release" >> ~/.bash_profile
cat << EOF >> ~/.bash_profile
setenforce 0
alias t='echo curl --http1.0 localhost:8080 http://httpbin.org/ip;curl --http1.0 localhost:8080 http://httpbin.org/ip;'
alias r='systemctl stop v2ray;systemctl disable v2ray;rm -fr /var/log/v2ray/access.log /var/log/v2ray/error.log;systemctl enable /etc/systemd/system/v2ray.service;systemctl start v2ray;systemctl stop nginx;systemctl disable nginx;rm -fr /www/nginx/logs/*;systemctl enable /www/nginx/nginx.service;systemctl start nginx;systemctl stop frps;systemctl disable frps;rm -fr /etc/frp/frps.log;systemctl enable /etc/frp/frps.service;systemctl start frps;systemctl daemon-reload;'
alias s='systemctl status nginx -l;systemctl status v2ray -l;systemctl status frps -l;'
alias b='vim ~/.bash_profile'
alias vi='vim'
alias cls=clear
alias ipconfig=ifconfig
stty erase ^h

TZ='Asia/Shanghai'
export TZ

PATH=$PATH:~
export PATH
EOF

. ~/.bash_profile

# https://developer.aliyun.com/article/767677
wget -N --no-check-certificate "https://gist.github.com/zeruns/a0ec603f20d1b86de6a774a8ba27588f/raw/4f9957ae23f5efb2bb7c57a198ae2cffebfb1c56/tcp.sh" && chmod +x tcp.sh && ./tcp.sh





# systemctl stop v2ray;systemctl disable v2ray;rm -fr /var/log/v2ray/access.log /var/log/v2ray/error.log;systemctl enable /etc/systemd/system/v2ray.service;systemctl start v2ray;systemctl stop nginx;systemctl disable nginx;rm -fr /www/nginx/logs/*;systemctl enable /www/nginx/nginx.service;systemctl start nginx;systemctl stop frps;systemctl disable frps;rm -fr /etc/frp/frps.log;systemctl enable /etc/frp/frps.service;systemctl start frps;

