#!/bin/bash

#Install docker.

if sudo apt-get update ; then
    echo "SUCCESS: linux system is successfully updated"
else
    echo "ERROR: system update failed with status: $?"
fi

if sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release; then
    echo "SUCCESS: Ubuntu packages required for docker successfully installed"
else
    echo "ERROR: Installing packages failed with status: $?"
fi

if curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg; then
    echo "SUCCESS: Docker's official gpg key is successfully added"
else
    echo "ERROR: Failed to add Docker's gpg key with status: $?"
fi

if echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null; then
    echo "SUCCESS: Stable repository set"
else
    echo "ERROR: Failed to set up stable repository with status: $?"
fi

if sudo apt-get update && sudo apt-get install -y docker-ce docker-ce-cli containerd.io; then
    if sudo docker --version; then
        echo "SUCCESS: Docker successfully installed"
    fi
else
    echo "ERROR: Failed to install docker with status: $?"
fi

#Install sysbox docker runtime engine.
if curl -L https://downloads.nestybox.com/sysbox/releases/v0.4.1/sysbox-ce_0.4.1-0.ubuntu-focal_amd64.deb --output sysbox-ce_0.4.1-0.ubuntu-focal_amd64.deb && sudo apt-get install -y ./sysbox-ce_0.4.1-0.ubuntu-focal_amd64.deb; then
    echo "SUCCESS: sysbox runtime engine successfully installed"
else
    echo "ERROR: Failed to install sysbox runtime engine with status: $?"
fi

modinfo shiftfs
result=$?
if [$result -eq 0]; then
    echo "installing kubectl on the VM Host..."
fi

#Install kubectl.
if sudo apt-get update &&
    sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg &&
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list &&
    sudo apt-get update &&
    sudo apt-get install -y kubectl &&
    kubectl version --client; then
    echo "SUCCESS: kubectl installed on the VM Host successfully"
else
    echo "ERROR: failed to install kubectl with status: $?"
fi

sudo mkdir /home/vagrant/.kube && sudo docker run --runtime=sysbox-runc -d --rm --name=k8s-master --hostname=k8s-master nestybox/k8s-node:v1.18.2;
echo "creating control plane"
sleep 20

if sudo docker exec k8s-master sh -c "kubeadm init --kubernetes-version=v1.18.2 --pod-network-cidr=10.244.0.0/16"; then
    echo "SUCCESS: kubeadm started inside the control plane node"
else
    echo "ERROR: kubeadm init failed with status: $?"
fi

if sudo docker cp k8s-master:/etc/kubernetes/admin.conf /home/vagrant/.kube/config; then
    echo "SUCCESS: host kubectl configured successfully"
else
    echo "ERROR: failed to copy config file into the host machine with status: $?"
fi

echo "DIRECTORY:::::"
pwd
if sudo kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml --kubeconfig /home/vagrant/.kube/config; then
    echo "creating flannel CNI for the cluster..."
    sleep 20
    if sudo kubectl get all --all-namespaces --kubeconfig /home/vagrant/.kube/config; then
        echo "SUCCESS: cluster network up and running!"
    else
        echo "ERROR: failed to configure networking with status: $?"
    fi
fi

for i in {1..2};
do
    echo "creating worker node $i..."
    if sudo docker run --runtime=sysbox-runc -d --rm --name=k8s-worker$i --hostname=k8s-worker$i nestybox/k8s-node:v1.18.2; then
        sleep 3 &&
        echo "SUCCESS: worker nodes are successfull created"
    else
        echo "ERROR: failed to create worker$i with status: $?"
    fi
done

if join_cmd=$(sudo docker exec k8s-master sh -c "kubeadm token create --print-join-command 2> /dev/null"); then
    echo "SUCCESS: join config prepared."
else
    echo "ERROR: failed to create join config with status: $?"
fi

for i in {1..2};
do
    echo "worker$i joining the cluster..."
    if  sudo docker exec k8s-worker$i sh -c "$join_cmd"; then
        echo "SUCCESS: worker$i joined to cluster!"
    else
        echo "ERROR: worker$i failed to join cluster with status: $?"
    fi
done