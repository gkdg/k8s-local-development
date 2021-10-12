# Arhitecture
![Architecture](Vagrant&Sysbox&K8s.drawio.png?raw=true)
This system uses [Sysbox](https://github.com/nestybox/sysbox) and [Vagrant](https://www.vagrantup.com/). It creates a kubernetes cluster with a control plane node and two worker nodes inside docker containers. Ready to use out of the box.

# Introduction
Local development on Kubernetes can be complex and painful. Tools like [minikube](https://minikube.sigs.k8s.io/docs/) provides convenient way to deploy a local K8s cluster on your machine but without additional nodes. That leaves you with a single node which can only mimic production environment so far. 

On the other hand if you want to create K8s cluster for development you can either use cloud provider to spin up a cluster with the amount of nodes you want or you can use some servers lying around in your office or at home. First one requires some more configuration and a budget the second one is not likely nowadays in the age of cloud.

While searching for a solution I have put some technologies together to make a convenient way for local K8s cluster for development and learning purposes.

# Prerequisites
- Vagrant installed.
- Virtual box installed.

# Usage
- Copy the repo to your machine.
- Go to root folder of the project directory
- Build the guest virtual machine
```sh
vagrant up
```
- Connect to your machine
```sh
vagrant ssh
```
- View your nodes
```sh
sudo kubectl get nodes --kubeconfig .kube/config
```
Now you can deploy some stuff into your cluster.

# Warning
For the moment its better to use `sudo` and `--kubeconfig` flag with the path to the configuration file `.kube/config`. I will try to improve file and user permission issues in the near future.
