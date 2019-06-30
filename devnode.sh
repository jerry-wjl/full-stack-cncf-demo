#!/bin/sh

# Disable selinux
setenforce 0
sed -i '/^SELINUX.*/s//SELINUX=disabled/' /etc/selinux/config

# Set up hosts file
printf '192.168.56.200 devnode\n192.168.56.201 kmaster\n192.168.56.202 kworker1\n' >>/etc/hosts

# Allow root ssh logins
printf 'demo ALL=(ALL) NOPASSWD: ALL' >/etc/sudoers.d/demo
printf '\nPermitRootLogin yes\n' >> /etc/ssh/sshd_config
printf '\nStrictHostKeyChecking no\n' >>/etc/ssh/ssh_config
systemctl restart sshd

# create docker fs
mkfs.ext4 -F -L var-lib-docker /dev/sdb
echo LABEL=var-lib-docker /var/lib/docker auto defaults 0 1 >>/etc/fstab
mkdir /var/lib/docker
mount /var/lib/docker

yum-config-manager --enable ol7_addons ol7_latest ol7_optional_latest ol7_UEKR5
yum -y install docker-engine docker-registry java-11-openjdk git mongodb-server kubeadm kubectl haproxy nodejs nfs-utils
yum -y upgrade

# enable docker
systemctl enable docker
systemctl start docker

# allow ssh between nodes
mkdir /root/.ssh
cp /vagrant/id_rsa /root/.ssh
cp /vagrant/id_rsa.pub /root/.ssh/authorized_keys
chmod 0600 /root/.ssh/*

# Make a demo user with password welcome1
useradd demo -p "$6$/HTxL3YE$ZNXjFmj4SpgDzeR6EgxkTtDPQCCVa1aW9r0NdggyA9jlozQojKkDEvC1cWFyM1TvABppkkWh/gKhu7LJRAo8V/" -G wheel,docker
mkdir -p /home/demo/.ssh
cp /vagrant/id_rsa /home/demo/.ssh/
cp /vagrant/id_rsa.pub /home/demo/.ssh/authorized_keys
mkdir -p /home/demo/.kube
chmod 0600 /home/demo/.ssh/*

# Jenkins
curl -s -L http://mirrors.jenkins.io/war-stable/latest/jenkins.war >/home/demo/jenkins.war
printf '#!/bin/sh\nnohup java -jar jenkins.war --httpPort=4000 &\n' >/home/demo/jenkins.sh
chmod +x /home/demo/jenkins.sh
(cd /home/demo; su - demo jenkins.sh)

# Git repo
mkdir /home/demo/git
(cd /home/demo/git; git init cncfdemo --bare)

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

printf '#!/bin/sh\ndocker run --name registry -itd -p :5000:5000 -v `pwd`:/certs -e REGISTRY_HTTP_TLS_CERTIFICATE=/certs/domain.crt  -e REGISTRY_HTTP_TLS_KEY=/certs/domain.key --restart always registry
' >/home/demo/registry.sh
chmod +x /home/demo/registry.sh
/home/demo/registry.sh

# Pull official nodejs slim image
docker pull node:10-slim

# Finally pull container registry images

if [ -f /vagrant/ocr.txt ]; then
    . /vagrant/ocr.txt
    docker login -u $OCRUSER  -p $OCRPASS container-registry.oracle.com
    kubeadm-registry.sh --to devnode:5000
    
    # Pull prometheus from Oracle Container Registry Developer Repo
    docker pull container-registry.oracle.com/kubernetes_developer/prometheus:v2.9.1
    docker tag container-registry.oracle.com/kubernetes_developer/prometheus:v2.9.1 devnode:5000/prometheus
fi

# Pull Grafana from Official Docker Hub repository
docker pull grafana/grafana
docker tag grafana/grafana devnode:5000/grafana

# Copy Grafana and Prometheus configuration
cp -r /vagrant/grafana /home/demo/
cp -r /vagrant/prometheus /home/demo/

# Build Grafana and Prometheus images preconfigured for BBC app 
docker build -t bbc-prometheus /home/demo/prometheus/
docker build -t bbc-grafana /home/demo/grafana/

# Install td-agent for fluentd logging
yum -y install td-agent
systemctl enable td-agent
systemctl start td-agent

# Haproxy
cp /vagrant/haproxy/haproxy.cfg /etc/haproxy/
systemctl start haproxy
systemctl enable haproxy

# Download Prometheus Node Exporter
wget -nv https://github.com/prometheus/node_exporter/releases/download/v0.18.1/node_exporter-0.18.1.linux-amd64.tar.gz
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

# Set up nfs server for CSI
mkdir /nfs
chmod a+rwt /nfs
printf '/nfs *(rw,no_root_squash,async,no_subtree_check,insecure)' >/etc/exports
systemctl start nfs-server
systemctl enable nfs-server

# Fix ownership because we did everything as root --- THIS SHOULD BE THE LAST STEP
chown -R demo:demo /home/demo
