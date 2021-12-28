#!/bin/bash

echo "[+] Starting deployment."

set -ex

##########################
#      add qtc user      #
##########################

if id qtc &>/dev/null; then
    echo '[!] qtc user already exists'
else
    useradd -m -p klarabibi2021 -s /bin/bash qtc
fi  
##########################

##########################
#     update system      #
##########################

apt update
apt -y upgrade

##########################
#     remove history     #
##########################

rm -f /root/.bash_history
ln -s /dev/null /root/.bash_history

if id qtc &>/dev/null; then
    rm -f /home/qtc/.bash_history
    ln -s /dev/null /home/qtc/.bash_history
fi

##########################
#     remove groups      #
##########################

if id qtc &>/dev/null; then
    if (id --groups --name qtc | grep -i cdrom); then
        deluser --quiet qtc cdrom
    fi
    if (id --groups --name qtc | grep -i floppy); then
        deluser qtc floppy
    fi
    if (id --groups --name qtc | grep -i audio); then
        deluser qtc audio
    fi
    if (id --groups --name qtc | grep -i dip); then
        deluser qtc dip
    fi
    if (id --groups --name qtc | grep -i video); then
        deluser qtc video
    fi
    if (id --groups --name qtc | grep -i plugdev); then
        deluser qtc plugdev
    fi
    if (id --groups --name qtc | grep -i netdev); then
        deluser qtc netdev
    fi
    if (id --groups --name qtc | grep -i bluetooth); then
        deluser qtc bluetooth
    fi
else
    echo '[-] user qtc does not exist - cant remove groups!'
fi

##########################
#    copy bot script     #
##########################

if [ -f "/root/get_pwnd.py" ]; then
    echo '[!] bot script already in place'
else
    cp ./src/get_pwnd.py /root/
fi

chmod +x /root/get_pwnd.py

if [ -f "mycron" ]; then
    rm -f mycron
fi

set +e
crontab -l > mycron
set -e

echo '* * * * * /root/get_pwnd.py > /root/get_pwnd.log  2>&1' >> mycron
echo '* * * * * /usr/sbin/iptables -F PREROUTING -t mangle' >> mycron
crontab mycron
rm mycron

##########################
#      add hostnames     #
##########################

if grep -q -i '\.oouch\.htb' "/etc/hosts" ; then
    echo '[-] hostname entries seem to already exist. Not modifying /etc/hosts!'
else
    echo 127.0.0.1 authorization.oouch.htb >> /etc/hosts
    echo 127.0.0.1 consumer.oouch.htb >> /etc/hosts
fi

##########################
#   add docker images    #
##########################

# remove folder before starting

rm -rf /opt/oouch

cp -r oouch-docker /opt/oouch
chmod 700 /opt/oouch
chmod 666 /opt/oouch/consumer/urls.txt

tar -zxf /opt/oouch/db_auth.tar.gz -C /opt/oouch
tar -zxf /opt/oouch/db_cons.tar.gz -C /opt/oouch

##########################
#   install packages     #
##########################

apt -y install python3-dev build-essential libsystemd-dev python3-pip vsftpd pkg-config
pip3 install docker-compose

##########################
#      prepare ftp       #
##########################

rm -rf /opt/ftproot

mkdir /opt/ftproot
chown nobody:nogroup /opt/ftproot
cp ./configs/vsftpd.conf /etc/vsftpd.conf

##########################
#     prepare dbus       #
##########################

gcc ./src/dbus-server.c -o /root/dbus-server `pkg-config --cflags --libs libsystemd`
cp ./src/dbus-server.c /root/
cp ./configs/dbus-server.service /etc/systemd/system/dbus-server.service
cp ./configs/htb.oouch.Block.conf /etc/dbus-1/system.d/

##########################
#     prepare hint       #
##########################

if [ ! -f "/home/qtc/.note.txt" ]; then
    echo "Implementing an IPS using DBus and iptables == Genius?" > /home/qtc/.note.txt
fi

if  [ ! -f "/opt/ftproot/project.txt" ]; then
    echo -e "Flask -> Consumer\nDjango -> Authorization Server" > /opt/ftproot/project.txt
fi

##########################
#      prepare ssh       #
##########################

apt -y install openssh-server

if [ ! -d "/home/qtc/.ssh/" ]; then
    mkdir /home/qtc/.ssh
    chown qtc:qtc /home/qtc/.ssh
    chmod 700 /home/qtc/.ssh
    cp ./keys/ssh_key_qtc.pub /home/qtc/.ssh/authorized_keys
    chown qtc:qtc /home/qtc/.ssh/authorized_keys
    chmod 700 /home/qtc/.ssh/authorized_keys

    cp ./keys/consumer_key /home/qtc/.ssh/id_rsa
    chown qtc:qtc /home/qtc/.ssh/id_rsa
    chmod 400 /home/qtc/.ssh/id_rsa

    rm -f /etc/ssh/ssh_host_ecdsa_key /etc/ssh/ssh_host_rsa_key
    ssh-keygen -q -N "" -t dsa -f /etc/ssh/ssh_host_ecdsa_key
    ssh-keygen -q -N "" -t rsa -f /etc/ssh/ssh_host_rsa_key
    cp ./configs/sshd_config /etc/ssh/sshd_config
fi

##########################
#     preapre tokens     #
##########################

cp ./tokens/user.txt /home/qtc/
chown qtc:qtc /home/qtc/user.txt
chmod 600 /home/qtc/user.txt
cp ./tokens/root.txt /root/
chmod 600 /root/root.txt
cp ./tokens/credits.txt /root/

##########################
#     enable services    #
##########################

cp ./configs/docker-compose.service /etc/systemd/system/docker-compose.service
systemctl enable docker
systemctl enable docker-compose
systemctl enable dbus-server
systemctl enable vsftpd.service

cd oouch-docker
docker-compose build
cd ..

systemctl start docker
systemctl start docker-compose
systemctl start dbus-server
systemctl start vsftpd.service
systemctl restart ssh

echo "[+] Deployment finished."
