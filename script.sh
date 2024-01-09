#!/bin/bash
echo 'installing Kind ...'
# For AMD64 / x86_64
[ $(uname -m) = x86_64 ] && curl -Lo ./kind https://kind.sigs.k8s.io/dl/v0.20.0/kind-linux-amd64
chmod +x ./kind
sudo cp ./kind /usr/local/bin/kind
rm -rf kind
echo 'kind installation [ok]'
kind --version
echo 'installing Kubernetes cluster'

# Creating the Cluster
kind create cluster --config=config.yml
echo 'Downloading Kubectl'
# Download the latest version of kubectl
curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl"

# Make the kubectl binary executable
chmod +x ./kubectl

# Move the binary to a directory in your PATH
sudo mv ./kubectl /usr/local/bin/kubectl

# Verify the installation
kubectl version --client
# Download and install the latest version of Helm
curl https://raw.githubusercontent.com/helm/helm/master/scripts/get-helm-3 | bash

echo 'Kubectl Installation [Done]'
# ingress
echo 'Deploying Ingress Controller'
controller_tag=$(curl -s https://api.github.com/repos/kubernetes/ingress-nginx/releases/latest | grep tag_name | cut -d '"' -f 4)
wget https://raw.githubusercontent.com/kubernetes/ingress-nginx/${controller_tag}/deploy/static/provider/baremetal/deploy.yaml
mv deploy.yaml nginx-ingress-controller-deploy.yaml
kubectl apply -f nginx-ingress-controller-deploy.yaml
# wait until pods all running and ready or completed

# Ingress config
kubectl -n ingress-nginx patch svc ingress-nginx-controller --patch "$(cat ingress-controller/external-ips.yaml)"
kubectl -n ingress-nginx patch deployment/ingress-nginx-controller --patch "$(cat ingress-controller/master-node-tolerations.yaml)"
# Cert-manager installation
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
 --set installCRDs=true
# Wait
kubectl apply -f issuer.yaml
