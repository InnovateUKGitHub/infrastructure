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

# Provision a Kubernetes node on RHEL7 or RHEL Atomic
# https://access.redhat.com/documentation/
#+en/red-hat-enterprise-linux-atomic-host/version-7/getting-started-guide/

set -o nounset
set -o errexit
set -o pipefail

MNAME="k8smaster.devcluster.lite.bis.gov.uk"
HNAME="`hostname`"
MADDR="`getent ahosts $HNAME | tail -n1 | awk '{print$1}'`"
IDREG="registry.lite.bis.gov.uk"
DOMNAME="lite.local"
SKYDNSIP="10.254.1.1"

exec 1> >( sed "s/^/$(date '+[%F %T]'): /" | tee -a /tmp/provision.log) 2>&1

# If this is not Atomic install the appropriate software.
install_prerequisites () {
  DISTRO="`rpm -qf /etc/redhat-release 2>/dev/null`" || return
  if [ "${DISTRO%%-*}" = "redhat" ]
  then
    subscription-manager clean
    subscription-manager register --username=$SUB_USERNAME --password=$SUB_PASSWORD
    POOL_ID="`subscription-manager list --available | awk '$0~/^Pool\ ID/{print$3}' | tail -n1`"
    subscription-manager attach --pool=$POOL_ID
    subscription-manager repos --enable=rhel-7-server-extras-rpms
    subscription-manager repos --enable=rhel-7-server-optional-rpms
    yum install -y docker device-mapper-libs device-mapper-event-libs
    systemctl start docker.service
    systemctl enable docker.service
    yum install -y kubernetes-node etcd flannel
    systemctl disable firewalld
    systemctl stop firewalld
  else
    echo "Not Red Hat so crossing fingers"
  fi
}

install_prerequisites

# Set the Kubernetes config
sed -ie "s|KUBE_MASTER=\".*\"|KUBE_MASTER=\"--master=http://$MNAME:8080\"|" \
  /etc/kubernetes/config

# Set the Kubelet config
sed -ie 's|KUBELET_ADDRESS=".*"|KUBELET_ADDRESS="--address=0.0.0.0"|' \
  /etc/kubernetes/kubelet
sed -ie "s|KUBELET_HOSTNAME=\".*\"|KUBELET_HOSTNAME=\"--hostname-override=${HNAME}\"|" \
  /etc/kubernetes/kubelet
sed -ie "s|KUBELET_API_SERVER=\".*\"|KUBELET_API_SERVER=\"--api_servers=http://${MNAME}:8080\"|" \
  /etc/kubernetes/kubelet

KUBELET_ARGS="--register-node=true --config=/etc/kubernetes/manifests"
KUBELET_ARGS="$KUBELET_ARGS --resolv-conf=''"
KUBELET_ARGS="$KUBELET_ARGS --cluster-dns=${SKYDNSIP} --cluster-domain=${DOMNAME}"

sed -ie "s|KUBELET_ARGS=\".*\"|KUBELET_ARGS=\"${KUBELET_ARGS}\"|" \
  /etc/kubernetes/kubelet

# Edit the docker sysconfig
sed -ie "s|#\s*INSECURE_REGISTRY=.*|INSECURE_REGISTRY='--insecure-registry=${IDREG}'|" \
  /etc/sysconfig/docker

# Start the relevant services
for SERVICE in docker kube-proxy.service kubelet.service
do
  systemctl restart $SERVICE
  systemctl enable $SERVICE
done

# Set the Flannel config
sed -ie "s|FLANNEL_ETCD=\".*\"|FLANNEL_ETCD=\"http://${MNAME}:2379\"|" \
  /etc/sysconfig/flanneld
sed -ie 's|FLANNEL_ETCD_KEY=".*"|FLANNEL_ETCD_KEY="/coreos.com/network"|' \
  /etc/sysconfig/flanneld
sed -ie "s|#FLANNEL_OPTIONS=\".*\"|FLANNEL_OPTIONS=\"-iface=${MADDR}\"|" \
  /etc/sysconfig/flanneld

# Start Flannel
systemctl start flanneld
systemctl enable flanneld

# Set the default cluster config
su -l vagrant << __EOF__
kubectl config set-cluster default-cluster --server=http://${MNAME}:8080
kubectl config set-context default-system --cluster=default-cluster
kubectl config use-context default-system
__EOF__
