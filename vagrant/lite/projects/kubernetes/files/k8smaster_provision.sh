#!/usr/bin/env bash
# Copyright (c) 2016, Department for Business, Innovation and Skills
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the name of the <organization> nor the
#       names of its contributors may be used to endorse or promote products
#       derived from this software without specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL BIS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Provision a Kubernetes master on RHEL7 or RHEL Atomic
# https://access.redhat.com/documentation/
#+en/red-hat-enterprise-linux-atomic-host/version-7/getting-started-guide/

set -x

set -o nounset
set -o errexit
set -o pipefail

MNAME="`hostname`"
MADDR="`getent ahosts $MNAME | tail -n1 | awk '{print$1}'`"
IDREG="registry.lite.bis.gov.uk"

exec 1> >( sed "s/^/$(date '+[%F %T]'): /" | tee -a /tmp/provision.log) 2>&1

# If this is not Atomic install the appropriate software.
install_prerequisites () {
  DISTRO="`rpm -qf /etc/redhat-release 2>/dev/null`" || return
  if [ "${DISTRO%%-*}" = "redhat" ]
  then
    subscription-manager clean
    #subscription-manager register --username=$SUB_USERNAME --password=$SUB_PASSWORD
    #POOL_ID="`subscription-manager list --available | awk '$0~/^Pool\ ID/{print$3}' | tail -n1`"
    #subscription-manager attach --pool=$POOL_ID
    subscription-manager register --auto-attach --username=$SUB_USERNAME --password=$SUB_PASSWORD
    subscription-manager repos --enable=rhel-7-server-extras-rpms
    subscription-manager repos --enable=rhel-7-server-optional-rpms
    yum install -y docker device-mapper-libs device-mapper-event-libs
    systemctl start docker.service
    systemctl enable docker.service
    yum install -y kubernetes etcd flannel
    systemctl disable firewalld
    systemctl stop firewalld
    sed -ie 's|^SELINUX=.*|SELINUX=permissive|' /etc/selinux/config
    setenforce 0
  else
    echo "Not Red Hat so crossing fingers"
  fi
}

install_prerequisites

# Edit the /etc/etcd/etcd.conf and place the correct values
sed -ie "s|ETCD_ADVERTISE_CLIENT_URLS=\".*\"|ETCD_ADVERTISE_CLIENT_URLS=\"http://${MADDR}:2379\"|" \
  /etc/etcd/etcd.conf
sed -ie 's|ETCD_LISTEN_CLIENT_URLS=".*"|ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"|' \
  /etc/etcd/etcd.conf
sed -ie 's|#ETCD_LISTEN_PEER_URLS=".*"|ETCD_LISTEN_PEER_URLS="http://localhost:2380"|' \
  /etc/etcd/etcd.conf

# Edit the Kubernetes config file
sed -ie "s|KUBE_MASTER=\".*\"|KUBE_MASTER=\"--master=http://${MNAME}:8080\"|" \
  /etc/kubernetes/config

# Edit the Kubernetes API server config
sed -ie "s|KUBE_API_ADDRESS=\".*\"|KUBE_API_ADDRESS=\"--insecure-bind-address=${MADDR}\"|" \
  /etc/kubernetes/apiserver

# Edit the docker sysconfig
sed -ie "s|#\s*INSECURE_REGISTRY=.*|INSECURE_REGISTRY='--insecure-registry=${IDREG}'|" \
  /etc/sysconfig/docker

# Start master systemd services
for SERVICES in docker etcd
do
  systemctl restart $SERVICES
  systemctl enable $SERVICES
done

sleep 2

# Upload Flannel config to etcd services
etcdctl set coreos.com/network/config << __EOF__
{
  "Network": "10.20.0.0/16",
  "SubnetLen": 24,
  "Backend": {
    "Type": "vxlan",
    "VNI": 1
  }
}
__EOF__

# Configure Flannel config
sed -ie "s|FLANNEL_ETCD=\".*\"|FLANNEL_ETCD=\"http://${MNAME}:2379\"|" \
  /etc/sysconfig/flanneld
sed -ie 's|FLANNEL_ETCD_KEY=".*"|FLANNEL_ETCD_KEY="/coreos.com/network"|' \
  /etc/sysconfig/flanneld
sed -ie "s|#FLANNEL_OPTIONS=\".*\"|FLANNEL_OPTIONS=\"-iface=${MADDR}\"|" \
  /etc/sysconfig/flanneld

# Force Docker to load the new config
systemctl stop docker
ip link del docker0
#systemctl enable docker

# Enable flanneld and reboot so all systems pick up
systemctl enable flanneld
