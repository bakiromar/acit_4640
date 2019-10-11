vboxmanager () { VBoxManage.exe "$@"; }
VM_NAME="VM_ACIT4640"
NAT_NETWORK="net_4640"
PXE_SERVER="PXE_4640"

clean_all () {
	vboxmanager natnetwork remove --netname "$NAT_NETWORK"
	vboxmanager unregistervm "$VM_NAME" --delete
}

setup(){
vboxmanager natnetwork add --netname $NAT_NETWORK --network 192.168.250.0/24 --enable --dhcp off --ipv6 off --port-forward-4 "ssh:tcp:[]:50022:[192.168.250.10]:22" --port-forward-4 "http:tcp:[]:50080:[192.168.250.10]:80" --port-forward-4 "https:tcp:[]:50443:[192.168.250.10]:443" --port-forward-4 "ssh2:tcp:[]:50222:[192.168.250.200]:22"
vboxmanager createvm --name $VM_NAME --ostype "RedHat_64" --register
vboxmanager modifyvm $VM_NAME --memory 1536 --cpus 1 --nic1 natnetwork --nat-network1 $NAT_NETWORK --boot1 disk --boot2 net

SED_PROGRAM="/^Config file:/ { s/^.*:\s\+\(\S\+\)/\1/; s|\\\\|/|gp }"
VBOX_FILE=$(vboxmanager showvminfo "$VM_NAME" | sed -ne "$SED_PROGRAM")
VM_DIR=$(dirname "$VBOX_FILE")

vboxmanager createmedium disk --filename "$VM_DIR.vdi" --size 10000 --format VDI
vboxmanager storagectl $VM_NAME --name "SATA Controller" --add sata --controller IntelAhci
vboxmanager storageattach $VM_NAME --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$VM_DIR".vdi

vboxmanager storagectl $VM_NAME --name "IDE Controller" --add ide --controller PIIX4
vboxmanager storageattach $VM_NAME --storagectl "IDE Controller" --port 1 --device 0 --type dvddrive --medium "C:\Users\Dell\Downloads\CentOS-7-x86_64-Minimal-1810.iso"
}

start_pxe(){
    vboxmanager startvm "$PXE_SERVER"
chmod 600 -R files/acit_admin_id_rsa
while /bin/true; do
        ssh -i files/acit_admin_id_rsa -p 50222 \
            -o ConnectTimeout=2 -o StrictHostKeyChecking=no \
            -q admin@localhost exit
        if [ $? -ne 0 ]; then
                echo "PXE server is not up, sleeping..."
                sleep 2
        else
                break
        fi
done
}

remote_stuff(){
ssh -i files/acit_admin_id_rsa -p 50222 -o ConnectTimeout=2 -o StrictHostKeyChecking=no -q admin@localhost  "sudo rm -rf /var/www/lighttpd/ks.cfg; sudo rm -rf /var/www/lighttpd/files"
scp -i files/acit_admin_id_rsa -o StrictHostKeyChecking=no -P 50222 -r files admin@localhost:/home/admin/
ssh -i files/acit_admin_id_rsa -p 50222 admin@localhost "sudo mv /home/admin/files /var/www/lighttpd/ ; sudo mv /var/www/lighttpd/files/ks.cfg /var/www/lighttpd/ks.cfg"
ssh -i files/acit_admin_id_rsa -p 50222 admin@localhost "sudo chmod 755 /var/www/lighttpd/ks.cfg"
}

start_vm(){
vboxmanager startvm "$VM_NAME"
}

clean_all
setup
start_pxe
remote_stuff
start_vm