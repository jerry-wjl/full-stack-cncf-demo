#!/bin/sh
# Disable selinux
setenforce 0
sed -i '/^SELINUX.*/s//SELINUX=disabled/' /etc/selinux/config

# Set up hosts file
printf '192.168.56.200 devnode\n192.168.56.201 kmaster\n192.168.56.202 kworker1\n' >>/etc/hosts

# Allow root ssh logins 
printf '\nPermitRootLogin yes\n' >> /etc/ssh/sshd_config
printf '\nStrictHostKeyChecking no\n' >>/etc/ssh/ssh_config
systemctl restart sshd

# create docker brtfs fs
mkfs.btrfs -L var-lib-docker /dev/sdb
echo LABEL=var-lib-docker /var/lib/docker auto defaults 0 1 >>/etc/fstab
mkdir /var/lib/docker
mount /var/lib/docker

yum-config-manager --enable ol7_addons ol7_latest ol7_optional_latest ol7_UEKR5
yum -y install docker-engine docker-registry java-11-openjdk git mongodb-server kubeadm kubectl
yum -y upgrade

# enable docker
systemctl enable docker
systemctl start docker

# allow ssh between nodes
mkdir /root/.ssh
cp /vagrant/id_rsa /root/.ssh
cp /vagrant/id_rsa.pub /root/.ssh/authorized_keys
chmod go-rw /root/.ssh/*

# Make a demo user with password welcome1
useradd demo -p "$6$/HTxL3YE$ZNXjFmj4SpgDzeR6EgxkTtDPQCCVa1aW9r0NdggyA9jlozQojKkDEvC1cWFyM1TvABppkkWh/gKhu7LJRAo8V/" -G wheel,docker
mkdir -p /home/demo/.ssh
cp /vagrant/id_rsa.pub /home/demo/.ssh/authorized_keys
mkdir -p /home/demo/.kube

# Jenkins
curl -s -L http://mirrors.jenkins.io/war-stable/latest/jenkins.war >/home/demo/jenkins.war
printf '#!/bin/sh\nnohup java -jar jenkins.war --httpPort=4000 &\n' >/home/demo/jenkins.sh
chmod +x /home/demo/jenkins.sh
(cd /home/demo; su - demo jenkins.sh)

# Git
mkdir /home/demo/git
(cd /home/demo/git; git init cncfdemo)

# Mongodb
sed -i s/^bind_ip/#bind_ip/ /etc/mongod.conf
systemctl enable mongod
systemctl start mongod

# Registry
docker pull registry
cd /home/demo
openssl req -subj "/CN=devnode/O=DOCKER-REGISTRY-TEST/C=AE/emailAddress=mitch.dsouza@oracle.com" -newkey rsa:4096 -nodes -sha256 -keyout domain.key -x509 -days 356 -out domain.crt 2>/dev/null
mkdir -p /etc/docker/certs.d/devnode:5000
cp domain.crt /etc/docker/certs.d/devnode:5000/ca.crt
cp domain.crt /etc/docker/certs.d/devnode:5000/client.crt
cp domain.key /etc/docker/certs.d/devnode:5000/client.key

printf '#!/bin/sh\ndocker run -itd -p :5000:5000 -v `pwd`:/certs -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key --restart always registry
' >/home/demo/registry.sh
chmod +x /home/demo/registry.sh
/home/demo/registry.sh

if [ -f /vagrant/ocr.txt ]; then
    . /vagrant/ocr.txt
    docker login -u $OCRUSER  -p $OCRPASS container-registry.oracle.com
    kubeadm-registry.sh --to devnode:5000
    rm -f ocr.txt
fi

# Fix ownership because we did everything as root
chown -R demo:demo /home/demo
