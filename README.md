# Mautic Helm Chart

Helm chart for deploying Mautic 7 on Kubernetes.

## Features

- Mautic 7 Apache image
- MariaDB dependency
- Redis dependency
- Traefik IngressRoute support
- Longhorn persistent storage
- Kubernetes CronJobs
- Horizontal Pod Autoscaling
- PodDisruptionBudget

## Install

```bash
helm install mautic . \
  -n mautic \
  --create-namespace \
  -f values-production.yaml

## Upgrade

```bash
helm upgrade mautic . \
  -n mautic \
  -f values-production.yaml