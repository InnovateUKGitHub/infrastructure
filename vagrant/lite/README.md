# BIS Vagrant

LITE primarily use the Kubernetes project. It's definitions are in projects/kubernetes.

## Red Hat Subscription

In order to use the environment, you will need to create a file in the variables
directory with two variables that authenticate you to Red Hat Enterprise Linux
Developer Suite. 

https://www.redhat.com/apps/store/developers/rhel_developer_suite.html

You must be subscribed to this product. Also, you will need to
obtain a valid RHEL7 Vagrant box. In the projects/kubernetes/variables/network.yaml
file, the box is defined as jhcook/rhel7.

Git is instructed to ignore the variables/personal.yaml in the variables/.gitignore
file.

```
$ cat variables/personal.yaml
---

rh_username: "justin@blabla.com"
rh_password: "somePassword"

$ cat variables/.gitignore
personal.yaml
```

## Adding the box

Once you have obtained a valid RHEL7 box, please add it to the Vagrant cache.

```
$ vagrant box add --name <box_name> ./path/to/rhel7.box
```

## Preparing Vagrant

There are plugins that are necessary to install in Vagrant in order to
properly use the RHEL7 boxes. 

```
$ vagrant plugin list
vagrant-dotvm (0.39.0)
vagrant-registration (1.2.1)
vagrant-reload (0.0.1)
vagrant-service-manager (1.0.2)
vagrant-share (1.1.5, system)
```

## Usage

By default, commands are directed toward the Kubernetes master box. Therefore,
Vagrant ssh access does not need to be specified to the master.

```
$ vagrant group up k8s
...
$ vagrant ssh
```

Once you have created the environment, you will notice Kubernetes functions as
a three-node cluster.

```
[vagrant@k8smaster ~]$ kubectl get nodes
NAME                                  STATUS    AGE
k8snode1.devcluster.lite.bis.gov.uk   Ready     1h
k8snode2.devcluster.lite.bis.gov.uk   Ready     1h
[vagrant@k8smaster ~]$ sudo docker ps
CONTAINER ID        IMAGE                                                        COMMAND                  CREATED             STATUS              PORTS               NAMES
10406d168d73        rhel7/kubernetes-controller-mgr                              "/usr/bin/kube-contro"   About an hour ago   Up About an hour                        k8s_kube-controller-manager.d31bb258_kube-controller-manager-k8smaster.devcluster.lite.bis.gov.uk_default_3ae86699b27fd8cffb9e684a58c50f34_f8bcdd3b
1d0b653527b3        rhel7/kubernetes-apiserver                                   "/usr/bin/kube-apiser"   About an hour ago   Up About an hour                        k8s_kube-apiserver.d37747b4_kube-apiserver-k8smaster.devcluster.lite.bis.gov.uk_default_e94cd7ca5c14ffadec853314a548908c_1597fda4
64beb9c1667a        rhel7/kubernetes-scheduler                                   "/usr/bin/kube-schedu"   About an hour ago   Up About an hour                        k8s_kube-scheduler.5a889386_kube-scheduler-k8smaster.devcluster.lite.bis.gov.uk_default_b3fb728e5d7bf5e5f8e0dbb1d35d4a01_370e7219
7f344ee74454        registry.access.redhat.com/rhel7/pod-infrastructure:latest   "/pod"                   About an hour ago   Up About an hour                        k8s_POD.ae8ee9ac_kube-apiserver-k8smaster.devcluster.lite.bis.gov.uk_default_e94cd7ca5c14ffadec853314a548908c_cf0f7db8
50058bfc618e        registry.access.redhat.com/rhel7/pod-infrastructure:latest   "/pod"                   About an hour ago   Up About an hour                        k8s_POD.ae8ee9ac_kube-scheduler-k8smaster.devcluster.lite.bis.gov.uk_default_b3fb728e5d7bf5e5f8e0dbb1d35d4a01_56a22389
5fe40a76b6fb        registry.access.redhat.com/rhel7/pod-infrastructure:latest   "/pod"                   About an hour ago   Up About an hour                        k8s_POD.ae8ee9ac_kube-controller-manager-k8smaster.devcluster.lite.bis.gov.uk_default_3ae86699b27fd8cffb9e684a58c50f34_32c18550
```
