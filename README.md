# 🖨️ Elegoo Centauri Carbon Monitor

Локальный монитор для 3D-принтеров Elegoo с умными уведомлениями в Telegram о завершении печати и ошибках.

## 🎯 Проблема
Многие принтеры Elegoo (особенно старые модели) не имеют звуковых уведомлений при завершении печати, рабочих push-уведомлений (приложение Matrix только для CC2) и надежного способа узнать о статусе печати удаленно без спама.

## ✅ Решение
Python-скрипт в Docker-контейнере, который:
- ✅ Подключается к принтеру через локальный WebSocket (протокол SDCP)
- ✅ Отправляет мгновенные уведомления в Telegram при завершении печати, обрыве или замятии филамента, ошибках температуры
- ✅ **Игнорирует ручные паузы** (не спамит, когда вы сами нажали "Пауза" или используете M600 для смены цвета)
- ✅ Работает полностью локально, без облака
- ✅ Автоматически переподключается при разрывах связи
- ✅ Поддерживает прокси (HTTP/SOCKS5) для регионов с блокировками Telegram

## 🖨️ Поддерживаемые модели

### ✅ Протестировано
- **Elegoo Centauri Carbon (1st Gen)**

### ⚠️ Потенциально поддерживается (протокол SDCP)
Эти модели используют тот же протокол, но **еще не тестировались**. Будем очень рады вашему фидбеку!
- Elegoo Saturn 3 Ultra
- Elegoo Saturn 4 Ultra
- Elegoo Mars серии (некоторые модели)

*Если у вас есть один из этих принтеров, пожалуйста, протестируйте скрипт и сообщите о результате через [Issues](https://github.com/trubacevvladislav-boop/elegoo-centauri-carbon-monitor/issues)!*

### ❌ Не поддерживается
Принтеры на базе Klipper/Moonraker (Neptune 4/Pro, OrangeStorm Giga). Для них используйте OctoPrint или нативные интеграции Klipper.

## 🚀 Быстрая установка

~~~~bash
git clone https://github.com/trubacevvladislav-boop/elegoo-centauri-carbon-monitor.git
cd elegoo-centauri-carbon-monitor
chmod +x install.sh
sudo ./install.sh
~~~~
Скрипт автоматически проверит Docker, спросит IP принтера, токен бота, **сам определит ваш Chat ID** (попросив отправить сообщение боту) и запустит мониторинг.

## 🧠 Умная логика уведомлений
| Ситуация | Действие скрипта |
|----------|------------------|
| Ручная пауза / M600 (смена цвета) | ❌ Уведомление НЕ отправляется |
| Обрыв или замятие филамента | ✅ Мгновенное уведомление с причиной |
| Ошибка температуры / G-кода | ✅ Мгновенное уведомление с причиной |
| Завершение печати | ✅ Уведомление об успехе |

## 🛠️ Управление

~~~~bash
sudo docker logs -f elegoo-monitor       # Просмотр логов
cd /opt/elegoo-monitor && sudo docker compose down    # Остановка
sudo /opt/elegoo-monitor/uninstall.sh    # Полное удаление
~~~~

## 🙏 Благодарности
- [WalkerFrederick/sdcp-centauri-carbon](https://github.com/WalkerFrederick/sdcp-centauri-carbon)
- [vvuk/cassini](https://github.com/vvuk/cassini)
- [bjan/pycentauri](https://github.com/bjan/pycentauri)
- Сообществу 3D-печати за reverse engineering протокола SDCP.

*Лицензия: MIT*
