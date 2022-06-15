#!/bin/bash

# 관리자 권한으로 실행되었는지 확인
if [ $EUID -ne 0 ]; then
    echo "[!] Root required to use this script"
    echo "[i] Re-launching as root account..."
    sudo $0 $@
    exit
fi

# 필요한 프로그램이 설치되어 있는지 확인
if ! command -v quota &> /dev/null; then
    echo "[!] Quota is not installed"
    
    source /etc/os-release
    if [ $id == "centos" ]; then
        echo "[i] Installing Quota..."
        yum -y install quota
    fi
fi

# /home이 별도의 파티션인지 확인
if ! mountpoint "/home" &> /dev/null; then
    echo "[!] \"/home\" does not have a separate partition!"
    exit
fi

# script stage 1
if [ ! -f "/opt/exam/03/stage1" ]; then
    # create stage1 marker
    echo "[i] Starting quota stage-1 task..."
    mkdir -p "/opt/exam/03"
    touch "/opt/exam/03/stage1"
    # enable quota on /home
    echo "[i] Enabling quota on \"/home\"..."
    sed -ie '/ \/home/ s/defaults/defaults,usrquota,grpquota/' /etc/fstab
    echo "[i] Please restart this script after reboot"
    echo "[i] Rebooting after 10 seconds..."
    sleep 10
    reboot
fi

# script stage 2
if [ -f "/opt/exam/03/stage1" ]; then
    # create quota database file
    echo "[i] Creating quota database..."
    touch /home/aquota.user
    chmod 600 /home/aquota.user
    # enable quota on /home
    echo "[i] Enabling quota..."
    quotaon /home
    # create user samuel, csejj
    echo "[i] Creating user samuel, csejj..."
    useradd -G linuxadmin -m samuel
    useradd -G linuxuser -m csejj
    usermod -g linuxadmin samuel
    usermod -g linuxuser csejj
    groupdel samuel
    groupdel csejj
    # set user quota limit for samuel (max 10 files)
    echo "[i] Applying user quota limit..."
    setquota -u samuel 0 0 10 10 /home
    # set group quota limit for linuxuser (max 1MB, 20 files)
    echo "[i] Applying group quota limit..."
    setquota -g linuxuser 1024 1024 20 20 /home
    echo -e "\n[i] Done. Now check with \"repquota /home\" and some files."
fi
