# MiniCRM Deployment Configurations


## Docker Image

All deployment methods use the pre-built Docker image from GitHub Container Registry:

```bash
docker pull ghcr.io/jasmaine/minicrm:latest
```

## Deployment Options

Choose the deployment method that best fits your needs:

### 1. Docker Compose (Recommended)
Multi-container setup with PostgreSQL database.

**Best for:** Small to medium deployments, production-ready

[📖 Docker Compose Guide](docker-compose/)

```bash
cd docker-compose
cp .env.example .env
# Edit .env with your configuration
docker-compose up -d
```

---

### 2. Kubernetes
Full Kubernetes deployment with StatefulSet PostgreSQL.

**Best for:** Large deployments, high availability, scalability

[📖 Kubernetes Guide](k8s/)

```bash
kubectl apply -f k8s/
```

---

### 3. Helm Chart
Templated Kubernetes deployment with easy customization.

**Best for:** Kubernetes deployments with custom configurations

[📖 Helm Guide](helm-chart/)

```bash
helm install minicrm ./helm-chart/minicrm
```

---

## Features

MiniCRM includes:

- **Contact Management** - Store and organize customer contacts
- **Company Management** - Track companies and link contacts
- **Email Campaigns** - Create and send email campaigns
- **Import/Export** - Bulk import contacts from CSV with duplicate detection
- **Media Library** - Store and manage images for emails
- **Activity Tracking** - Automatic logging of all actions
- **Multi-language** - 7 languages supported
- **Tag System** - Categorize contacts and companies

## Requirements

### Docker Compose
- Docker 20.10+
- Docker Compose 2.0+

### Kubernetes
- Kubernetes 1.24+
- kubectl configured
- Persistent storage provider

### Helm
- Helm 3.0+
- Kubernetes 1.24+

## Configuration

All deployment methods support these environment variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `DB_TYPE` | Database type (pgsql) | `pgsql` |
| `DB_HOST` | Database hostname | `localhost` |
| `DB_NAME` | Database name | `minicrm` |
| `DB_USER` | Database username | `minicrm` |
| `DB_PASSWORD` | Database password | - |
| `BASE_URL` | Application base URL | `http://localhost` |
| `SMTP_HOST` | SMTP server hostname | - |
| `SMTP_PORT` | SMTP server port | `587` |
| `SMTP_USER` | SMTP username | - |
| `SMTP_PASSWORD` | SMTP password | - |
| `SMTP_FROM_EMAIL` | Default sender email | - |
| `SMTP_FROM_NAME` | Default sender name | `MiniCRM` |

## Default Credentials

After installation, access the application and register the first user. The first user automatically becomes the admin.

**Important:** Change the admin password immediately after first login!

## Upgrading

### Docker Compose
```bash
docker pull ghcr.io/jasmaine/minicrm:latest
# Restart your containers
```

### Kubernetes
```bash
kubectl set image deployment/minicrm minicrm=ghcr.io/jasmaine/minicrm:latest -n minicrm
```

### Helm
```bash
helm upgrade minicrm ./helm-chart/minicrm
```

## Backup

### Database Backup

**Docker Compose:**
```bash
docker exec minicrm_postgres pg_dump -U minicrm minicrm > backup.sql
```

**Kubernetes:**
```bash
kubectl exec postgres-0 -n minicrm -- pg_dump -U minicrm minicrm > backup.sql
```

### Uploads Backup

**Docker Compose:**
```bash
docker cp minicrm_web:/var/www/html/uploads ./uploads-backup
```

**Kubernetes:**
```bash
kubectl cp minicrm/<pod-name>:/var/www/html/uploads ./uploads-backup
```

## License

This project is open source software.

---

**MiniCRM** - Lightweight CRM for small businesses
