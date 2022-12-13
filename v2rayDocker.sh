#!/bin/bash
# Author: Houdawei

#记录最开始运行脚本的路径
BEGIN_PATH=$(pwd)


#定义操作变量, 0为否, 1为是
HELP=0

CHINESE=0

v2ray_domain=""


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
while [[ $# > 0 ]];do
    v2ray_domain="$1"
    shift
done
#############################

installFinish() {
    #配置域名
    
    #回到原点
    cd ${BEGIN_PATH}
    echo -e "\n请在安全组放开端口 12345\n"
}


main() {
    
    colorEcho ${BLUE} "开始下载Docker..\n"
    
    yum install -y amazon-linux-extras yum-utils device-mapper-persistent-data lvm2
    yum-config-manager --enable extras
    amazon-linux-extras install docker
    usermod -a -G docker ec2-user
    systemctl enable docker.service
    systemctl start docker.service
    
    
    colorEcho ${BLUE} "开始下载Docker镜像..\n"
    
    docker pull feihuwangluo/v2ray_hdw:v2
    docker run -d --name v2ray -p 12345:12345 --privileged --restart always feihuwangluo/v2ray_hdw:v2
    
    colorEcho ${RED} "安装完成！\n"
    
    docker exec v2ray /bin/sh -c "v2ray info"

    installFinish
}


#if [[ $v2ray_domain == "" ]]; then
#    echo -e "请输入域名，并确保已经解析到本机IP"
#    read -p "$(echo -e "(必须):")" v2ray_domain
#fi

main
