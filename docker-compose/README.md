# MiniCRM - Docker Compose Deployment

Deploy MiniCRM using Docker Compose with PostgreSQL database.

## Prerequisites

- Docker 20.10+
- Docker Compose 2.0+

## Quick Start

1. **Copy environment file:**
   ```bash
   cp .env.example .env
   ```

2. **Edit configuration:**
   ```bash
   nano .env
   ```

   Update at minimum:
   - `DB_PASSWORD` - Set a secure database password
   - `BASE_URL` - Your application URL
   - SMTP settings (if you want to send emails)

3. **Start the application:**
   ```bash
   docker-compose up -d
   ```

4. **Access MiniCRM:**
   - Open http://localhost:8080 (or your configured port)
   - First user to register becomes the admin

## Configuration

### Database

The PostgreSQL database is configured with:
- Default database: `minicrm`
- Default user: `minicrm`
- Persistent storage via Docker volume

### Volumes

Three volumes are created:
- `postgres_data` - Database files
- `uploads` - User uploaded files
- `storage` - Application storage (sessions, logs)

### Environment Variables

See `.env.example` for all available configuration options.

## Management Commands

**View logs:**
```bash
docker-compose logs -f
```

**Stop application:**
```bash
docker-compose stop
```

**Restart application:**
```bash
docker-compose restart
```

**Update to latest version:**
```bash
docker-compose pull
docker-compose up -d
```

**Remove everything (including data):**
```bash
docker-compose down -v
```

## Backup

### Database Backup
```bash
docker exec minicrm_postgres pg_dump -U minicrm minicrm > backup.sql
```

### Restore Database
```bash
cat backup.sql | docker exec -i minicrm_postgres psql -U minicrm -d minicrm
```

### Backup Uploads
```bash
docker cp minicrm_web:/var/www/html/uploads ./uploads-backup
```

## Troubleshooting

### Cannot connect to database
- Check that postgres container is running: `docker-compose ps`
- Check logs: `docker-compose logs postgres`
- Verify credentials in `.env` file

### Port already in use
- Change `HTTP_PORT` in `.env` file
- Restart: `docker-compose up -d`

### Permission denied errors
```bash
docker-compose exec web chown -R www-data:www-data /var/www/html/uploads
docker-compose exec web chown -R www-data:www-data /var/www/html/storage
```

## Production Deployment

For production use:

1. **Use strong passwords:**
   - Generate secure `DB_PASSWORD`
   - Use environment-specific SMTP credentials

2. **Enable HTTPS:**
   - Add a reverse proxy (nginx/traefik)
   - Configure SSL/TLS certificates

3. **Regular backups:**
   - Set up automated database backups
   - Back up uploads volume regularly

4. **Monitor resources:**
   - Check disk space
   - Monitor logs for errors
   - Set up health checks

## Support

- Documentation: [Main README](../README.md)
- Issues: https://github.com/jasmaine/minicrm/issues
