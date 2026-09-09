```text
<div align="center">

# 🖨️ Elegoo Centauri Carbon Monitor

**Local 3D printer monitor with smart Telegram notifications**

[🇬🇧 English](#english) | [🇷🇺 Русский](#русский)

</div>

---

<a name="english"></a>
## 🇬🇧 English

### 🎯 Problem
Many Elegoo printers (especially older models) lack sound notifications, working push notifications (the Matrix app only supports CC2), and a reliable way to check print status remotely without spam.

### ✅ Solution
A Python script in a Docker container that:
- ✅ Connects to the printer via local WebSocket (SDCP protocol)
- ✅ Sends instant Telegram notifications for print completion, filament runout/jam, temperature errors, and more
- ✅ **Notifies about ALL pauses** with the exact reason (e.g., "Manual pause/M600", "Filament runout", "USB removed"), so you are always in control
- ✅ Works fully locally (no cloud required)
- ✅ Automatically reconnects on connection drops
- ✅ Supports HTTP/SOCKS5 proxies for regions with Telegram restrictions

### 🚀 Quick Installation (1 Command)

```bash
curl -sSL https://raw.githubusercontent.com/trubacevvladislav-boop/elegoo-centauri-carbon-monitor/main/install.sh | sudo bash
```
*(Or clone the repo and run `sudo ./install.sh`)*

The interactive installer will:
1. Check for Docker.
2. Ask for printer IP and Telegram bot token.
3. **Automatically detect your Chat ID** (it will ask you to send a message to the bot and show you a preview of the message to confirm).
4. Optionally configure proxies (both for Telegram notifications and for Docker build if needed).
5. Launch the monitoring container.

### ⚠️ Important: Static IP Required
You **must** reserve a static IP address for your printer in your router's DHCP settings. If the printer's IP changes, the monitoring will stop working.
*How to: Log into your router → Find "DHCP Reservation" → Assign a fixed IP (e.g., 192.168.0.234) to your printer's MAC address.*

### 🖨️ Supported Models
- ✅ **Tested:** Elegoo Centauri Carbon (1st Gen)
- ⚠️ **Potentially Supported (SDCP Protocol):** Elegoo Saturn 3/4 Ultra, Mars series *(Feedback welcome via [Issues](https://github.com/trubacevvladislav-boop/elegoo-centauri-carbon-monitor/issues)!)*
- ❌ **Not Supported:** Klipper/Moonraker based printers (Neptune 4/Pro, OrangeStorm Giga).

### 🛠️ Management
```bash
sudo docker logs -f elegoo-monitor       # View live logs
cd /opt/elegoo-monitor && sudo docker compose down    # Stop
sudo /opt/elegoo-monitor/uninstall.sh    # Complete removal
```

---

<a name="русский"></a>
## 🇷🇺 Русский

### 🎯 Проблема
Многие принтеры Elegoo (особенно старые модели) не имеют звуковых уведомлений, рабочих push-уведомлений (приложение Matrix только для CC2) и надежного способа узнать о статусе печати удаленно без спама.

### ✅ Решение
Python-скрипт в Docker-контейнере, который:
- ✅ Подключается к принтеру через локальный WebSocket (протокол SDCP)
- ✅ Отправляет мгновенные уведомления в Telegram о завершении печати, обрыве/замятии филамента, ошибках температуры и др.
- ✅ **Уведомляет о ЛЮБОЙ паузе** с точной причиной (например, "Ручная пауза/M600", "Обрыв филамента", "Извлечен USB"), чтобы вы всегда были в курсе
- ✅ Работает полностью локально, без облака
- ✅ Автоматически переподключается при разрывах связи
- ✅ Поддерживает HTTP/SOCKS5 прокси для регионов с блокировками Telegram

### 🚀 Быстрая установка (1 команда)

```bash
curl -sSL https://raw.githubusercontent.com/trubacevvladislav-boop/elegoo-centauri-carbon-monitor/main/install.sh | sudo bash
```
*(Или склонируйте репозиторий и запустите `sudo ./install.sh`)*

Интерактивный установщик:
1. Проверит наличие Docker.
2. Спросит IP принтера и токен Telegram бота.
3. **Автоматически определит ваш Chat ID** (попросит отправить сообщение боту и покажет его превью для подтверждения).
4. Опционально настроит прокси (как для отправки уведомлений, так и для сборки Docker, если интернет на сервере ограничен).
5. Запустит контейнер мониторинга.

### ⚠️ Важно: Требуется статический IP
Вы **должны** зарезервировать статический IP-адрес для вашего принтера в настройках DHCP роутера. Если IP принтера изменится, мониторинг перестанет работать.
*Как сделать: Войдите в роутер → Найдите "Резервирование DHCP" → Назначьте фиксированный IP (например, 192.168.0.234) MAC-адресу принтера.*

### 🖨️ Поддерживаемые модели
- ✅ **Протестировано:** Elegoo Centauri Carbon (1st Gen)
- ⚠️ **Потенциально поддерживается (протокол SDCP):** Elegoo Saturn 3/4 Ultra, Mars серии *(Будем рады вашему фидбеку в [Issues](https://github.com/trubacevvladislav-boop/elegoo-centauri-carbon-monitor/issues)!)*
- ❌ **Не поддерживается:** Принтеры на базе Klipper/Moonraker (Neptune 4/Pro, OrangeStorm Giga).

### 🛠️ Управление
```bash
sudo docker logs -f elegoo-monitor       # Просмотр логов
cd /opt/elegoo-monitor && sudo docker compose down    # Остановка
sudo /opt/elegoo-monitor/uninstall.sh    # Полное удаление
```

---

## 🙏 Credits / Благодарности
- [WalkerFrederick/sdcp-centauri-carbon](https://github.com/WalkerFrederick/sdcp-centauri-carbon) - SDCP protocol documentation
- [vvuk/cassini](https://github.com/vvuk/cassini) - Elegoo tools
- [bjan/pycentauri](https://github.com/bjan/pycentauri) - Python SDCP client
- 3D printing community for SDCP reverse engineering

*License: MIT*
