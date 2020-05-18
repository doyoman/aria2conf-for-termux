#!/usr/bin/env bash
#=============================================================
# https://github.com/P3TERX/aria2.sh
# Description: Aria2 One-click installation management script
# System Required: CentOS/Debian/Ubuntu
# Version: 2.3.0
# Author: Toyo
# Maintainer: P3TERX
# Blog: https://p3terx.com
#=============================================================

sh_ver="2.3.0"
PATH=$PREFIX/bin
export PATH
aria2_conf_path="$HOME/.aria2"
download_path="$HOME/storage/downloads/aria2"
aria2_conf="${aria2_conf_path}/aria2.conf"
aria2_log="${aria2_conf_path}/aria2.log"
aria2c="$PREFIX/bin/aria2c"
Green_font_prefix="\033[32m"
Red_font_prefix="\033[31m"
Green_background_prefix="\033[42;37m"
Red_background_prefix="\033[41;37m"
Font_color_suffix="\033[0m"
Info="[${Green_font_prefix}信息${Font_color_suffix}]"
Error="[${Red_font_prefix}错误${Font_color_suffix}]"
Tip="[${Green_font_prefix}注意${Font_color_suffix}]"

check_installed_status() {
    [[ ! -e ${aria2c} ]] && echo -e "${Error} Aria2 没有安装，请检查 !" && exit 1
    [[ ! -e ${aria2_conf} ]] && echo -e "${Error} Aria2 配置文件不存在，请检查 !" && [[ $1 != "un" ]] && exit 1
}
check_pid() {
    PID=$(ps -ef | grep "aria2c" | grep -v grep | grep -v "aria2.sh" | grep -v "init.d" | grep -v "service" | awk '{print $2}')
}
Start_aria2() {
    check_installed_status
    check_pid
    [[ ! -z ${PID} ]] && echo -e "${Error} Aria2 正在运行，请检查 !" && exit 1
    $HOME/.aria2/aria2 start
}
Stop_aria2() {
    check_installed_status
    check_pid
    [[ -z ${PID} ]] && echo -e "${Error} Aria2 没有运行，请检查 !" && exit 1
    $HOME/.aria2/aria2 stop
}
Restart_aria2() {
    check_installed_status
    check_pid
    [[ ! -z ${PID} ]] && $HOME/.aria2/aria2 stop
    $HOME/.aria2/aria2 start
}
Set_aria2() {
    check_installed_status
    echo && echo -e "你要做什么？
 ${Green_font_prefix}1.${Font_color_suffix}  修改 Aria2 RPC 密钥
 ${Green_font_prefix}2.${Font_color_suffix}  修改 Aria2 RPC 端口
 ${Green_font_prefix}3.${Font_color_suffix}  修改 Aria2 文件下载位置
 ${Green_font_prefix}4.${Font_color_suffix}  修改 Aria2 密钥 + 端口 + 文件下载位置
 ${Green_font_prefix}5.${Font_color_suffix}  手动 打开配置文件修改
 ————————————" && echo
    read -e -p "(默认: 取消):" aria2_modify
    [[ -z "${aria2_modify}" ]] && echo "已取消..." && exit 1
    if [[ ${aria2_modify} == "1" ]]; then
        Set_aria2_RPC_passwd
    elif [[ ${aria2_modify} == "2" ]]; then
        Set_aria2_RPC_port
    elif [[ ${aria2_modify} == "3" ]]; then
        Set_aria2_RPC_dir
    elif [[ ${aria2_modify} == "4" ]]; then
        Set_aria2_RPC_passwd_port_dir
    elif [[ ${aria2_modify} == "5" ]]; then
        Set_aria2_vim_conf
    else
        echo -e "${Error} 请输入正确的数字(0-5)" && exit 1
    fi
}
Set_aria2_RPC_passwd() {
    read_123=$1
    if [[ ${read_123} != "1" ]]; then
        Read_config
    fi
    if [[ -z "${aria2_passwd}" ]]; then
        aria2_passwd_1="空(没有检测到配置，可能手动删除或注释了)"
    else
        aria2_passwd_1=${aria2_passwd}
    fi
    echo -e "请输入要设置的 Aria2 RPC 密钥(旧密钥为：${Green_font_prefix}${aria2_passwd_1}${Font_color_suffix})"
    read -e -p "(默认密钥: 随机生成 密钥请不要包含等号 = 和井号 #):" aria2_RPC_passwd
    echo
    [[ -z "${aria2_RPC_passwd}" ]] && aria2_RPC_passwd=$(date +%s%N | md5sum | head -c 20)
    if [[ "${aria2_passwd}" != "${aria2_RPC_passwd}" ]]; then
        if [[ -z "${aria2_passwd}" ]]; then
            echo -e "\nrpc-secret=${aria2_RPC_passwd}" >>${aria2_conf}
            if [[ $? -eq 0 ]]; then
                echo -e "${Info} 密钥修改成功！新密钥为：${Green_font_prefix}${aria2_RPC_passwd}${Font_color_suffix}(因为找不到旧配置参数，所以自动加入配置文件底部)"
                if [[ ${read_123} != "1" ]]; then
                    Restart_aria2
                fi
            else
                echo -e "${Error} 密钥修改失败！旧密钥为：${Green_font_prefix}${aria2_passwd}${Font_color_suffix}"
            fi
        else
            sed -i 's/^rpc-secret='${aria2_passwd}'/rpc-secret='${aria2_RPC_passwd}'/g' ${aria2_conf}
            if [[ $? -eq 0 ]]; then
                echo -e "${Info} 密钥修改成功！新密钥为：${Green_font_prefix}${aria2_RPC_passwd}${Font_color_suffix}"
                if [[ ${read_123} != "1" ]]; then
                    Restart_aria2
                fi
            else
                echo -e "${Error} 密钥修改失败！旧密钥为：${Green_font_prefix}${aria2_passwd}${Font_color_suffix}"
            fi
        fi
    else
        echo -e "${Error} 新密钥与旧密钥一致，取消..."
    fi
}
Set_aria2_RPC_port() {
    read_123=$1
    if [[ ${read_123} != "1" ]]; then
        Read_config
    fi
    if [[ -z "${aria2_port}" ]]; then
        aria2_port_1="空(没有检测到配置，可能手动删除或注释了)"
    else
        aria2_port_1=${aria2_port}
    fi
    echo -e "请输入要设置的 Aria2 RPC 端口(旧端口为：${Green_font_prefix}${aria2_port_1}${Font_color_suffix})"
    read -e -p "(默认端口: 6800):" aria2_RPC_port
    echo
    [[ -z "${aria2_RPC_port}" ]] && aria2_RPC_port="6800"
    if [[ "${aria2_port}" != "${aria2_RPC_port}" ]]; then
        if [[ -z "${aria2_port}" ]]; then
            echo -e "\nrpc-listen-port=${aria2_RPC_port}" >>${aria2_conf}
            if [[ $? -eq 0 ]]; then
                echo -e "${Info} 端口修改成功！新端口为：${Green_font_prefix}${aria2_RPC_port}${Font_color_suffix}(因为找不到旧配置参数，所以自动加入配置文件底部)"
                if [[ ${read_123} != "1" ]]; then
                    Restart_aria2
                fi
            else
                echo -e "${Error} 端口修改失败！旧端口为：${Green_font_prefix}${aria2_port}${Font_color_suffix}"
            fi
        else
            sed -i 's/^rpc-listen-port='${aria2_port}'/rpc-listen-port='${aria2_RPC_port}'/g' ${aria2_conf}
            if [[ $? -eq 0 ]]; then
                echo -e "${Info} 端口修改成功！新端口为：${Green_font_prefix}${aria2_RPC_port}${Font_color_suffix}"
                if [[ ${read_123} != "1" ]]; then
                    Restart_aria2
                fi
            else
                echo -e "${Error} 端口修改失败！旧端口为：${Green_font_prefix}${aria2_port}${Font_color_suffix}"
            fi
        fi
    else
        echo -e "${Error} 新端口与旧端口一致，取消..."
    fi
}
Set_aria2_RPC_dir() {
    read_123=$1
    if [[ ${read_123} != "1" ]]; then
        Read_config
    fi
    if [[ -z "${aria2_dir}" ]]; then
        aria2_dir_1="空(没有检测到配置，可能手动删除或注释了)"
    else
        aria2_dir_1=${aria2_dir}
    fi
    echo -e "请输入要设置的 Aria2 文件下载位置(旧位置为：${Green_font_prefix}${aria2_dir_1}${Font_color_suffix})"
    read -e -p "(默认位置: ${download_path}):" aria2_RPC_dir
    [[ -z "${aria2_RPC_dir}" ]] && aria2_RPC_dir="${download_path}"
    mkdir -p ${aria2_RPC_dir}
    echo
    if [[ -d "${aria2_RPC_dir}" ]]; then
        if [[ "${aria2_dir}" != "${aria2_RPC_dir}" ]]; then
            if [[ -z "${aria2_dir}" ]]; then
                echo -e "\ndir=${aria2_RPC_dir}" >>${aria2_conf}
                if [[ $? -eq 0 ]]; then
                    echo -e "${Info} 位置修改成功！新位置为：${Green_font_prefix}${aria2_RPC_dir}${Font_color_suffix}(因为找不到旧配置参数，所以自动加入配置文件底部)"
                    if [[ ${read_123} != "1" ]]; then
                        Restart_aria2
                    fi
                else
                    echo -e "${Error} 位置修改失败！旧位置为：${Green_font_prefix}${aria2_dir}${Font_color_suffix}"
                fi
            else
                aria2_dir_2=$(echo "${aria2_dir}" | sed 's/\//\\\//g')
                aria2_RPC_dir_2=$(echo "${aria2_RPC_dir}" | sed 's/\//\\\//g')
                sed -i 's/^dir='${aria2_dir_2}'/dir='${aria2_RPC_dir_2}'/g' ${aria2_conf}
                sed -i "/^downloadpath=/c\downloadpath='${aria2_RPC_dir_2}'" ${aria2_conf_path}/*.sh
                sed -i "/^DOWNLOAD_PATH=/c\DOWNLOAD_PATH='${aria2_RPC_dir_2}'" ${aria2_conf_path}/*.sh
                if [[ $? -eq 0 ]]; then
                    echo -e "${Info} 位置修改成功！新位置为：${Green_font_prefix}${aria2_RPC_dir}${Font_color_suffix}"
                    if [[ ${read_123} != "1" ]]; then
                        Restart_aria2
                    fi
                else
                    echo -e "${Error} 位置修改失败！旧位置为：${Green_font_prefix}${aria2_dir}${Font_color_suffix}"
                fi
            fi
        else
            echo -e "${Error} 新位置与旧位置一致，取消..."
        fi
    else
        echo -e "${Error} 新位置文件夹不存在，请检查！新位置为：${Green_font_prefix}${aria2_RPC_dir}${Font_color_suffix}"
    fi
}
Set_aria2_RPC_passwd_port_dir() {
    Read_config
    Set_aria2_RPC_passwd "1"
    Set_aria2_RPC_port "1"
    Set_aria2_RPC_dir "1"
    Restart_aria2
}
Set_aria2_vim_conf() {
    Read_config
    aria2_port_old=${aria2_port}
    aria2_dir_old=${aria2_dir}
    read -e -p "如果已经了解 vim 使用方法，请按任意键继续，如要取消请使用 Ctrl+C 。" var
    vim "${aria2_conf}"
    Read_config
    if [[ ${aria2_port_old} != ${aria2_port} ]]; then
        aria2_RPC_port=${aria2_port}
        aria2_port=${aria2_port_old}
    fi
    if [[ ${aria2_dir_old} != ${aria2_dir} ]]; then
        mkdir -p ${aria2_dir}
        aria2_dir_2=$(echo "${aria2_dir}" | sed 's/\//\\\//g')
        aria2_dir_old_2=$(echo "${aria2_dir_old}" | sed 's/\//\\\//g')
        sed -i "/^downloadpath=/c\downloadpath='${aria2_RPC_dir_2}'" ${aria2_conf_path}/*.sh
        sed -i "/^DOWNLOAD_PATH=/c\DOWNLOAD_PATH='${aria2_RPC_dir_2}'" ${aria2_conf_path}/*.sh
    fi
    Restart_aria2
}
Read_config() {
    status_type=$1
    if [[ ! -e ${aria2_conf} ]]; then
        if [[ ${status_type} != "un" ]]; then
            echo -e "${Error} Aria2 配置文件不存在 !" && exit 1
        fi
    else
        conf_text=$(cat ${aria2_conf} | grep -v '#')
        aria2_dir=$(echo -e "${conf_text}" | grep "^dir=" | awk -F "=" '{print $NF}')
        aria2_port=$(echo -e "${conf_text}" | grep "^rpc-listen-port=" | awk -F "=" '{print $NF}')
        aria2_passwd=$(echo -e "${conf_text}" | grep "^rpc-secret=" | awk -F "=" '{print $NF}')
        aria2_bt_port=$(echo -e "${conf_text}" | grep "^listen-port=" | awk -F "=" '{print $NF}')
        aria2_dht_port=$(echo -e "${conf_text}" | grep "^dht-listen-port=" | awk -F "=" '{print $NF}')
    fi
}
View_Aria2() {
    check_installed_status
    Read_config
    IPV4="127.0.0.1"
#$(
#        wget -qO- -t1 -T2 -4 ip.sb ||
#            wget -qO- -t1 -T2 -4 ifconfig.io ||
#            wget -qO- -t1 -T2 -4 www.trackip.net/ip
#    )
#    [[ -z "${IPV4}" ]] && IPV4="IPv4 地址检测失败"
    IPV6="用于本地，想啥呢"
#$(
#        wget -qO- -t1 -T2 -6 ip.sb ||
#            wget -qO- -t1 -T2 -6 ifconfig.io ||
#            wget -qO- -t1 -T2 -6 www.trackip.net/ip
#    )
    [[ -z "${IPV6}" ]] && IPV6="IPv6 地址检测失败"
    [[ -z "${aria2_dir}" ]] && aria2_dir="找不到配置参数"
    [[ -z "${aria2_port}" ]] && aria2_port="找不到配置参数"
    [[ -z "${aria2_passwd}" ]] && aria2_passwd="找不到配置参数(或无密钥)"
    clear
    echo -e "\nAria2 简单配置信息：\n
 IPv4 地址\t: ${Green_font_prefix}${IPV4}${Font_color_suffix}
 IPv6 地址\t: ${Green_font_prefix}${IPV6}${Font_color_suffix}
 RPC 端口\t: ${Green_font_prefix}${aria2_port}${Font_color_suffix}
 RPC 密钥\t: ${Green_font_prefix}${aria2_passwd}${Font_color_suffix}
 下载目录\t: ${Green_font_prefix}${aria2_dir}${Font_color_suffix}\n"
}
View_Log() {
    [[ ! -e ${aria2_log} ]] && echo -e "${Error} Aria2 日志文件不存在 !" && exit 1
    echo && echo -e "${Tip} 按 ${Red_font_prefix}Ctrl+C${Font_color_suffix} 终止查看日志" && echo -e "如果需要查看完整日志内容，请用 ${Red_font_prefix}cat ${aria2_log}${Font_color_suffix} 命令。" && echo
    tail -f ${aria2_log}
}
Clean_Log() {
    [[ ! -e ${aria2_log} ]] && echo -e "${Error} Aria2 日志文件不存在 !" && exit 1
    >${aria2_log}
    echo -e "${Info} Aria2 日志已清空 !"
}
Update_bt_tracker() {
    check_installed_status
    check_pid
    [[ -z $PID ]] && {
        bash <(wget -qO- git.io/tracker.sh) ${aria2_conf}
    } || {
        bash <(wget -qO- git.io/tracker.sh) ${aria2_conf} RPC
    }
}

echo && echo -e " Aria2 for termux 便捷管理脚本  DOYO修改自用
原版地址: https://github.com/P3TERX/aria2.sh
————————————————————————
 ${Green_font_prefix} 1.${Font_color_suffix} 启动 Aria2
 ${Green_font_prefix} 2.${Font_color_suffix} 停止 Aria2
 ${Green_font_prefix} 3.${Font_color_suffix} 重启 Aria2
————————————————————————
 ${Green_font_prefix} 4.${Font_color_suffix} 修改 配置
 ${Green_font_prefix} 5.${Font_color_suffix} 查看 配置
 ${Green_font_prefix} 6.${Font_color_suffix} 查看 日志
 ${Green_font_prefix} 7.${Font_color_suffix} 清空 日志
————————————————————————
 ${Green_font_prefix} 8.${Font_color_suffix} 手动更新 BT-Tracker
————————————————————————" && echo
if [[ -e ${aria2c} ]]; then
    check_pid
    if [[ ! -z "${PID}" ]]; then
        echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 并 ${Green_font_prefix}已启动${Font_color_suffix}"
    else
        echo -e " 当前状态: ${Green_font_prefix}已安装${Font_color_suffix} 但 ${Red_font_prefix}未启动${Font_color_suffix}"
    fi
else
    echo -e " 当前状态: ${Red_font_prefix}未安装${Font_color_suffix}"
fi
echo
read -e -p " 请输入数字 [1-8]:" num
case "$num" in
1)
    Start_aria2
    ;;
2)
    Stop_aria2
    ;;
3)
    Restart_aria2
    ;;
4)
    Set_aria2
    ;;
5)
    View_Aria2
    ;;
6)
    View_Log
    ;;
7)
    Clean_Log
    ;;
8)
    Update_bt_tracker
    ;;
*)
    echo "请输入正确数字 [1-8]"
    ;;
esac
