# MiniCRM Kubernetes Deployment

This directory contains Kubernetes manifests for deploying MiniCRM to a Kubernetes cluster.

## Prerequisites

- Kubernetes cluster (1.21+)
- kubectl configured
- NGINX Ingress Controller installed
- cert-manager installed (for automatic SSL certificates)
- StorageClass configured (for PersistentVolumes)

## Quick Start

### 1. Update Configuration

**Edit `secrets.yaml`** and replace the default passwords:
```bash
# Or create secret via kubectl
kubectl create secret generic minicrm-secrets \
  --from-literal=DB_USER=minicrm \
  --from-literal=DB_PASSWORD=your-secure-password \
  --from-literal=POSTGRES_PASSWORD=your-postgres-password \
  -n minicrm
```

**Edit `ingress.yaml`** and replace `minicrm.example.com` with your actual domain.

### 2. Build and Push Docker Image

```bash
# Build the image
docker build -t your-registry/minicrm:latest .

# Push to your registry
docker push your-registry/minicrm:latest

# Update minicrm-deployment.yaml with your image name
```

### 3. Deploy to Kubernetes

```bash
# Create namespace
kubectl apply -f namespace.yaml

# Create secrets (if not created via kubectl)
kubectl apply -f secrets.yaml

# Create ConfigMap
kubectl apply -f configmap.yaml

# Create PersistentVolumeClaims
kubectl apply -f postgres-pvc.yaml
kubectl apply -f uploads-pvc.yaml

# Deploy PostgreSQL
kubectl apply -f postgres-statefulset.yaml
kubectl apply -f postgres-service.yaml

# Wait for PostgreSQL to be ready
kubectl wait --for=condition=ready pod -l app=postgres -n minicrm --timeout=300s

# Deploy MiniCRM application
kubectl apply -f minicrm-deployment.yaml
kubectl apply -f minicrm-service.yaml

# Create Ingress
kubectl apply -f ingress.yaml

# Optional: Enable auto-scaling
kubectl apply -f hpa.yaml
```

### 4. Verify Deployment

```bash
# Check all resources
kubectl get all -n minicrm

# Check pods
kubectl get pods -n minicrm

# Check services
kubectl get svc -n minicrm

# Check ingress
kubectl get ingress -n minicrm

# View logs
kubectl logs -f deployment/minicrm -n minicrm

# Check PostgreSQL
kubectl logs -f statefulset/postgres -n minicrm
```

## Manifest Files

- **namespace.yaml** - Creates the minicrm namespace
- **configmap.yaml** - Application configuration
- **secrets.yaml** - Database credentials (MUST be updated)
- **postgres-pvc.yaml** - PostgreSQL persistent storage (10Gi)
- **uploads-pvc.yaml** - Uploads persistent storage (20Gi, ReadWriteMany)
- **postgres-statefulset.yaml** - PostgreSQL StatefulSet
- **postgres-service.yaml** - PostgreSQL headless service
- **minicrm-deployment.yaml** - MiniCRM application deployment
- **minicrm-service.yaml** - MiniCRM ClusterIP service
- **ingress.yaml** - NGINX Ingress with SSL
- **hpa.yaml** - Horizontal Pod Autoscaler (2-10 replicas)

## Storage Requirements

### ReadWriteMany for Uploads

The uploads PVC requires `ReadWriteMany` access mode since multiple MiniCRM pods need to access uploaded files. Options:

1. **NFS StorageClass** (Recommended for production)
   ```bash
   # Install NFS provisioner
   helm repo add nfs-subdir-external-provisioner \
     https://kubernetes-sigs.github.io/nfs-subdir-external-provisioner/

   helm install nfs-provisioner nfs-subdir-external-provisioner/nfs-subdir-external-provisioner \
     --set nfs.server=your-nfs-server \
     --set nfs.path=/exported/path
   ```

2. **Cloud Provider Storage**
   - AWS: EFS
   - GCP: Filestore
   - Azure: Azure Files

3. **Single Replica (Development)**
   - Set `replicas: 1` in minicrm-deployment.yaml
   - Change uploads-pvc to `ReadWriteOnce`

## SSL/TLS Certificates

### Using cert-manager (Recommended)

The ingress.yaml is configured to use cert-manager with Let's Encrypt:

```bash
# Install cert-manager
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml

# Create ClusterIssuer
kubectl apply -f - <<EOF
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    server: https://acme-v02.api.letsencrypt.org/directory
    email: your-email@example.com
    privateKeySecretRef:
      name: letsencrypt-prod
    solvers:
    - http01:
        ingress:
          class: nginx
EOF
```

Certificates will be automatically provisioned when you create the Ingress.

### Using Existing Certificates

```bash
# Create TLS secret from existing certs
kubectl create secret tls minicrm-tls \
  --cert=path/to/tls.crt \
  --key=path/to/tls.key \
  -n minicrm

# Remove cert-manager annotation from ingress.yaml
```

## Database Initialization

