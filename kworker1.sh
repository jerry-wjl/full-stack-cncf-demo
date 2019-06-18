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

# create docker brtfs fs
mkfs.ext4 -F -L var-lib-docker /dev/sdb
echo LABEL=var-lib-docker /var/lib/docker auto defaults 0 1 >>/etc/fstab
mkdir /var/lib/docker
mount /var/lib/docker

# allow ssh between nodes
mkdir /root/.ssh
cp /vagrant/id_rsa /root/.ssh
cp /vagrant/id_rsa.pub /root/.ssh/authorized_keys
chmod go-rw /root/.ssh/*

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
