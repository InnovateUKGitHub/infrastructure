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

# Provision a Kubernetes master on CentOS Atomic
# https://access.redhat.com/documentation/
#+en/red-hat-enterprise-linux-atomic-host/version-7/getting-started-guide/

set -o nounset
set -o errexit
set -o pipefail

HNAME="k8smaster"
MADDR="10.100.1.11"

exec 1> >( sed "s/^/$(date '+[%F %T]'): /" | tee -a /tmp/provision.log) 2>&1

# Edit the /etc/etcd/etcd.conf and place the correct values
sed -ie 's|ETCD_ADVERTISE_CLIENT_URLS=".*"|ETCD_ADVERTISE_CLIENT_URLS="http://0.0.0.0:2379"|' \
  /etc/etcd/etcd.conf
sed -ie 's|ETCD_LISTEN_CLIENT_URLS=".*"|ETCD_LISTEN_CLIENT_URLS="http://0.0.0.0:2379"|' \
  /etc/etcd/etcd.conf
sed -ie 's|#ETCD_LISTEN_PEER_URLS=".*"|ETCD_LISTEN_PEER_URLS="http://localhost:2380"|' \
  /etc/etcd/etcd.conf

# Edit the Kubernetes config file
sed -ie "s|KUBE_MASTER=\".*\"|KUBE_MASTER=\"--master=http://${HNAME}:8080\"|" \
  /etc/kubernetes/config

# Edit the Kubernetes API server config
sed -ie "s|KUBE_API_ADDRESS=\".*\"|KUBE_API_ADDRESS=\"--insecure-bind-address=${MADDR}\"|" \
  /etc/kubernetes/apiserver

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
sed -ie "s|FLANNEL_ETCD=\".*\"|FLANNEL_ETCD=\"http://${HNAME}:2379\"|" /etc/sysconfig/flanneld
sed -ie 's|FLANNEL_ETCD_KEY=".*"|FLANNEL_ETCD_KEY="/coreos.com/network"|' /etc/sysconfig/flanneld

# Force Docker to load the new config
systemctl stop docker
ip link del docker0
systemctl enable docker

# Enable flanneld and reboot so all systems pick up
systemctl enable flanneld
