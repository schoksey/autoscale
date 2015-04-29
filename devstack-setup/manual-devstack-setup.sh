#!/bin/bash
clear

# Cleanup
echo "# Cleaning up prior installs"
sudo userdel stack
sudo sed -i -e 's/stack ALL=(ALL) NOPASSWD: ALL//g' /etc/sudoers
sudo rm -rf /home/stack
sudo rm -rf /opt/stack
rm -rf ./stack.basrc
rm -rf ./devstack
rm -rf ./heat-templates

echo ""

# Install prerequisites
echo "# Installing dependencies..."
check=`sudo dpkg -s git | grep Status | grep installed`
if [ "$check" == "" ]; then
	echo "Installing git."
	sudo apt-get -y install git > /dev/null
else
	echo "All dependencies installed."
fi

echo ""

# Setup stack user
echo "# Setting up stack user..."
if sudo grep stack /etc/passwd > /dev/null; then
        echo "Stack user already exists."
else
        sudo useradd -d /home/stack -m stack
	sudo sh -c "echo 'stack:stack' | chpasswd"
	
# Set stack.sh to run on first login
cat <<'EOF' > ./stack.bashrc

if [ -d "/opt/stack" ] ; then
    echo "Devstack installed"
else
    echo "Installing Devstack"
    cd /home/stack/devstack
    ./stack.sh
fi
EOF
	sudo sh -c "cat ./stack.bashrc >> /home/stack/.bashrc"
	echo "Stack user added."
fi

echo ""

echo "# Adding stack user to sudoers..."
if sudo grep stack /etc/sudoers > /dev/null; then
        echo "Stack user already in sudoers"
else
	echo "Added stack user to sudoers"
        sudo sh -c "echo 'stack ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers"
fi

echo ""

# Download and install devstack
git clone https://github.com/openstack-dev/devstack.git ./devstack/ > /dev/null
git clone https://github.com/openstack/heat-templates.git ./heat-templates/ > /dev/null

# Install and configure devstack
cat <<'EOF' > ./devstack/local.conf
[[local|localrc]]

# Global Options
LOGFILE=/opt/stack/logs/stack.sh.log
RECLONE=yes
VERBOSE=True
LOG_COLOR=False
SCREEN_LOGDIR=/opt/stack/logs

# Auth Info
ADMIN_PASSWORD=stack
DATABASE_PASSWORD=$ADMIN_PASSWORD
RABBIT_PASSWORD=$ADMIN_PASSWORD
SERVICE_PASSWORD=$ADMIN_PASSWORD
SERVICE_TOKEN=$ADMIN_PASSWORD

# Branches
KEYSTONE_BRANCH=stable/kilo
NOVA_BRANCH=stable/kilo
NEUTRON_BRANCH=stable/kilo
SWIFT_BRANCH=stable/kilo
GLANCE_BRANCH=stable/kilo
CINDER_BRANCH=stable/kilo
HEAT_BRANCH=stable/kilo
TROVE_BRANCH=stable/kilo
HORIZON_BRANCH=stable/kilo
SAHARA_BRANCH=stable/kilo

## Disable unwanted services
# Nova network and extra neutron services
disable_service n-net
disable_service q-fwaas
disable_service q-vpn
# Tempest services
disable_service tempest
# Sahara
disable_service sahara
# Trove services
disable_service trove
disable_service tr-api
disable_service tr-mgr
disable_service tr-cond
# Swift services
disable_service s-proxy
disable_service s-object
disable_service s-container
disable_service s-account

# Enable Cinder services
enable_service cinder
enable_service c-api
enable_service c-vol
enable_service c-sch
enable_service c-bak

# Enable Database Backend MySQL
enable_service mysql

# Enable RPC Backend RabbitMQ
enable_service rabbit

# Enable Keystone - OpenStack Identity Service
enable_service key  

# Enable Horizon - OpenStack Dashboard Service
enable_service horizon

# Enable Glance -  OpenStack Image service 
enable_service g-api
enable_service g-reg

# Enable Neutron - Networking Service
enable_service q-svc
enable_service q-agt
enable_service q-dhcp
enable_service q-l3
enable_service q-meta
enable_service q-lbaas
enable_service neutron

# Neutron Options
# VLAN configuration.
PUBLIC_SUBNET_NAME=public
PRIVATE_SUBNET_NAME=private
PUBLIC_INTERFACE=eth1
FIXED_RANGE=10.1.0.0/24
FIXED_NETWORK_SIZE=256
NETWORK_GATEWAY=10.1.0.1
# HOST_IP=192.168.1.109
FLOATING_RANGE=192.168.1.224/27
PUBLIC_NETWORK_GATEWAY=192.168.1.225
ENABLE_TENANT_VLANS=True
TENANT_VLAN_RANGE=3001:4000
PHYSICAL_NETWORK=default
OVS_PHYSICAL_BRIDGE=br-ex
PROVIDER_SUBNET_NAME="provider_net"
PROVIDER_NETWORK_TYPE="vlan"
SEGMENTATION_ID=2010
Q_PLUGIN=ml2
Q_USE_SECGROUP=True
Q_USE_PROVIDER_NETWORKING=True
Q_L3_ENABLED=True

# GRE tunnel configuration
# Q_PLUGIN=ml2
# ENABLE_TENANT_TUNNELS=True

# VXLAN tunnel configuration
# Q_PLUGIN=ml2
# Q_ML2_TENANT_NETWORK_TYPE=vxlan

# Enable Ceilometer - Metering Service (metering + alarming)
enable_service ceilometer-acompute
enable_service ceilometer-acentral
enable_service ceilometer-anotification
enable_service ceilometer-api
enable_service ceilometer-alarm-notifier
enable_service ceilometer-alarm-evaluator

# Enable Heat - Orchestration Service
enable_service heat
enable_service h-api
enable_service h-api-cfn
enagle_service h-api-cw
enable_service h-eng

# Images
IMAGE_URLS+="http://cloud-images.ubuntu.com/releases/14.04/release/ubuntu-14.04-server-cloudimg-amd64-disk1.img"

EOF

# Add iptables forwarding rule for neutron / eth0
sudo iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Copy files and fix permissions
sudo cp -rf ./devstack /home/stack/
sudo cp -rf ./heat-templates /home/stack/
sudo chown -R stack:stack /home/stack/*

# Change to stack user
cd /home/stack
sudo su stack