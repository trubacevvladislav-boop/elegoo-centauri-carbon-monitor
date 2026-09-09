#!/bin/bash

# Определяем директорию, где лежит сам скрипт (работает даже через sudo)
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Выбор языка
echo "Выберите язык / Select language:"
echo "  1) Русский"
echo "  2) English"
read -p "Выберите (1-2): " lang_choice

if [ "$lang_choice" = "1" ]; then
    LANGUAGE="ru"
    MSG_WELCOME="Установка Elegoo Centauri Carbon Monitor"
    MSG_CHECKING_DOCKER="Проверка наличия Docker..."
    MSG_DOCKER_NOT_FOUND="Docker не установлен!"
    MSG_INSTALL_DOCKER="Установите Docker:"
    MSG_DOCKER_FOUND="Docker найден"
    MSG_INSTALL_DIR="Директория установки"
    MSG_DIR_EXISTS="Директория уже существует"
    MSG_OVERWRITE="Перезаписать? (y/n)"
    MSG_SETUP="Настройка"
    MSG_PRINTER_IP="IP-адрес принтера"
    MSG_BOT_TOKEN="Получите токен у @BotFather в Telegram"
    MSG_ENTER_TOKEN="Токен Telegram бота"
    MSG_TOKEN_EMPTY="Токен не может быть пустым"
    MSG_USE_TG_PROXY="Использовать прокси для отправки уведомлений в Telegram? (y/n)"
    MSG_TG_PROXY_EXAMPLES="Примеры: http://127.0.0.1:8080 или socks5://127.0.0.1:1080"
    MSG_TG_PROXY_URL="URL прокси для Telegram"
    MSG_USE_PIP_PROXY="Нужен ли прокси для скачивания пакетов при сборке Docker (pip install)? (y/n)"
    MSG_PIP_PROXY_EXAMPLE="Пример: http://192.168.0.50:7890 (оставьте пустым, если интернет работает напрямую)"
    MSG_PIP_PROXY_URL="URL прокси для сборки Docker"
    MSG_CREATING_FILES="Создание файлов"
    MSG_ENV_CREATED=".env создан"
    MSG_DOCKERFILE_CREATED="Dockerfile создан с учетом ваших настроек сети"
    MSG_FILES_COPIED="Файлы скопированы"
    MSG_LAUNCHING="Запуск"
    MSG_CONTAINER_STARTED="Контейнер запущен!"
    MSG_ERROR_LAUNCH="Ошибка запуска"
    MSG_INSTALL_COMPLETE="Установка завершена!"
    MSG_MONITOR_ACTIVE="Мониторинг принтера активен!"
    MSG_USEFUL_COMMANDS="Полезные команды:"
    MSG_LOGS="Логи"
    MSG_STOP="Стоп"
    MSG_RESTART="Рестарт"
    MSG_UNINSTALL="Удаление"
else
    LANGUAGE="en"
    MSG_WELCOME="Installing Elegoo Centauri Carbon Monitor"
    MSG_CHECKING_DOCKER="Checking Docker installation..."
    MSG_DOCKER_NOT_FOUND="Docker is not installed!"
    MSG_INSTALL_DOCKER="Install Docker:"
    MSG_DOCKER_FOUND="Docker found"
    MSG_INSTALL_DIR="Installation directory"
    MSG_DIR_EXISTS="Directory already exists"
    MSG_OVERWRITE="Overwrite? (y/n)"
    MSG_SETUP="Setup"
    MSG_PRINTER_IP="Printer IP address"
    MSG_BOT_TOKEN="Get token from @BotFather in Telegram"
    MSG_ENTER_TOKEN="Telegram bot token"
    MSG_TOKEN_EMPTY="Token cannot be empty"
    MSG_USE_TG_PROXY="Use proxy for sending Telegram notifications? (y/n)"
    MSG_TG_PROXY_EXAMPLES="Examples: http://127.0.0.1:8080 or socks5://127.0.0.1:1080"
    MSG_TG_PROXY_URL="Proxy URL for Telegram"
    MSG_USE_PIP_PROXY="Do you need a proxy for downloading packages during Docker build (pip install)? (y/n)"
    MSG_PIP_PROXY_EXAMPLE="Example: http://192.168.0.50:7890 (leave empty if internet works directly)"
    MSG_PIP_PROXY_URL="Proxy URL for Docker build"
    MSG_CREATING_FILES="Creating files"
    MSG_ENV_CREATED=".env created"
    MSG_DOCKERFILE_CREATED="Dockerfile created according to your network settings"
    MSG_FILES_COPIED="Files copied"
    MSG_LAUNCHING="Launching"
    MSG_CONTAINER_STARTED="Container started!"
    MSG_ERROR_LAUNCH="Launch error"
    MSG_INSTALL_COMPLETE="Installation complete!"
    MSG_MONITOR_ACTIVE="Printer monitoring is active!"
    MSG_USEFUL_COMMANDS="Useful commands:"
    MSG_LOGS="Logs"
    MSG_STOP="Stop"
    MSG_RESTART="Restart"
    MSG_UNINSTALL="Uninstall"
