#!/bin/sh
function install_stuff(){
    sudo yum install git -y
    sudo yum install npm -y
}
function create_todo_user(){
    useradd -m -r todo-app && passwd -l todo-app
    mkdir /home/todo-app/app
    chown todo-app /home/todo-app/app
    chmod -R 755 /home/todo-app
}

function setup_linux_environmnet(){
    setenforce 0
    sed -r -i 's/SELINUX=(enforciing|disabled)/SELINUX=permissive/' /etc/selinux/config
}

function setup_firewall(){
    firewall-cmd --zone=public --add-service=http
    firewall-cmd --zone=public --add-service=https
    firewall-cmd --zone=public --add-service=ssh
    firewall-cmd --runtime-to-permanent
}

function setup_application(){
    git clone https://github.com/timoguic/ACIT4640-todo-app.git /home/todo-app/app/
    npm install --prefix /home/todo-app/app/
}

function copy_all_files(){
    cp /home/admin/database.js /home/todo-app/app/config/ -f
    cp /home/admin/nginx.conf /etc/nginx/nginx.conf -f
    cp /home/admin/todoapp.service /lib/systemd/system -f
}

function start_services(){
    systemctl enable nginx
    systemctl start nginx
    systemctl enable mongod && systemctl start mongod
    systemctl daemon-reload
    systemctl enable todoapp
    systemctl start todoapp
    nginx -s reload
}

create_todo_user
setup_linux_environmnet
setup_firewall
setup_application
copy_all_files
start_services