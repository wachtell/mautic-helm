# Mautic Helm Chart

Production-ready Helm chart for deploying Mautic on Kubernetes.

Designed for:

- Kubernetes 1.31+
- Helm v3
- Traefik v3
- cert-manager
- Longhorn storage
- MariaDB
- Redis
- Authentik OIDC

## Features

✅ Mautic 7.x support  
✅ Persistent storage  
✅ MariaDB deployment  
✅ Redis support  
✅ SMTP configuration  
✅ Kubernetes CronJobs  
✅ TLS via cert-manager  
✅ Traefik ingress  
✅ Security contexts  
✅ Production defaults  

## Installation

```bash
helm dependency update ./mautic

helm install mautic ./mautic \
  --namespace mautic \
  --create-namespace \
  -f mautic/values-production.yaml