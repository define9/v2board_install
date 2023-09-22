#!/bin/sh

process()
{
    # 从接收信息后开始统计脚本执行时间
    START_TIME=`date +%s`
    install_date="V2board_install_$(date +%Y-%m-%d_%H:%M:%S).log"
    
    echo -e "\033[36m#######################################################################\033[0m"
    echo -e "\033[36m#                                                                     #\033[0m"
    echo -e "\033[36m#                    正在部署V2board 请稍等~                           #\033[0m"
    echo -e "\033[36m#                                                                     #\033[0m"
    echo -e "\033[36m#######################################################################\033[0m"
    rm -rf /usr/share/nginx/html/v2board
    cd /usr/share/nginx/html
    git clone https://github.com/v2board/v2board.git
    cd /usr/share/nginx/html/v2board
    git checkout 1.7.4
    sh /usr/share/nginx/html/v2board/init.sh
    chmod -R 777 /usr/share/nginx/html/v2board
    # 添加定时任务
    echo "* * * * * root /usr/bin/php /usr/share/nginx/html/v2board/artisan schedule:run >/dev/null 2>/dev/null &" >> /etc/crontab
    
    # 启动队列
    php artisan horizon &

    # 清除缓存垃圾
    rm -rf /usr/local/src/v2board_install
    rm -rf /usr/local/src/lnmp_rpm
    
    echo -e "\033[32m--------------------------- 安装已完成 ---------------------------\033[0m"
    echo -e "\033[32m##################################################################\033[0m"
    echo -e "\033[32m#                            V2board                             #\033[0m"
    echo -e "\033[32m##################################################################\033[0m"
    echo -e "\033[32m 网站目录       :/usr/share/nginx/html/v2board \033[0m"
    echo -e "\033[32m Nginx配置文件  :/etc/nginx/conf.d/v2board.conf \033[0m"
    echo -e "\033[32m------------------------------------------------------------------\033[0m"
    
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
