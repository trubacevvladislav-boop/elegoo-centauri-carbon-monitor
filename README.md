<div align="center">

# 🖨️ Elegoo Centauri Carbon Monitor

**Local 3D printer monitor with smart Telegram notifications**

[🇬🇧 English](#english) | [🇷🇺 Русский](#русский)

</div>

---

<a name="english"></a>
## 🇬🇧 English

### 🎯 Problem
Many Elegoo printers (especially older models) lack:
- Sound notifications when printing finishes
- Working push notifications (Matrix app only supports CC2)
- A reliable way to check print status remotely without spam

### ✅ Solution
A Python script in a Docker container that:
- ✅ Connects to the printer via local WebSocket (SDCP protocol)
- ✅ Sends instant Telegram notifications for:
  - Print completion
  - Filament runout or jam
  - Temperature errors
  - Other critical errors
- ✅ **Ignores manual pauses** (no spam when you press "Pause" or use M600 for color changes)
- ✅ Works fully locally (no cloud required)
- ✅ Automatically reconnects on connection drops
- ✅ Supports HTTP/SOCKS5 proxies for regions with Telegram restrictions

### 🖨️ Supported Models

#### ✅ Tested
- **Elegoo Centauri Carbon (1st Gen)**

#### ⚠️ Potentially Supported (SDCP Protocol)
These models use the same protocol but **haven't been tested yet**. We'd love your feedback!
- Elegoo Saturn 3 Ultra
- Elegoo Saturn 4 Ultra
- Elegoo Mars series (some models)

*If you have one of these printers, please test the script and report results via [Issues](https://github.com/trubacevvladislav-boop/elegoo-centauri-carbon-monitor/issues)!*

#### ❌ Not Supported
Printers based on Klipper/Moonraker (Neptune 4/Pro, OrangeStorm Giga). Use OctoPrint or native Klipper integrations for these.

### 🚀 Quick Installation

~~~~bash
git clone https://github.com/trubacevvladislav-boop/elegoo-centauri-carbon-monitor.git
cd elegoo-centauri-carbon-monitor
chmod +x install.sh
sudo ./install.sh
~~~~

The installer will:
- Check for Docker
- Ask for printer IP
- Request Telegram bot token
- **Automatically detect your Chat ID** (by asking you to send a message to the bot)
- Optionally configure proxy (if Telegram is blocked)
- Launch monitoring

### ⚠️ Important Notes

**⚡ Static IP Required:** You must reserve a static IP address for your printer in your router's DHCP settings. If the printer's IP changes, the monitoring will stop working.

**How to set static IP:**
1. Log into your router's admin panel (usually 192.168.0.1 or 192.168.1.1)
2. Find "DHCP Reservation" or "Static Lease" section
3. Add your printer's MAC address and assign a fixed IP (e.g., 192.168.0.234)
4. Save and restart the printer

### 🧠 Smart Notification Logic

| Situation | Script Action |
|-----------|---------------|
| Manual pause / M600 (color change) | ❌ Notification NOT sent |
| Filament runout or jam | ✅ Instant notification with reason |
| Temperature / G-code error | ✅ Instant notification with reason |
| Print completion | ✅ Success notification |

### 🛠️ Management

~~~~bash
sudo docker logs -f elegoo-monitor       # View logs
cd /opt/elegoo-monitor && sudo docker compose down    # Stop
sudo /opt/elegoo-monitor/uninstall.sh    # Complete removal
~~~~

### 🔍 How to Get Chat ID?

#### Automatically (via installer)
The installer will ask you to send a message to the bot and will detect the Chat ID automatically.

#### Manually
1. Send any message to your bot
2. Open in browser: `https://api.telegram.org/bot<YOUR_TOKEN>/getUpdates`
3. Find the field `"chat":{"id":123456789}` in the JSON
4. This is your Chat ID

### 🙏 Credits
- [WalkerFrederick/sdcp-centauri-carbon](https://github.com/WalkerFrederick/sdcp-centauri-carbon) - SDCP protocol documentation
- [vvuk/cassini](https://github.com/vvuk/cassini) - Elegoo tools
- [bjan/pycentauri](https://github.com/bjan/pycentauri) - Python SDCP client
- 3D printing community for SDCP reverse engineering

*License: MIT*

---

<a name="русский"></a>
## 🇷🇺 Русский

### 🎯 Проблема
Многие принтеры Elegoo (особенно старые модели) не имеют:
- Звуковых уведомлений при завершении печати
- Рабочих push-уведомлений (приложение Matrix только для CC2)
- Надежного способа узнать о статусе печати удаленно без спама

### ✅ Решение
Python-скрипт в Docker-контейнере, который:
- ✅ Подключается к принтеру через локальный WebSocket (протокол SDCP)
- ✅ Отправляет мгновенные уведомления в Telegram при:
  - Завершении печати
  - Обрыве или замятии филамента
  - Ошибках температуры
  - Других критических ошибках
- ✅ **Игнорирует ручные паузы** (не спамит, когда вы сами нажали "Пауза" или используете M600 для смены цвета)
- ✅ Работает полностью локально, без облака
- ✅ Автоматически переподключается при разрывах связи
- ✅ Поддерживает прокси (HTTP/SOCKS5) для регионов с блокировками Telegram

### 🖨️ Поддерживаемые модели

#### ✅ Протестировано
- **Elegoo Centauri Carbon (1st Gen)**

#### ⚠️ Потенциально поддерживается (протокол SDCP)
Эти модели используют тот же протокол, но **еще не тестировались**. Будем очень рады вашему фидбеку!
- Elegoo Saturn 3 Ultra
- Elegoo Saturn 4 Ultra
- Elegoo Mars серии (некоторые модели)

*Если у вас есть один из этих принтеров, пожалуйста, протестируйте скрипт и сообщите о результате через [Issues](https://github.com/trubacevvladislav-boop/elegoo-centauri-carbon-monitor/issues)!*

#### ❌ Не поддерживается
Принтеры на базе Klipper/Moonraker (Neptune 4/Pro, OrangeStorm Giga). Для них используйте OctoPrint или нативные интеграции Klipper.

### 🚀 Быстрая установка

~~~~bash
git clone https://github.com/trubacevvladislav-boop/elegoo-centauri-carbon-monitor.git
cd elegoo-centauri-carbon-monitor
chmod +x install.sh
sudo ./install.sh
~~~~

Скрипт автоматически:
- Проверит наличие Docker
- Спросит IP принтера
- Запросит токен Telegram бота
- **Автоматически определит ваш Chat ID** (попросив отправить сообщение боту)
- Опционально настроит прокси (если Telegram заблокирован)
- Запустит мониторинг

### ⚠️ Важные замечания

**⚡ Требуется статический IP:** Вы должны зарезервировать статический IP-адрес для вашего принтера в настройках DHCP роутера. Если IP принтера изменится, мониторинг перестанет работать.

**Как настроить статический IP:**
1. Войдите в админ-панель вашего роутера (обычно 192.168.0.1 или 192.168.1.1)
2. Найдите раздел "Резервирование DHCP" или "Статические адреса"
3. Добавьте MAC-адрес вашего принтера и назначьте фиксированный IP (например, 192.168.0.234)
4. Сохраните и перезагрузите принтер

### 🧠 Умная логика уведомлений

| Ситуация | Действие скрипта |
|----------|------------------|
| Ручная пауза / M600 (смена цвета) | ❌ Уведомление НЕ отправляется |
| Обрыв или замятие филамента | ✅ Мгновенное уведомление с причиной |
| Ошибка температуры / G-кода | ✅ Мгновенное уведомление с причиной |
| Завершение печати | ✅ Уведомление об успехе |

### 🛠️ Управление

~~~~bash
sudo docker logs -f elegoo-monitor       # Просмотр логов
cd /opt/elegoo-monitor && sudo docker compose down    # Остановка
sudo /opt/elegoo-monitor/uninstall.sh    # Полное удаление
~~~~

### 🔍 Как получить Chat ID?

#### Автоматически (через установщик)
Установщик сам предложит отправить сообщение боту и определит Chat ID.

#### Вручную
1. Отправьте любое сообщение вашему боту
2. Откройте в браузере: `https://api.telegram.org/bot<ВАШ_ТОКЕН>/getUpdates`
3. Найдите в JSON поле `"chat":{"id":123456789}`
4. Это и есть ваш Chat ID

### 🙏 Благодарности
- [WalkerFrederick/sdcp-centauri-carbon](https://github.com/WalkerFrederick/sdcp-centauri-carbon) - документация протокола SDCP
- [vvuk/cassini](https://github.com/vvuk/cassini) - инструмент для работы с Elegoo
- [bjan/pycentauri](https://github.com/bjan/pycentauri) - Python клиент для SDCP
- Сообществу 3D-печати за reverse engineering протокола SDCP

*Лицензия: MIT*
