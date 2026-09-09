import asyncio
import json
import logging
import os
import httpx
import websockets

PRINTER_IP = os.getenv("PRINTER_IP", "192.168.0.234")
TG_TOKEN = os.getenv("TG_BOT_TOKEN")
TG_CHAT_ID = os.getenv("TG_CHAT_ID")
PROXY_URL = os.getenv("PROXY_URL", "")
LANGUAGE = os.getenv("LANGUAGE", "ru")

# Мультиязычные сообщения
MESSAGES = {
    "ru": {
        "connecting": "🔄 Подключение к принтеру {ws_url}...",
        "connected": "✅ Успешно подключено к WebSocket принтера",
        "connection_closed": "⚠️ Соединение закрыто: {error}. Переподключение через 5 сек...",
        "critical_error": "❌ Критическая ошибка: {error}. Переподключение через 5 сек...",
        "manual_pause": "ℹ️ Обнаружена ручная пауза. Уведомление не отправляется.",
        "error_pause": "⚠️ Обнаружена пауза из-за ошибки (код: {code})!",
        "print_finished": "🎉 Печать завершена!",
        "telegram_sent": "✅ Уведомление успешно отправлено в Telegram",
        "telegram_error": "❌ Ошибка отправки в Telegram: {error}",
        "config_error": "Не заданы TG_BOT_TOKEN или TG_CHAT_ID!",
        
        # Сообщения для Telegram
        "pause_title": "⚠️ <b>Печать приостановлена из-за ошибки!</b>",
        "pause_file": "🖨️ Файл: <code>{file}</code>",
        "pause_reason": "🔍 Причина: <b>{reason}</b>",
        "pause_check": "🛠️ Проверьте принтер и устраните проблему.",
        
        "finish_title": "✅ <b>Печать успешно завершена!</b>",
        "finish_file": "🖨️ Файл: <code>{file}</code>",
        "finish_congrats": "🎉 Можно забирать деталь.",
        
        # Причины ошибок
        "reason_0": "Ручная пауза (пользователь)",
        "reason_1": "Ошибка температуры (перегрев/недогрев)",
        "reason_3": "Обрыв филамента (Filament Runout)",
        "reason_6": "Замятие филамента (Filament Jam)",
        "reason_7": "Ошибка автовыравнивания стола",
        "reason_12": "Извлечен USB-накопитель во время печати",
        "reason_13": "Ошибка парковки/концевика оси X",
        "reason_14": "Ошибка парковки/концевика оси Z",
        "reason_24": "Ошибка в G-коде файла",
        "reason_33": "Отключен датчик температуры сопла",
        "reason_34": "Отключен датчик температуры стола",
        "reason_unknown": "Неизвестная ошибка (код {code})"
    },
    "en": {
        "connecting": "🔄 Connecting to printer {ws_url}...",
        "connected": "✅ Successfully connected to printer WebSocket",
        "connection_closed": "⚠️ Connection closed: {error}. Reconnecting in 5 sec...",
        "critical_error": "❌ Critical error: {error}. Reconnecting in 5 sec...",
        "manual_pause": "ℹ️ Manual pause detected. Notification not sent.",
        "error_pause": "⚠️ Pause due to error detected (code: {code})!",
        "print_finished": "🎉 Print finished!",
        "telegram_sent": "✅ Notification successfully sent to Telegram",
        "telegram_error": "❌ Telegram send error: {error}",
        "config_error": "TG_BOT_TOKEN or TG_CHAT_ID not set!",
        
        # Telegram messages
        "pause_title": "⚠️ <b>Print paused due to error!</b>",
        "pause_file": "🖨️ File: <code>{file}</code>",
        "pause_reason": "🔍 Reason: <b>{reason}</b>",
        "pause_check": "🛠️ Check the printer and fix the issue.",
        
        "finish_title": "✅ <b>Print successfully completed!</b>",
        "finish_file": "🖨️ File: <code>{file}</code>",
        "finish_congrats": "🎉 Ready to collect the part.",
        
        # Error reasons
        "reason_0": "Manual pause (user)",
        "reason_1": "Temperature error (overheating/underheating)",
        "reason_3": "Filament runout",
        "reason_6": "Filament jam",
        "reason_7": "Auto bed leveling failed",
        "reason_12": "USB drive removed during printing",
        "reason_13": "X-axis parking/endstop error",
        "reason_14": "Z-axis parking/endstop error",
        "reason_24": "G-code file error",
        "reason_33": "Nozzle temperature sensor offline",
        "reason_34": "Bed temperature sensor offline",
        "reason_unknown": "Unknown error (code {code})"
    }
}

