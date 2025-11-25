# MiniCRM - Plain Docker Deployment

Deploy MiniCRM as a single Docker container with SQLite database.

## Prerequisites

- Docker 20.10+

## Quick Start

### Option 1: Using the Setup Script (Easiest)

```bash
chmod +x docker-run.sh
./docker-run.sh
```

The script will:
- Pull the latest MiniCRM image
- Create data directories
- Start the container
- Show you the access URL

### Option 2: Manual Docker Run

```bash
# Create data directory
mkdir -p ~/minicrm-data/{database,uploads,storage}

# Pull latest image
docker pull ghcr.io/jasmaine/minicrm:latest

# Run container
docker run -d \
  --name minicrm \
  -p 8080:80 \
  -e DB_TYPE=sqlite \
  -e BASE_URL=http://localhost:8080 \
  -v ~/minicrm-data/database:/var/www/html/database \
  -v ~/minicrm-data/uploads:/var/www/html/uploads \
  -v ~/minicrm-data/storage:/var/www/html/storage \
  --restart unless-stopped \
  ghcr.io/jasmaine/minicrm:latest
```

## Access

Open http://localhost:8080 in your browser.

## Configuration

### Change Port

Set the `HTTP_PORT` environment variable:

```bash
HTTP_PORT=9000 ./docker-run.sh
```

Or manually:
```bash
docker run -d \
  --name minicrm \
  -p 9000:80 \
  ...
```

### Add SMTP for Email Campaigns

```bash
docker run -d \
  --name minicrm \
  -p 8080:80 \
  -e DB_TYPE=sqlite \
  -e BASE_URL=http://localhost:8080 \
  -e SMTP_HOST=smtp.gmail.com \
  -e SMTP_PORT=587 \
  -e SMTP_USER=your-email@gmail.com \
  -e SMTP_PASSWORD=your-app-password \
  -e SMTP_FROM_EMAIL=your-email@gmail.com \
  -e SMTP_FROM_NAME=MiniCRM \
  -v ~/minicrm-data/database:/var/www/html/database \
  -v ~/minicrm-data/uploads:/var/www/html/uploads \
  -v ~/minicrm-data/storage:/var/www/html/storage \
  --restart unless-stopped \
  ghcr.io/jasmaine/minicrm:latest
```

## Management Commands

**View logs:**
```bash
docker logs -f minicrm
```

**Stop container:**
```bash
docker stop minicrm
```

**Start container:**
```bash
docker start minicrm
```

**Restart container:**
```bash
docker restart minicrm
```

**Update to latest version:**
```bash
docker stop minicrm
docker rm minicrm
docker pull ghcr.io/jasmaine/minicrm:latest
./docker-run.sh
```

**Remove container (keeps data):**
```bash
docker stop minicrm
docker rm minicrm
```

## Backup

### Backup All Data
```bash
tar -czf minicrm-backup-$(date +%Y%m%d).tar.gz ~/minicrm-data
```

### Restore Data
```bash
tar -xzf minicrm-backup-YYYYMMDD.tar.gz -C ~/
```

## Data Location

All data is stored in `~/minicrm-data/`:
- `database/` - SQLite database file
- `uploads/` - User uploaded files
- `storage/` - Application storage (sessions, logs)

## Limitations

This setup uses SQLite, which is suitable for:
- Development
- Testing
- Small deployments (< 10 users)
- Single-server setups

For production or larger deployments, use:
- [Docker Compose](../docker-compose/) with PostgreSQL
- [Kubernetes](../k8s/) deployment
- [Helm](../helm-chart/) chart

## Troubleshooting

### Port already in use
Stop the container and use a different port:
```bash
docker stop minicrm
docker rm minicrm
HTTP_PORT=9000 ./docker-run.sh
```

### Permission errors
```bash
docker exec minicrm chown -R www-data:www-data /var/www/html/database
docker exec minicrm chown -R www-data:www-data /var/www/html/uploads
docker exec minicrm chown -R www-data:www-data /var/www/html/storage
```

### Container won't start
Check logs:
```bash
docker logs minicrm
```

## Support

- Documentation: [Main README](../README.md)
- Issues: https://github.com/jasmaine/minicrm/issues
