#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

INSTALL_DIR="/opt/elegoo-monitor"

echo -e "${YELLOW}Удаление Elegoo Centauri Carbon Monitor...${NC}"
echo ""

if [ -d "$INSTALL_DIR" ]; then
    echo "Остановка контейнера..."
    cd "$INSTALL_DIR"
    sudo docker compose down 2>/dev/null
    echo -e "${GREEN}✓ Контейнер остановлен${NC}"
fi

echo "Удаление Docker образа..."
sudo docker rmi elegoo-monitor-printer-monitor:latest 2>/dev/null
echo -e "${GREEN}✓ Образ удален${NC}"

echo "Удаление файлов..."
sudo rm -rf "$INSTALL_DIR"
echo -e "${GREEN}✓ Файлы удалены${NC}"

echo ""
echo -e "${GREEN}✅ Удаление завершено!${NC}"
