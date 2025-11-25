# MiniCRM Helm Chart

A Helm chart for deploying MiniCRM to Kubernetes.

## Introduction

This chart bootstraps a MiniCRM deployment on a Kubernetes cluster using the Helm package manager.

## Prerequisites

- Kubernetes 1.21+
- Helm 3.0+
- PV provisioner support in the underlying infrastructure (for persistence)
- NGINX Ingress Controller (for ingress)
- cert-manager (for automatic SSL certificates, optional)

## Installing the Chart

### Quick Install

```bash
# Install with default values
helm install minicrm ./minicrm

# Install with custom values
helm install minicrm ./minicrm -f custom-values.yaml

# Install in specific namespace
helm install minicrm ./minicrm --namespace minicrm --create-namespace
```

### Install with Custom Values

Create a `custom-values.yaml` file:

```yaml
ingress:
  hosts:
    - host: crm.yourcompany.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: minicrm-tls
      hosts:
        - crm.yourcompany.com

minicrm:
  secrets:
    dbPassword: "your-secure-database-password"
    postgresPassword: "your-secure-postgres-password"

image:
  repository: your-registry/minicrm
  tag: "1.0.0"
```

Then install:

```bash
helm install minicrm ./minicrm -f custom-values.yaml
```

## Uninstalling the Chart

```bash
helm uninstall minicrm
```

This command removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following table lists the configurable parameters and their default values.

### Global Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `app.name` | Application name | `minicrm` |
| `app.environment` | Environment name | `production` |
| `app.debug` | Enable debug mode | `false` |

### Image Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `image.repository` | Image repository | `minicrm` |
| `image.pullPolicy` | Image pull policy | `IfNotPresent` |
| `image.tag` | Image tag | `latest` |
| `imagePullSecrets` | Image pull secrets | `[]` |

### Service Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `service.type` | Service type | `ClusterIP` |
| `service.port` | Service port | `80` |
| `service.targetPort` | Container port | `80` |

### Ingress Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `true` |
| `ingress.className` | Ingress class name | `nginx` |
| `ingress.hosts` | Ingress hosts | `[minicrm.example.com]` |
| `ingress.tls` | TLS configuration | See values.yaml |

### MiniCRM Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `minicrm.replicaCount` | Number of replicas | `2` |
| `minicrm.resources.requests.memory` | Memory request | `512Mi` |
| `minicrm.resources.requests.cpu` | CPU request | `500m` |
| `minicrm.resources.limits.memory` | Memory limit | `2Gi` |
| `minicrm.resources.limits.cpu` | CPU limit | `2000m` |
| `minicrm.secrets.dbPassword` | Database password | `CHANGE_ME_SECURE_PASSWORD` |

### PostgreSQL Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `postgresql.enabled` | Enable PostgreSQL | `true` |
| `postgresql.image.tag` | PostgreSQL image tag | `15-alpine` |
| `postgresql.database.name` | Database name | `minicrm` |
| `postgresql.database.user` | Database user | `minicrm` |
| `postgresql.persistence.enabled` | Enable persistence | `true` |
| `postgresql.persistence.size` | PVC size | `10Gi` |

### Autoscaling Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `autoscaling.enabled` | Enable HPA | `true` |
| `autoscaling.minReplicas` | Minimum replicas | `2` |
| `autoscaling.maxReplicas` | Maximum replicas | `10` |
| `autoscaling.targetCPUUtilizationPercentage` | Target CPU % | `70` |
| `autoscaling.targetMemoryUtilizationPercentage` | Target memory % | `80` |

## Examples

### Production Deployment with External PostgreSQL

```yaml
# values-prod.yaml
minicrm:
  replicaCount: 3
  secrets:
    dbPassword: "prod-secure-password"
  env:
    DB_HOST: "external-postgres.example.com"
    DB_PORT: "5432"

postgresql:
  enabled: false  # Use external PostgreSQL

ingress:
  hosts:
    - host: crm.company.com
      paths:
        - path: /
          pathType: Prefix

autoscaling:
  minReplicas: 3
  maxReplicas: 20
```

Deploy:
```bash
helm install minicrm ./minicrm -f values-prod.yaml
```

### Development Deployment

```yaml
# values-dev.yaml
minicrm:
  replicaCount: 1
  env:
    ENVIRONMENT: development
    APP_DEBUG: "true"

postgresql:
  persistence:
    size: 5Gi

autoscaling:
  enabled: false

ingress:
  hosts:
    - host: minicrm-dev.local
```

Deploy:
```bash
helm install minicrm-dev ./minicrm -f values-dev.yaml
```

## Upgrading

```bash
# Upgrade with new values
helm upgrade minicrm ./minicrm -f custom-values.yaml

# Upgrade with specific chart version
helm upgrade minicrm ./minicrm --version 1.0.1

# View upgrade history
helm history minicrm

# Rollback to previous version
helm rollback minicrm
```

## Troubleshooting

### View Logs

```bash
# MiniCRM logs
kubectl logs -f -l app.kubernetes.io/name=minicrm

# PostgreSQL logs
kubectl logs -f -l app.kubernetes.io/component=database
```

### Debug Deployment

```bash
# Get deployment status
helm status minicrm

# Get all resources
kubectl get all -l app.kubernetes.io/instance=minicrm

# Describe problematic pod
kubectl describe pod <pod-name>
```

### Common Issues

1. **Pods not starting**: Check events with `kubectl describe pod`
2. **Database connection failed**: Verify PostgreSQL is running and secrets are correct
3. **Ingress not working**: Check NGINX Ingress Controller is installed
4. **SSL certificate issues**: Verify cert-manager is installed and configured

## Support

For support and issues:
- Check the main documentation
- Review Helm chart values
- Check application logs
- Consult Kubernetes documentation
