sed -i '4s/.*/BOOTPROTO=static' /etc/sysconfig/network-scripts/ifcfg-enp0s3
echo "IPADDR=192.168.250.10" >> /etc/sysconfig/network-scripts/ifcfg-enp0s3
echo "PREFIX=24" >> /etc/sysconfig/network-scripts/ifcfg-enp0s3
echo "GATEWAY=192.168.250.1" >> /etc/sysconfig/network-scripts/ifcfg-enp0s3
echo "NETMASK=255.255.255.0" >> /etc/sysconfig/network-scripts/ifcfg-enp0s3
echo "192.168.250.10/24 wp.snp.acit" >> /etc/hosts
systemctl restart network

yum install wget -y
wget https://acit4640.y.vu/docs/module02/resources/acit_admin_id_rsa.pub

mkdir -p ~/.ssh
chmod 700 ~/.ssh

sudo useradd admin -p P@ssw0rd
sudo gpasswd -a admin wheel
cp acit_admin_id_rsa.pub ~admin/.ssh/authorized_keys

sed -r -i 's/^(%wheel\s+ALL=\(ALL\)\s+)(ALL)$/\1NOPASSWD: ALL/' /etc/sudoers

setenforce 0
sed -r -i 's/SELINUX=(enforcing|disabled)/SELINUX=permissive/' /etc/selinux/config

yum install epel-release vim git tcpdump curl net-tools bzip2 -y
yum update -y

firewall-cmd --zone=public --add-port=22/tcp --permanent
firewall-cmd --zone=public --add-port=80/tcp --permanent
firewall-cmd --zone=public --add-port=443/tcp --permanent
firewall-cmd --zone=public --list-all

useradd -m -r todo-app && passwd -l todo-app
yum install nodejs npm -y
yum install mongodb-server -y
systemctl enable mongod && systemctl start mongod

mkdir /home/todo-app/app
chown todo-app /home/todo-app/app
git clone https://github.com/timoguic/ACIT4640-todo-app.git /home/todo-app/app/
npm install --prefix /home/todo-app/app/

echo $currentDir
cd $currentDir
cd "$(dirname "$0")"

fileFolderPath=$(pwd)/files
echo $fileFolderPath
databasePath=${fileFolderPath}/database.js
echo $databasePath
nginxPath=${fileFolderPath}/nginx.conf
todoappPath=${fileFolderPath}/todoapp.service

cp $databasePath /home/todo-app/app/config/ -f
cat /home/todo-app/app/config/database.js
chmod -R 755 /home/todo-app

yum install nginx -y
systemctl start nginx
systemctl enable nginx
systemctl status nginx

cp $nginxPath /etc/nginx/nginx.conf -f
cp $todoappPath /lib/systemd/system -f

systemctl daemon-reload
systemctl start todoapp
systemctl enable todoapp
systemctl status todoapp

systemctl restart nginx