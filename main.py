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

MESSAGES = {
    "ru": {
        "connecting": "🔄 Подключение к принтеру {ws_url}...",
        "connected": "✅ Успешно подключено к WebSocket принтера",
        "connection_closed": "⚠️ Соедин closed: {error}. Переподключение через 5 сек...",
        "critical_error": "❌ Критическая ошибка: {error}. Переподключение через 5 сек...",
        "pause_detected": "⚠️ Обнаружена пауза в печати (код: {code})!",
        "print_finished": "🎉 Печать завершена!",
        "telegram_sent": "✅ Уведомление успешно отправлено в Telegram",
        "telegram_error": "❌ Ошибка отправки в Telegram: {error}",
        "config_error": "Не заданы TG_BOT_TOKEN или TG_CHAT_ID!",
        
        "pause_title": "⚠️ <b>Печать приостановлена!</b>",
        "pause_file": "🖨️ Файл: <code>{file}</code>",
        "pause_reason": "🔍 Причина: <b>{reason}</b>",
        "pause_check": "🛠️ Проверьте состояние принтера.",
        
        "finish_title": "✅ <b>Печать успешно завершена!</b>",
        "finish_file": "🖨️ Файл: <code>{file}</code>",
        "finish_congrats": "🎉 Можно забирать деталь.",
        
        "reason_0": "Ручная пауза или команда G-кода (M600)",
        "reason_1": "Ошибка температуры",
        "reason_3": "Обрыв филамента (Filament Runout)",
        "reason_6": "Замятие филамента (Filament Jam)",
        "reason_7": "Ошибка автовыравнивания стола",
        "reason_12": "Извлечен USB-накопитель",
        "reason_13": "Ошибка оси X",
        "reason_14": "Ошибка оси Z",
        "reason_24": "Ошибка в G-коде",
        "reason_33": "Датчик температуры сопла offline",
        "reason_34": "Датчик температуры стола offline",
        "reason_unknown": "Неизвестная причина (код {code})"
    },
    "en": {
        "connecting": "🔄 Connecting to printer {ws_url}...",
        "connected": "✅ Successfully connected to printer WebSocket",
        "connection_closed": "⚠️ Connection closed: {error}. Reconnecting in 5 sec...",
        "critical_error": "❌ Critical error: {error}. Reconnecting in 5 sec...",
        "pause_detected": "⚠️ Print paused (code: {code})!",
        "print_finished": "🎉 Print finished!",
        "telegram_sent": "✅ Notification successfully sent to Telegram",
        "telegram_error": "❌ Telegram send error: {error}",
        "config_error": "TG_BOT_TOKEN or TG_CHAT_ID not set!",
        
        "pause_title": "⚠️ <b>Print paused!</b>",
        "pause_file": "🖨️ File: <code>{file}</code>",
        "pause_reason": "🔍 Reason: <b>{reason}</b>",
        "pause_check": "🛠️ Check the printer status.",
        
        "finish_title": "✅ <b>Print successfully completed!</b>",
        "finish_file": "🖨️ File: <code>{file}</code>",
        "finish_congrats": "🎉 Ready to collect the part.",
        
        "reason_0": "Manual pause or G-code command (M600)",
        "reason_1": "Temperature error",
        "reason_3": "Filament runout",
        "reason_6": "Filament jam",
        "reason_7": "Auto bed leveling failed",
        "reason_12": "USB drive removed",
        "reason_13": "X-axis error",
        "reason_14": "Z-axis error",
        "reason_24": "G-code file error",
        "reason_33": "Nozzle temp sensor offline",
        "reason_34": "Bed temp sensor offline",
        "reason_unknown": "Unknown reason (code {code})"
    }
}

msgs = MESSAGES.get(LANGUAGE, MESSAGES["ru"])

logging.basicConfig(level=logging.INFO, format="%(asctime)s | %(levelname)s | %(message)s")

def get_error_reason_text(code: int) -> str:
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

                            if current_status == 13:
                                is_printing = True

                            # Уведомляем о ЛЮБОЙ паузе (5 или 6), если до этого шла печать (13)
                            if is_printing and current_status in (5, 6) and last_status == 13:
                                logging.warning(msgs["pause_detected"].format(code=error_reason))
                                reason_text = get_error_reason_text(error_reason)
                                msg = (
                                    f"{msgs['pause_title']}\n"
                                    f"{msgs['pause_file'].format(file=current_file)}\n"
                                    f"{msgs['pause_reason'].format(reason=reason_text)}\n"
                                    f"{msgs['pause_check']}"
                                )
                                await send_telegram_message(msg)

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