fi

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
    print_info "$MSG_CHECKING_DOCKER"
    if ! command -v docker &> /dev/null; then
        print_error "$MSG_DOCKER_NOT_FOUND"
        echo -e "\n$MSG_INSTALL_DOCKER"
        echo "  curl -fsSL https://get.docker.com -o get-docker.sh"
        echo "  sudo sh get-docker.sh"
        exit 1
    fi
    
    if ! docker compose version &> /dev/null; then
        print_error "Docker Compose not installed!"
        exit 1
    fi
    
    print_success "$MSG_DOCKER_FOUND: $(docker --version)"
}

get_chat_id() {
    local token=$1
    local proxy=$2
    
    echo -e "\n${BLUE}═══════════════════════════════════════════════════════════${NC}" >&2
    echo -e "${BLUE}  🔍 Получение Chat ID / Getting Chat ID${NC}" >&2
    echo -e "${BLUE}═══════════════════════════════════════════════════════════${NC}\n" >&2
    echo -e "${BLUE}ℹ 1. Откройте Telegram и найдите вашего бота.${NC}" >&2
    echo -e "${BLUE}ℹ 2. Отправьте ему ЛЮБОЕ сообщение (например, 'test' или '/start').${NC}" >&2
    echo -e "${BLUE}ℹ 3. После отправки нажмите Enter здесь для проверки.${NC}" >&2
    read -p "Нажмите Enter... / Press Enter..." dummy >&2

    local url="https://api.telegram.org/bot${token}/getUpdates"
    local response
    
    if [ -n "$proxy" ]; then
        response=$(curl -s -x "$proxy" "$url" 2>/dev/null)
    else
        response=$(curl -s "$url" 2>/dev/null)
    fi
    
    if [ -z "$response" ]; then
        echo -e "${RED}✗ Не удалось получить ответ от Telegram API / Failed to get response from Telegram API${NC}" >&2
        return 1
    fi
    
    local parsed_data=$(echo "$response" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    if data.get('ok') and data.get('result'):
        last_update = data['result'][-1]
        msg = last_update.get('message') or last_update.get('edited_message')
        if msg:
            chat_id = msg['chat']['id']
            text = msg.get('text', 'No text')
            print(f'{chat_id}|{text}')
        else:
            print('')
    else:
        print('')
except:
    print('')
" 2>/dev/null)

    if [ -z "$parsed_data" ]; then
        echo -e "${RED}✗ Не удалось найти chat_id. Убедитесь, что вы отправили сообщение боту.${NC}" >&2
        return 1
    fi

    local found_chat_id="${parsed_data%%|*}"
    local msg_text="${parsed_data#*|}"

    echo -e "\n${GREEN}✓ Найдено сообщение в чате ID / Found message in chat ID: $found_chat_id${NC}" >&2
    echo -e "${GREEN}  Текст сообщения / Message text: '$msg_text'${NC}" >&2
    echo "" >&2
    read -p "Это ваш чат? (y/n) / Is this your chat? (y/n): " confirm >&2
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo "$found_chat_id"
        return 0
    else
        return 1
    fi
}

main() {
    clear
    print_header "🖨️  $MSG_WELCOME"
    
    check_docker
    
    INSTALL_DIR="/opt/elegoo-monitor"
    print_info "$MSG_INSTALL_DIR: $INSTALL_DIR"
    
    if [ -d "$INSTALL_DIR" ]; then
        print_warning "$MSG_DIR_EXISTS"
        read -p "$MSG_OVERWRITE " overwrite
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            exit 1
        fi
        sudo rm -rf "$INSTALL_DIR"
    fi
    
    sudo mkdir -p "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    
    print_header "📝 $MSG_SETUP"
    
    read -p "$MSG_PRINTER_IP [192.168.0.234]: " PRINTER_IP
    PRINTER_IP=${PRINTER_IP:-192.168.0.234}
    
    echo ""
    print_info "$MSG_BOT_TOKEN"
    while true; do
        read -p "$MSG_ENTER_TOKEN: " TG_BOT_TOKEN
        if [ -n "$TG_BOT_TOKEN" ]; then
            break
        fi
        print_error "$MSG_TOKEN_EMPTY"
    done
    
    echo ""
    read -p "$MSG_USE_TG_PROXY " use_tg_proxy
    TG_PROXY_URL=""
    if [[ "$use_tg_proxy" =~ ^[Yy]$ ]]; then
        print_info "$MSG_TG_PROXY_EXAMPLES"
        read -p "$MSG_TG_PROXY_URL: " TG_PROXY_URL
    fi

    echo ""
    read -p "$MSG_USE_PIP_PROXY " use_pip_proxy
    PIP_PROXY_URL=""
    if [[ "$use_pip_proxy" =~ ^[Yy]$ ]]; then
        print_info "$MSG_PIP_PROXY_EXAMPLE"
        read -p "$MSG_PIP_PROXY_URL: " PIP_PROXY_URL
    fi
    
    while true; do
        # Передаем прокси Telegram в функцию, если он есть
        chat_id=$(get_chat_id "$TG_BOT_TOKEN" "$TG_PROXY_URL")
        if [ -n "$chat_id" ]; then
            TG_CHAT_ID="$chat_id"
            break
        fi
        
        read -p "Ввести Chat ID вручную? / Enter Chat ID manually? (y/n): " manual
        if [[ "$manual" =~ ^[Yy]$ ]]; then
            read -p "Chat ID: " TG_CHAT_ID
            break
        fi
    done
    
    print_header "🔧 $MSG_CREATING_FILES"
    
    sudo tee .env > /dev/null <<ENVEOF
PRINTER_IP=$PRINTER_IP
TG_BOT_TOKEN=$TG_BOT_TOKEN
TG_CHAT_ID=$TG_CHAT_ID
PROXY_URL=$TG_PROXY_URL
LANGUAGE=$LANGUAGE
ENVEOF
    print_success "$MSG_ENV_CREATED"
    
    # Генерируем Dockerfile динамически в зависимости от ответа про прокси для pip
    if [ -n "$PIP_PROXY_URL" ]; then
        sudo tee Dockerfile > /dev/null <<DOCKEREOF
FROM python:3.11-slim
WORKDIR /app

# Прокси для скачивания пакетов во время сборки
ENV http_proxy=$PIP_PROXY_URL
ENV https_proxy=$PIP_PROXY_URL
ENV HTTP_PROXY=$PIP_PROXY_URL
ENV HTTPS_PROXY=$PIP_PROXY_URL

RUN pip install --no-cache-dir websockets httpx

# Очищаем переменные прокси после установки
ENV http_proxy=""
ENV https_proxy=""
ENV HTTP_PROXY=""
ENV HTTPS_PROXY=""

COPY main.py .
CMD ["python", "main.py"]
DOCKEREOF
    else
        sudo tee Dockerfile > /dev/null <<DOCKEREOF
FROM python:3.11-slim
WORKDIR /app

RUN pip install --no-cache-dir websockets httpx

COPY main.py .
CMD ["python", "main.py"]
DOCKEREOF
    fi
    print_success "$MSG_DOCKERFILE_CREATED"
    
    sudo cp "$SCRIPT_DIR/main.py" .
    sudo cp "$SCRIPT_DIR/docker-compose.yml" .
    sudo cp "$SCRIPT_DIR/uninstall.sh" .
    print_success "$MSG_FILES_COPIED"
    
    print_header "🚀 $MSG_LAUNCHING"
    if sudo docker compose up -d --build; then
        print_success "$MSG_CONTAINER_STARTED"
    else
        print_error "$MSG_ERROR_LAUNCH"
        exit 1
    fi
    
    print_header "✅ $MSG_INSTALL_COMPLETE"
    echo -e "${GREEN}$MSG_MONITOR_ACTIVE${NC}"
    echo ""
    echo "$MSG_USEFUL_COMMANDS"
    echo "  $MSG_LOGS:    sudo docker logs -f elegoo-monitor"
    echo "  $MSG_STOP:    cd $INSTALL_DIR && sudo docker compose down"
    echo "  $MSG_RESTART: cd $INSTALL_DIR && sudo docker compose restart"
    echo "  $MSG_UNINSTALL: sudo $INSTALL_DIR/uninstall.sh"
}

main
