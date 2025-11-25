#!/bin/bash

# MiniCRM Plain Docker Deployment Script
# This script sets up MiniCRM with a single Docker container using SQLite

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}=====================================${NC}"
echo -e "${BLUE}   MiniCRM Plain Docker Setup${NC}"
echo -e "${BLUE}=====================================${NC}"
echo ""

# Configuration
CONTAINER_NAME="minicrm"
IMAGE_NAME="ghcr.io/jasmaine/minicrm:latest"
HTTP_PORT="${HTTP_PORT:-8080}"
BASE_URL="${BASE_URL:-http://localhost:8080}"

# Create volumes directory
VOLUME_DIR="$HOME/minicrm-data"
mkdir -p "$VOLUME_DIR"/{database,uploads,storage}

echo -e "${BLUE}[INFO]${NC} Pulling latest MiniCRM image..."
docker pull $IMAGE_NAME

echo -e "${BLUE}[INFO]${NC} Stopping existing container (if any)..."
docker stop $CONTAINER_NAME 2>/dev/null || true
docker rm $CONTAINER_NAME 2>/dev/null || true

echo -e "${BLUE}[INFO]${NC} Starting MiniCRM container..."
docker run -d \
  --name $CONTAINER_NAME \
  -p $HTTP_PORT:80 \
  -e DB_TYPE=sqlite \
  -e BASE_URL=$BASE_URL \
  -e ENVIRONMENT=production \
  -v "$VOLUME_DIR/database":/var/www/html/database \
  -v "$VOLUME_DIR/uploads":/var/www/html/uploads \
  -v "$VOLUME_DIR/storage":/var/www/html/storage \
  --restart unless-stopped \
  $IMAGE_NAME

echo ""
echo -e "${GREEN}=====================================${NC}"
echo -e "${GREEN}   MiniCRM Started Successfully!${NC}"
echo -e "${GREEN}=====================================${NC}"
echo ""
echo -e "Access MiniCRM at: ${BLUE}$BASE_URL${NC}"
echo -e "Container name: ${BLUE}$CONTAINER_NAME${NC}"
echo -e "Data directory: ${BLUE}$VOLUME_DIR${NC}"
echo ""
echo -e "${YELLOW}Note:${NC} This setup uses SQLite database."
echo -e "${YELLOW}For production use, consider PostgreSQL with Docker Compose.${NC}"
echo ""
echo -e "View logs: ${BLUE}docker logs -f $CONTAINER_NAME${NC}"
echo -e "Stop: ${BLUE}docker stop $CONTAINER_NAME${NC}"
echo -e "Start: ${BLUE}docker start $CONTAINER_NAME${NC}"
echo ""
