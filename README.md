# MiniCRM Deployment Configurations

A modern, lightweight CRM system for managing customers, contacts, and communications.

## Features

- **Customer Management** - Track customers, prospects, partners, and vendors
- **Contact Management** - Manage contacts associated with customers
- **Import/Export** - Bulk import contacts from CSV with duplicate detection and automatic company matching
- **Email Campaigns** - Create and send HTML email campaigns with templates
- **Template Builder** - Drag-and-drop email template builder
- **Task Management** - Create and assign tasks with due dates
- **Activity Tracking** - Automatic logging of all user activities
- **File Management** - Upload and manage files related to customers
- **Media Library** - Store and manage images for email campaigns
- **OAuth Authentication** - Secure login with Google and Microsoft
- **Multi-language Support** - 7 languages: English, Dutch, French, German, Spanish, Italian, Turkish
- **Email Tracking** - Track email opens and link clicks
- **Responsive Design** - Works on desktop, tablet, and mobile
- **Queue Worker** - Background email sending with queue management

## Technology Stack

- **Backend**: PHP 8.2, PDO for database access
- **Frontend**: Vanilla JavaScript, modern CSS
- **Database**: PostgreSQL 
- **Email**: PHPMailer with SMTP support
- **Architecture**: MVC pattern, RESTful API design
- **Deployment**: Docker, Kubernetes, Helm

## Quick Start

The easiest way to deploy MiniCRM is using the automated installation script:

```bash
curl -fsSL https://raw.githubusercontent.com/jasmaine/minicrm-deploy/master/install.sh | bash
```

Or download and run manually:

```bash
wget https://raw.githubusercontent.com/jasmaine/minicrm-deploy/master/install.sh
chmod +x install.sh
./install.sh
```

The script will guide you through:
- Choosing your deployment method (Docker Compose, Kubernetes, or Helm)
- Setting up database credentials
- Configuring your domain and SSL (for Kubernetes/Helm)
- Installing all necessary components

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

**Includes:**
- NGINX Ingress Controller support
- Automatic SSL/TLS with cert-manager and Let's Encrypt
- LoadBalancer service
- Security headers (X-Frame-Options, X-XSS-Protection, etc.)
- Rate limiting
- Persistent storage for uploads and database

[📖 Kubernetes Guide](k8s/)

```bash
kubectl apply -f k8s/
```

**Note:** Before deploying, edit `k8s/ingress.yaml` to replace `crm.example.eu` with your domain name.

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
- **Multi-language** - 7 languages supported (NL, EN, FR, DE, IT, ES, TR)
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

## SSL/TLS and Ingress Setup (Kubernetes)

The Kubernetes deployment includes a pre-configured Ingress with automatic SSL/TLS certificate provisioning.

### Prerequisites

1. **NGINX Ingress Controller** - Install if not already present:
```bash
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.8.1/deploy/static/provider/cloud/deploy.yaml
```

2. **cert-manager** - For automatic SSL certificates from Let's Encrypt:
```bash
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.0/cert-manager.yaml
```

3. **ClusterIssuer** - Configure Let's Encrypt (included in k8s/ directory):
```bash
kubectl apply -f k8s/cert-manager-issuer.yaml
```

### Configure Your Domain

Edit `k8s/ingress.yaml` and replace `crm.example.eu` with your domain:

```yaml
spec:
  tls:
  - hosts:
    - your-domain.com  # Replace this
    secretName: minicrm-tls
  rules:
  - host: your-domain.com  # Replace this
```

### Features Included

- **Automatic SSL/TLS**: Certificates are automatically provisioned and renewed via Let's Encrypt
- **Force HTTPS**: All HTTP traffic is automatically redirected to HTTPS
- **Security Headers**: X-Frame-Options, X-Content-Type-Options, X-XSS-Protection
- **Rate Limiting**: Protection against abuse (100 requests per client)
- **LoadBalancer**: Automatic external IP assignment (cloud provider dependent)

### Access Your Application

After deployment, the Ingress will automatically provision an SSL certificate. You can access your application at:

```
https://your-domain.com
```

Check certificate status:
```bash
kubectl get certificate -n minicrm
kubectl describe certificate minicrm-tls -n minicrm
```

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

See LICENSE file for license information.

## Support

For issues and questions:
- Check the documentation files
- Review troubleshooting section
- Check application logs

## Contributing

We welcome contributions! Please:
1. Test thoroughly
2. Follow existing code style
3. Update documentation
4. Include security considerations

## Changelog

See releases for version history and changes.

## About

MiniCRM is designed for small to medium businesses that need a lightweight, easy-to-deploy CRM system without the complexity of enterprise solutions.

Built with modern web technologies and best practices:
- MVC architecture
- RESTful API design
- Security-first approach
- Mobile-responsive
- Docker-native
- Kubernetes-ready

---

**Version:** 1.0.0
**Last Updated:** 2025-11-28