The PostgreSQL StatefulSet expects a schema initialization script. Create a ConfigMap:

```bash
# Create ConfigMap from schema file
kubectl create configmap postgres-init-script \
  --from-file=schema.sql=database/schema_postgres.sql \
  -n minicrm
```

Or uncomment the volume mount in postgres-statefulset.yaml.

## Monitoring and Logs

### View Application Logs

```bash
# All MiniCRM pods
kubectl logs -f -l app=minicrm -n minicrm

# Specific pod
kubectl logs -f pod/minicrm-xxxx-yyyy -n minicrm

# PostgreSQL logs
kubectl logs -f statefulset/postgres -n minicrm
```

### Port Forwarding (for debugging)

```bash
# Access MiniCRM locally
kubectl port-forward svc/minicrm-service 8080:80 -n minicrm
# Then visit http://localhost:8080

# Access PostgreSQL locally
kubectl port-forward svc/postgres-service 5432:5432 -n minicrm
# Then connect with: psql -h localhost -U minicrm -d minicrm
```

### Check Resource Usage

```bash
# Pod resource usage
kubectl top pods -n minicrm

# Node resource usage
kubectl top nodes

# HPA status
kubectl get hpa -n minicrm
```

## Scaling

### Manual Scaling

```bash
# Scale MiniCRM deployment
kubectl scale deployment minicrm --replicas=5 -n minicrm

# Check scaling status
kubectl get deployment minicrm -n minicrm
```

### Auto-scaling (HPA)

The HPA is configured to scale between 2-10 replicas based on CPU and memory usage.

```bash
# View HPA status
kubectl get hpa minicrm-hpa -n minicrm

# Describe HPA
kubectl describe hpa minicrm-hpa -n minicrm
```

## Backup and Recovery

### Database Backup

```bash
# Create backup
kubectl exec -it postgres-0 -n minicrm -- \
  pg_dump -U minicrm minicrm | gzip > backup-$(date +%Y%m%d).sql.gz

# Restore from backup
gunzip < backup-20251125.sql.gz | \
  kubectl exec -i postgres-0 -n minicrm -- \
  psql -U minicrm -d minicrm
```

### Uploads Backup

```bash
# Create uploads tarball
kubectl exec -it deployment/minicrm -n minicrm -- \
  tar czf - /var/www/html/uploads > uploads-backup-$(date +%Y%m%d).tar.gz

# Restore uploads
kubectl exec -i deployment/minicrm -n minicrm -- \
  tar xzf - -C /var/www/html < uploads-backup-20251125.tar.gz
```

## Troubleshooting

### Pods Not Starting

```bash
# Check pod status
kubectl get pods -n minicrm

# Describe pod for events
kubectl describe pod minicrm-xxxx-yyyy -n minicrm

# Check logs
kubectl logs minicrm-xxxx-yyyy -n minicrm
```

### Database Connection Issues

```bash
# Check PostgreSQL is ready
kubectl get pods -l app=postgres -n minicrm

# Test connection from MiniCRM pod
kubectl exec -it deployment/minicrm -n minicrm -- \
  pg_isready -h postgres-service -U minicrm

# Check secrets
kubectl get secret minicrm-secrets -n minicrm -o yaml
```

### Storage Issues

```bash
# Check PVCs
kubectl get pvc -n minicrm

# Describe PVC
kubectl describe pvc postgres-pvc -n minicrm
kubectl describe pvc uploads-pvc -n minicrm

# Check PVs
kubectl get pv
```

### Ingress Not Working

```bash
# Check ingress
kubectl get ingress -n minicrm

# Describe ingress
kubectl describe ingress minicrm-ingress -n minicrm

# Check NGINX Ingress Controller logs
kubectl logs -n ingress-nginx -l app.kubernetes.io/component=controller
```

## Cleanup

```bash
# Delete all resources
kubectl delete -f .

# Delete namespace (removes everything)
kubectl delete namespace minicrm

# Delete PersistentVolumes (if needed)
kubectl delete pv --selector app=minicrm
```

## Production Recommendations

1. **Use a Private Container Registry** - Store images in private registry (Docker Hub, GCR, ECR, ACR)

2. **Enable Network Policies** - Restrict pod-to-pod communication

3. **Set Resource Requests/Limits** - Already configured in manifests

4. **Enable Pod Security Policies** - Restrict pod capabilities

5. **Use Secrets Management** - Consider Sealed Secrets or external secret stores (Vault, AWS Secrets Manager)

6. **Set up Monitoring** - Use Prometheus + Grafana for metrics

7. **Configure Backups** - Automate database and uploads backups

8. **Enable Logging** - Use ELK stack or Loki for log aggregation

9. **Use Multiple Replicas** - Already configured (2 minimum)

10. **Configure Affinity Rules** - Spread pods across nodes

## Support

For issues or questions:
- Check the main DEPLOYMENT.md for general deployment guidance
- Check SECURITY.md for security best practices
- Review Kubernetes documentation: https://kubernetes.io/docs/
