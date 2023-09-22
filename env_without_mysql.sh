#!/bin/sh
#
#Date:2021.12.09
#Author:GZ
#Mail:V2board@qq.com

process()
{
    install_date="V2board_install_$(date +%Y-%m-%d_%H:%M:%S).log"
    printf "
\033[36m#######################################################################
#                     欢迎使用V2board一键部署脚本                     #
#                脚本适配环境CentOS7+/RetHot7+、内存1G+               #
#                更多信息请访问 https://gz1903.github.io              #
#######################################################################\033[0m
    "
    
    while :; do echo
        read -p "请输入您的域名: " Domain
        [ -n "$Domain" ] && break
    done
    
    # 从接收信息后开始统计脚本执行时间
    START_TIME=`date +%s`
    
    yum install -y git wget
    
    echo -e "\033[36m#######################################################################\033[0m"
    echo -e "\033[36m#                                                                     #\033[0m"
    echo -e "\033[36m#                  正在关闭SElinux策略 请稍等~                          #\033[0m"
    echo -e "\033[36m#                                                                     #\033[0m"
    echo -e "\033[36m#######################################################################\033[0m"
    setenforce 0
    #临时关闭SElinux
    sed -i "s/SELINUX=enforcing/SELINUX=disabled/" /etc/selinux/config
    #永久关闭SElinux
    
    echo -e "\033[36m#######################################################################\033[0m"
    echo -e "\033[36m#                                                                     #\033[0m"
    echo -e "\033[36m#                  正在配置Firewall策略 请稍等~                       #\033[0m"
    echo -e "\033[36m#                                                                     #\033[0m"
    echo -e "\033[36m#######################################################################\033[0m"
    firewall-cmd --zone=public --add-port=80/tcp --permanent
    firewall-cmd --zone=public --add-port=443/tcp --permanent
    firewall-cmd --reload
    firewall-cmd --zone=public --list-ports
    #放行TCP80、443端口
    
    
    echo -e "\033[36m#######################################################################\033[0m"
    echo -e "\033[36m#                                                                     #\033[0m"
    echo -e "\033[36m#                 正在下载安装包，时间较长 请稍等~                    #\033[0m"
    echo -e "\033[36m#                                                                     #\033[0m"
    echo -e "\033[36m#######################################################################\033[0m"
    # 下载安装包
    git clone https://github.com/define9/lnmp_rpm.git /usr/local/src/lnmp_rpm
    cd /usr/local/src/lnmp_rpm
    # 安装nginx，php，redis,mysql
    echo -e "\033[36m下载完成，开始安装~\033[0m"
    rpm -ivhU /usr/local/src/lnmp_rpm/*.rpm --nodeps --force --nosignature
    
    # 启动nmp
    systemctl start php-fpm.service nginx redis
    
    # 加入开机启动
    systemctl enable php-fpm.service nginx redis
    
    echo -e "\033[36m#######################################################################\033[0m"
    echo -e "\033[36m#                                                                     #\033[0m"
    echo -e "\033[36m#                    正在配置PHP.ini 请稍等~                          #\033[0m"
    echo -e "\033[36m#                                                                     #\033[0m"
    echo -e "\033[36m#######################################################################\033[0m"
    sed -i "s/post_max_size = 8M/post_max_size = 32M/" /etc/php.ini
    sed -i "s/max_execution_time = 30/max_execution_time = 600/" /etc/php.ini
    sed -i "s/max_input_time = 60/max_input_time = 600/" /etc/php.ini
    sed -i "s#;date.timezone =#date.timezone = Asia/Shanghai#" /etc/php.ini
    # 配置php-sg11
    mkdir -p /sg
    wget -P /sg/  https://cdn.jsdelivr.net/gh/gz1903/sg11/Linux%2064-bit/ixed.7.3.lin
    sed -i '$a\extension=/sg/ixed.7.3.lin' /etc/php.ini
    #修改PHP配置文件
    echo $?="PHP.inin配置完成完成"
    
    echo -e "\033[36m#######################################################################\033[0m"
    echo -e "\033[36m#                                                                     #\033[0m"
    echo -e "\033[36m#                    正在配置Nginx 请稍等~                              #\033[0m"
    echo -e "\033[36m#       会配置ssl, 请把Domain.cer和Domain.key放入/etc/pki/tls/certs/下  #\033[0m"
    echo -e "\033[36m#                                                                     #\033[0m"
    echo -e "\033[36m#######################################################################\033[0m"
    cp -i /etc/nginx/conf.d/default.conf{,.bak}
cat > /etc/nginx/conf.d/default.conf <<eof
server {
    server_name $Domain;
    listen 443;

    ssl on;
    ssl_certificate /etc/pki/tls/certs/$Domain.cer;
    ssl_certificate_key /etc/pki/tls/certs/$Domain.key;
    ssl_session_timeout 5m;
    ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
    ssl_ciphers ECDHE-RSA-AES128-GCM-SHA256:HIGH:!aNULL:!MD5:!RC4:!DHE;
    ssl_prefer_server_ciphers on;

    root /usr/share/nginx/html/v2board/public;
    index index.html index.htm index.php;

    error_page   500 502 503 504  /50x.html;
    #error_page   404 /404.html;
    #fastcgi_intercept_errors on;

    location / {
        try_files \$uri \$uri/ /index.php\$is_args\$query_string;
    }
    location = /50x.html {
        root   /usr/share/nginx/html/v2board/public;
    }
    #location = /404.html {
    #    root   /usr/share/nginx/html/v2board/public;
    #}
    location ~ \.php$ {
        root           html;
        fastcgi_pass   127.0.0.1:9000;
        fastcgi_index  index.php;
        fastcgi_param  SCRIPT_FILENAME  /usr/share/nginx/html/v2board/public/\$fastcgi_script_name;
        include        fastcgi_params;
    }
    location /downloads {
    }
    location ~ .*\.(js|css)?$
    {
        expires      1h;
        error_log off;
        access_log /dev/null;
    }
}
eof
    
cat > /etc/nginx/nginx.conf <<"eon"

user  nginx;
worker_processes  auto;

error_log  /var/log/nginx/error.log notice;
pid        /var/run/nginx.pid;

events {
    worker_connections  1024;
}

http {
    include       /etc/nginx/mime.types;
    default_type  application/octet-stream;

    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                      '$status $body_bytes_sent "$http_referer" '
                      '"$http_user_agent" "$http_x_forwarded_for"';

    access_log  /var/log/nginx/access.log  main;
    #fastcgi_intercept_errors on;

    sendfile        on;
    #tcp_nopush     on;

    keepalive_timeout  65;

    #gzip  on;

    include /etc/nginx/conf.d/*.conf;
}
eon
    
    mv /etc/nginx/conf.d/default.conf /etc/nginx/conf.d/v2board.conf
    
    # 重启nginx
    systemctl restart nginx
    
    # 创建php测试文件
    touch /usr/share/nginx/html/phpinfo.php
cat > /usr/share/nginx/html/phpinfo.php <<eos
<?php
	phpinfo();
?>
eos
    
}

LOGFILE=/var/log/"V2board_install_$(date +%Y-%m-%d_%H:%M:%S).log"
touch $LOGFILE
tail -f $LOGFILE &
pid=$!
exec 3>&1
exec 4>&2
exec &>$LOGFILE
process
ret=$?
exec 1>&3 3>&-
exec 2>&4 4>&-
