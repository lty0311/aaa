#!/bin/bash
# Author: Houdawei

#记录最开始运行脚本的路径
BEGIN_PATH=$(pwd)


#定义操作变量, 0为否, 1为是
HELP=0
CHINESE=0
ISHAVEDOCKER=0
v2ray_domain=""
cert_email=""

#######color code########
RED="31m"
GREEN="32m"
YELLOW="33m"
BLUE="36m"
FUCHSIA="35m"

colorEcho(){
    COLOR=$1
    echo -e "\033[${COLOR}${@:2}\033[0m"
}

colorEcho ${BLUE} "开始安装..\n"

#######get params#########
v2ray_domain="$1"
cert_email="$2"
#############################

installFinish() {
    #配置域名
    
    #回到原点
    cd ${BEGIN_PATH}
    echo -e "\n请在安全组放开端口 12345\n"
}

docker_is_install() {
    colorEcho "正在检查Docker是否安装.....\n"
    docker -v
    if [ $? -eq  0 ]; then
        ISHAVEDOCKER=1
    fi
}

docker_certbot() {
    certbot="docker run -it --name certbot -v ${BEGIN_PATH}/certbot/etc/letsencrypt:/etc/letsencrypt -v ${BEGIN_PATH}/certbot/lib/letsencrypt:/var/lib/letsencrypt -v ${BEGIN_PATH}/nginx_root:/www -v ${BEGIN_PATH}/certbot/var/log:/var/log certbot/certbot:v2.1.0"
    
    certbotRun="${certbot} certonly --webroot -w /www -d ${v2ray_domain}" #####-m 624936300@qq.com
    if [[ $cert_email != "" ]]; then
        certbotRun="${certbotRun} -m ${cert_email}"
    fi
    $certbotRun
    
    #${BEGIN_PATH}/certbot/etc/letsencrypt/live/${v2ray_domain}/
    #cert1.pem、chain1.pem、fullchain1.pem、privkey1.pem
    certbot_cp_cert="docker cp -L ${BEGIN_PATH}/certbot/etc/letsencrypt/live/${v2ray_domain}/privkey.pem v2ray:/root/${v2ray_domain}.key"
    certbot_cp_cert2="docker cp -L ${BEGIN_PATH}/certbot/etc/letsencrypt/live/${v2ray_domain}/fullchain.pem v2ray:/root/${v2ray_domain}.crt"
    $certbot_cp_cert
    $certbot_cp_cert2
    
    docker exec v2ray /bin/sh -c "sed -i 's/v2.mfkj-start.net/"${v2ray_domain}"/g' /etc/v2ray/config.json"
    docker exec v2ray /bin/sh -c "v2ray restart"
    
    cat /dev/null > ${BEGIN_PATH}/renewcer.sh
    echo ${certbot}' renew --force-renew' >> ${BEGIN_PATH}/renewcer.sh
    echo ${certbot_cp_cert} >> ${BEGIN_PATH}/renewcer.sh
    echo ${certbot_cp_cert2} >> ${BEGIN_PATH}/renewcer.sh
    echo 'docker exec v2ray /bin/sh -c "v2ray restart"' >> ${BEGIN_PATH}/renewcer.sh
    chmod +x ${BEGIN_PATH}/renewcer.sh
    # 一个月一更新
    crontab -l > conf && echo "* * * */1 * ${BEGIN_PATH}/renewcer.sh" >> conf && crontab conf && rm -f conf
}
    
main() {
    
    colorEcho ${BLUE} "开始下载Docker..\n"
    
    docker_is_install
    
    if [[ $ISHAVEDOCKER == 0 ]]; then
        yum install -y amazon-linux-extras yum-utils device-mapper-persistent-data lvm2
        yum-config-manager --enable extras
        amazon-linux-extras install -y docker
        usermod -a -G docker ec2-user
        systemctl enable docker.service
        systemctl start docker.service
    fi
    
    
    colorEcho ${BLUE} "开始下载Docker镜像..\n"
    
    docker pull feihuwangluo/v2ray_hdw:v2
    docker run -d --name v2ray -p 12345:12345 --privileged --restart always feihuwangluo/v2ray_hdw:v2
    
    colorEcho ${RED} "安装完成！\n"
    
    docker pull nginx:1.23.2
    docker run --name nginx_hdw -p 80:80 -v ${BEGIN_PATH}"/nginx_root:/usr/share/nginx/html" -d nginx:1.23.2
    
    docker pull certbot/certbot:v2.1.0
    
    docker_certbot
    
    docker exec v2ray /bin/sh -c "v2ray info"

    installFinish
}


if [[ $v2ray_domain == "" ]]; then
    echo -e "请输入域名，并确保已经解析到本机IP"
    read -p "$(echo -e "(必须):")" v2ray_domain
fi

main
