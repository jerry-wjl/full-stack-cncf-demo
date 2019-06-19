#!/bin/sh
# disable selinux
setenforce 0
sed -i '/^SELINUX.*/s//SELINUX=disabled/' /etc/selinux/config

# set up hosts file
printf '192.168.56.200 devnode\n192.168.56.201 kmaster\n192.168.56.202 kworker1\n' >>/etc/hosts

# allow root ssh logins 
printf '\nPermitRootLogin yes\n' >> /etc/ssh/sshd_config
printf '\nStrictHostKeyChecking no\n' >>/etc/ssh/ssh_config
systemctl restart sshd

# swap no allowed
swapoff -a
lvremove -f vg_main/lv_swap
lvresize -l +100%FREE  /dev/vg_main/lv_root
xfs_growfs /

# create docker brtfs fs
mkfs.ext4 -F -L var-lib-docker /dev/sdb
echo LABEL=var-lib-docker /var/lib/docker auto defaults 0 1 >>/etc/fstab
mkdir /var/lib/docker
mount /var/lib/docker

# allow ssh between nodes
mkdir /root/.ssh
cp /vagrant/id_rsa /root/.ssh
cp /vagrant/id_rsa.pub /root/.ssh/authorized_keys
chmod 0600 /root/.ssh/*

# install required packages
yum-config-manager --enable ol7_addons
yum -y install docker-engine kubeadm ntp
yum -y upgrade

# start ntp so that all k8s node certificates are in sync
systemctl enable ntpd && systemctl start ntpd

# enable and start docker
mkdir -p /etc/docker/certs.d
scp -r root@devnode:/etc/docker/certs.d/devnode\:5000 /etc/docker/certs.d
cp /etc/docker/certs.d/devnode:5000/client.crt /etc/docker/certs.d/devnode:5000/client.cert
systemctl enable docker
systemctl start docker

echo export KUBE_REPO_PREFIX=devnode:5000 >>~/.bashrc
export KUBE_REPO_PREFIX=devnode:5000
KMASTERIP=192.168.56.201
iptables -P FORWARD ACCEPT

TOKEN=`ssh root@kmaster "kubeadm token list"|awk 'NR==2 {print $1}'`
HASH=`ssh root@kmaster "openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null |openssl dgst -sha256 -hex | sed 's/^.* //'"`
kubeadm-setup.sh join --token $TOKEN $KMASTERIP:6443 --discovery-token-ca-cert-hash sha256:$HASH

# Download Prometheus Node Exporter
wget https://github.com/prometheus/node_exporter/releases/download/v0.18.1/node_exporter-0.18.1.linux-amd64.tar.gz
tar xvfz node_exporter-*.*-amd64.tar.gz
mv node_exporter-*.*-amd64 /usr/share/node_exporter

# Create Node Exporter service file
/bin/cat > /usr/lib/systemd/system/node_exporter.service <<EOF
[Unit]
Description=Node Exporter
Wants=network-online.target
After=network-online.target

[Service]
ExecStart=/usr/share/node_exporter/node_exporter

[Install]
WantedBy=multi-user.target
EOF

# Enable and Start Node Exporter service
systemctl daemon-reload
systemctl start node_exporter
systemctl enable node_exporter
