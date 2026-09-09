#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

INSTALL_DIR="/opt/elegoo-monitor"

echo -e "${YELLOW}Uninstalling Elegoo Centauri Carbon Monitor...${NC}"
echo ""

if [ -d "$INSTALL_DIR" ]; then
    echo "Stopping container..."
    cd "$INSTALL_DIR" || exit
    sudo docker compose down 2>/dev/null
    echo -e "${GREEN}✓ Container stopped${NC}"
else
    echo -e "${YELLOW}Directory $INSTALL_DIR not found${NC}"
fi

echo "Removing Docker image..."
sudo docker rmi elegoo-monitor-printer-monitor:latest 2>/dev/null || true
echo -e "${GREEN}✓ Image removed${NC}"

echo "Removing files..."
sudo rm -rf "$INSTALL_DIR"
echo -e "${GREEN}✓ Files removed${NC}"

echo ""
echo -e "${GREEN}✅ Uninstallation complete!${NC}"
