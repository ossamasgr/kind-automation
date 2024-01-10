# Running the Script
## Introduction
This README outlines the necessary steps to prepare and run the automated script of deploying a kind cluster. The script is designed to work in an environment with specific prerequisites and requires some initial setup for proper functionality.

## Prerequisites
Before running the script, ensure the following prerequisites are met:

- **Docker Installation:** Docker must be installed on your machine. Docker allows you to create, deploy, and run applications in containers, making it easier to manage dependencies and environments.
- **Ubuntu Machine:** The script is intended to be run on a machine with Ubuntu operating system. This ensures compatibility and smooth

## running of the script.
Before Running the Script
Certain files need to be modified to customize the script according to your environment and requirements.

### Modifying external-ips.yaml
Locate the file ingress-controller/external-ips.yaml.
Edit the spec section to include your public IPs.
```yaml
spec:
  externalIPs:
  - [YOUR_PUBLIC_IP_1]

```
Replace [YOUR_PUBLIC_IP_1]  with the public IP you wish to use. If only one IP is needed, simply provide one entry.

### Modifying issuer.yaml
Find the file cert-manager/issuer.yaml.
In the apiVersion: cert-manager.io/v1 section, locate the following fields:

```yaml
email: [YOUR_EMAIL]
```
Replace [YOUR_EMAIL] with your actual email address. This is used for ACME registration with Let's Encrypt.
## Running the Script
After ensuring all prerequisites are met and the necessary files are modified, you can proceed to run the script. 
```bash
bash script.sh
```
## Testing
To test the script, you need to deploy the contents of the /validation folder using Kubernetes.

### Preparing for Test Deployment
1. Modify validation/ingress.yaml:

- Open validation/ingress.yaml.
- Find the spec section.
- Replace [YOUR_DN] with your DNS name. This is crucial for routing and SSL certificate management.

```yaml 
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  annotations:
    kubernetes.io/ingress.class: nginx
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  name: ingress
  namespace: default
spec:
  tls:
    - hosts:
        - [YOUR_DN]
      secretName: hello-world-tls
  rules:
  - http:
      paths:
      - backend:
          service:
            name: hello-world
            port:
              number: 80
        path: /
        pathType: Prefix
```

2.Replace Placeholders:

- Ensure to replace [YOUR_DN] with your actual DNS name for proper configuration.
### Deploying for Test
- Execute the following command to apply the configuration:

```yaml
kubectl apply -f validation/.
```
This command deploys the configurations in the /validation folder, setting up the necessary environment for testing.


