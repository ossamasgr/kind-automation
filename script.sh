#!/bin/bash

# Function to check if the last command succeeded
check_success() {
    if [ $? -eq 0 ]; then
        echo "$1 [OK]"
    else
        echo "$1 [FAILED]"
        exit 1
    fi
}

# Function to wait until all pods in a namespace are ready
wait_for_pods() {
    echo "Waiting for all pods in the $1 namespace to be ready..."
    while true; do
        kubectl get pods -n $1
        if kubectl wait --for=condition=Ready pods --all -n $1 --timeout=60s; then
            break
        else
            echo "Waiting for pods to be ready..."
            sleep 10
        fi
    done
}

echo 'Installing Kind...'
# For AMD64 / x86_64
if [ "$(uname -m)" = "x86_64" ]; then
    curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
    chmod +x ./kind
    sudo mv ./kind /usr/local/bin/kind
    check_success 'Kind installation'
else
    echo 'Unsupported architecture'
    exit 1
fi

kind --version
check_success 'Kind version check'

echo 'Creating Kubernetes cluster...'
kind create cluster --config=config.yml
check_success 'Cluster creation'

echo 'Downloading and installing Kubectl...'
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x ./kubectl
sudo mv ./kubectl /usr/local/bin/kubectl
kubectl version --client
check_success 'Kubectl installation'

echo 'Downloading and installing Helm...'
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash
check_success 'Helm installation'

echo 'Deploying Ingress Controller...'
controller_tag=$(curl -s https://api.github.com/repos/kubernetes/ingress-nginx/releases/latest | grep tag_name | cut -d '"' -f 4)
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/${controller_tag}/deploy/static/provider/baremetal/deploy.yaml -O nginx-ingress-controller-deploy.yaml
kubectl apply -f nginx-ingress-controller-deploy.yaml
wait_for_pods ingress-nginx
check_success 'Ingress Controller deployment'

echo 'Configuring Ingress...'
kubectl -n ingress-nginx patch svc ingress-nginx-controller --patch "$(cat ingress-controller/external-ips.yaml)"
kubectl -n ingress-nginx patch deployment/ingress-nginx-controller --patch "$(cat ingress-controller/master-node-tolerations.yaml)"
check_success 'Ingress configuration'

echo 'Installing Cert-Manager...'
helm install cert-manager jetstack/cert-manager --namespace cert-manager --create-namespace --set installCRDs=true
wait_for_pods cert-manager
check_success 'Cert-Manager installation'

kubectl apply -f issuer.yaml
check_success 'Issuer application'

echo 'All tasks completed successfully.'
