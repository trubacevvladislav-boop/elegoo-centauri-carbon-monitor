#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_header() {
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}"
    echo -e "${BLUE}  $1${NC}"
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n"
}

print_success() { echo -e "${GREEN}✓ $1${NC}"; }
print_error() { echo -e "${RED}✗ $1${NC}"; }
print_warning() { echo -e "${YELLOW}⚠ $1${NC}"; }
print_info() { echo -e "${BLUE}ℹ $1${NC}"; }

check_docker() {
    print_info "Проверка наличия Docker..."
    if ! command -v docker &> /dev/null; then
        print_error "Docker не установлен!"
        echo -e "\nУстановите Docker:"
        echo "  curl -fsSL https://get.docker.com -o get-docker.sh"
        echo "  sudo sh get-docker.sh"
        exit 1
    fi
    
    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose не установлен!"
        exit 1
    fi
    
    print_success "Docker найден: $(docker --version)"
}

get_chat_id() {
    local token=$1
    local proxy=$2
    
    print_header "🔍 Получение Chat ID"
    print_info "Отправьте ЛЮБОЕ сообщение вашему боту в Telegram"
    print_info "Например: /start или просто 'привет'"
    echo ""
    read -p "Нажмите Enter после отправки сообщения..."
    
    local url="https://api.telegram.org/bot${token}/getUpdates"
    local response
    
    if [ -n "$proxy" ]; then
        response=$(curl -s -x "$proxy" "$url" 2>/dev/null)
    else
        response=$(curl -s "$url" 2>/dev/null)
    fi
    
    if [ -z "$response" ]; then
        print_error "Не удалось получить ответ от Telegram API"
        return 1
    fi
    
    local chat_id=$(echo "$response" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if data.get('ok') and data.get('result'):
        last_update = data['result'][-1]
        if 'message' in last_update:
            print(last_update['message']['chat']['id'])
        elif 'edited_message' in last_update:
            print(last_update['edited_message']['chat']['id'])
        else:
            print('')
    else:
        print('')
except:
    print('')
" 2>/dev/null)
    
    if [ -z "$chat_id" ]; then
        print_error "Не удалось найти chat_id"
        return 1
    fi
    
    echo ""
    print_success "Найден Chat ID: $chat_id"
    echo ""
    read -p "Это ваш Chat ID? (y/n): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo "$chat_id"
        return 0
    else
        return 1
    fi
}

main() {
    clear
    print_header "🖨️  Установка Elegoo Centauri Carbon Monitor"
    
    check_docker
    
    INSTALL_DIR="/opt/elegoo-monitor"
    print_info "Директория установки: $INSTALL_DIR"
    
    if [ -d "$INSTALL_DIR" ]; then
        print_warning "Директория уже существует"
        read -p "Перезаписать? (y/n): " overwrite
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            exit 1
        fi
        sudo rm -rf "$INSTALL_DIR"
    fi
    
    sudo mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    print_header "📝 Настройка"
    
    read -p "IP-адрес принтера [192.168.0.234]: " PRINTER_IP
    PRINTER_IP=${PRINTER_IP:-192.168.0.234}
    
    echo ""
    print_info "Получите токен у @BotFather в Telegram"
    while true; do
        read -p "Токен Telegram бота: " TG_BOT_TOKEN
        if [ -n "$TG_BOT_TOKEN" ]; then
            break
        fi
        print_error "Токен не может быть пустым"
    done
    
    echo ""
    read -p "Использовать прокси для Telegram? (y/n): " use_proxy
    PROXY_URL=""
    if [[ "$use_proxy" =~ ^[Yy]$ ]]; then
        print_info "Примеры: http://127.0.0.1:8080 или socks5://127.0.0.1:1080"
        read -p "URL прокси: " PROXY_URL
    fi
    
    while true; do
        chat_id=$(get_chat_id "$TG_BOT_TOKEN" "$PROXY_URL")
        if [ -n "$chat_id" ]; then
            TG_CHAT_ID="$chat_id"
            break
        fi
        
        read -p "Ввести Chat ID вручную? (y/n): " manual
        if [[ "$manual" =~ ^[Yy]$ ]]; then
            read -p "Chat ID: " TG_CHAT_ID
            break
        fi
    done
    
    print_header "🔧 Создание файлов"
    
    sudo tee .env > /dev/null <<ENVEOF
PRINTER_IP=$PRINTER_IP
TG_BOT_TOKEN=$TG_BOT_TOKEN
TG_CHAT_ID=$TG_CHAT_ID
PROXY_URL=$PROXY_URL
ENVEOF
    print_success ".env создан"
    
    sudo cp /home/$USER/elegoo-centauri-carbon-monitor/main.py .
    sudo cp /home/$USER/elegoo-centauri-carbon-monitor/Dockerfile .
    sudo cp /home/$USER/elegoo-centauri-carbon-monitor/docker-compose.yml .
    print_success "Файлы скопированы"
    
    print_header "🚀 Запуск"
    if sudo docker compose up -d --build; then
        print_success "Контейнер запущен!"
    else
        print_error "Ошибка запуска"
        exit 1
    fi
    
    print_header "✅ Установка завершена!"
    echo -e "${GREEN}Мониторинг принтера активен!${NC}"
    echo ""
    echo "Полезные команды:"
    echo "  Логи:    sudo docker logs -f elegoo-monitor"
    echo "  Стоп:    cd $INSTALL_DIR && sudo docker compose down"
    echo "  Рестарт: cd $INSTALL_DIR && sudo docker compose restart"
}

main