# Выбираем язык (по умолчанию русский)
msgs = MESSAGES.get(LANGUAGE, MESSAGES["ru"])

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s"
)

def get_error_reason_text(code: int) -> str:
    """Получение текста причины ошибки на выбранном языке"""
    key = f"reason_{code}"
    return msgs.get(key, msgs["reason_unknown"].format(code=code))

async def send_telegram_message(text: str):
    url = f"https://api.telegram.org/bot{TG_TOKEN}/sendMessage"
    payload = {"chat_id": TG_CHAT_ID, "text": text, "parse_mode": "HTML"}

    try:
        if PROXY_URL:
            async with httpx.AsyncClient(proxy=PROXY_URL, timeout=10.0) as client:
                response = await client.post(url, json=payload)
                response.raise_for_status()
        else:
            async with httpx.AsyncClient(timeout=10.0) as client:
                response = await client.post(url, json=payload)
                response.raise_for_status()
        logging.info(msgs["telegram_sent"])
    except Exception as e:
        logging.error(msgs["telegram_error"].format(error=e))

async def monitor_printer():
    ws_url = f"ws://{PRINTER_IP}:3030/websocket"
    is_printing = False
    current_file = "Неизвестно" if LANGUAGE == "ru" else "Unknown"
    last_status = None

    while True:
        try:
            logging.info(msgs["connecting"].format(ws_url=ws_url))
            async with websockets.connect(ws_url, ping_interval=20, ping_timeout=20) as ws:
                logging.info(msgs["connected"])

                async for message in ws:
                    try:
                        data = json.loads(message)
                        if "Topic" in data and "sdcp/status" in data["Topic"]:
                            print_info = data.get("Status", {}).get("PrintInfo", {})
                            
                            current_status = print_info.get("Status")
                            error_reason = print_info.get("ErrorStatusReason", print_info.get("ErrorNumber", 0))
                            
                            if print_info.get("Filename"):
                                current_file = print_info.get("Filename")

                            # 13 = Активная печать / Active printing
                            if current_status == 13:
                                is_printing = True

                            # 5 = Pausing, 6 = Paused
                            if is_printing and current_status in (5, 6) and last_status == 13:
                                if error_reason == 0:
                                    logging.info(msgs["manual_pause"])
                                else:
                                    logging.warning(msgs["error_pause"].format(code=error_reason))
                                    reason_text = get_error_reason_text(error_reason)
                                    msg = (
                                        f"{msgs['pause_title']}\n"
                                        f"{msgs['pause_file'].format(file=current_file)}\n"
                                        f"{msgs['pause_reason'].format(reason=reason_text)}\n"
                                        f"{msgs['pause_check']}"
                                    )
                                    await send_telegram_message(msg)

                            # 0 или 9 = Завершение печати / Print completed
                            if is_printing and current_status in (0, 9) and last_status in (13, 5, 6):
                                logging.info(msgs["print_finished"])
                                msg = (
                                    f"{msgs['finish_title']}\n"
                                    f"{msgs['finish_file'].format(file=current_file)}\n"
                                    f"{msgs['finish_congrats']}"
                                )
                                await send_telegram_message(msg)
                                is_printing = False
                                
                            last_status = current_status
                            
                    except json.JSONDecodeError:
                        pass

        except websockets.exceptions.ConnectionClosedError as e:
            logging.warning(msgs["connection_closed"].format(error=e))
            await asyncio.sleep(5)
        except Exception as e:
            logging.error(msgs["critical_error"].format(error=e))
            await asyncio.sleep(5)

if __name__ == "__main__":
    if not TG_TOKEN or not TG_CHAT_ID:
        logging.error(msgs["config_error"])
        exit(1)
    asyncio.run(monitor_printer())
