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

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s | %(levelname)s | %(message)s"
)

def get_error_reason_text(code: int) -> str:
    """Расшифровка кодов ошибок паузы из протокола SDCP"""
    reasons = {
        0: "Ручная пауза (пользователь)",
        1: "Ошибка температуры (перегрев/недогрев)",
        3: "Обрыв филамента (Filament Runout)",
        6: "Замятие филамента (Filament Jam)",
        7: "Ошибка автовыравнивания стола",
        12: "Извлечен USB-накопитель во время печати",
        13: "Ошибка парковки/концевика оси X",
        14: "Ошибка парковки/концевика оси Z",
        24: "Ошибка в G-коде файла",
        33: "Отключен датчик температуры сопла",
        34: "Отключен датчик температуры стола"
    }
    return reasons.get(code, f"Неизвестная ошибка (код {code})")

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
        logging.info("✅ Уведомление успешно отправлено в Telegram")
    except Exception as e:
        logging.error(f"❌ Ошибка отправки в Telegram: {e}")

async def monitor_printer():
    ws_url = f"ws://{PRINTER_IP}:3030/websocket"
    is_printing = False
    current_file = "Неизвестно"
    last_status = None

    while True:
        try:
            logging.info(f"🔄 Подключение к принтеру {ws_url}...")
            async with websockets.connect(ws_url, ping_interval=20, ping_timeout=20) as ws:
                logging.info("✅ Успешно подключено к WebSocket принтера")

                async for message in ws:
                    try:
                        data = json.loads(message)
                        if "Topic" in data and "sdcp/status" in data["Topic"]:
                            print_info = data.get("Status", {}).get("PrintInfo", {})
                            
                            current_status = print_info.get("Status")
                            error_reason = print_info.get("ErrorStatusReason", print_info.get("ErrorNumber", 0))
                            
                            if print_info.get("Filename"):
                                current_file = print_info.get("Filename")

                            # 13 = Активная печать
                            if current_status == 13:
                                is_printing = True

                            # 5 = Pausing, 6 = Paused. Проверяем переход из состояния печати (13)
                            if is_printing and current_status in (5, 6) and last_status == 13:
                                if error_reason == 0:
                                    logging.info("ℹ️ Обнаружена ручная пауза. Уведомление не отправляется.")
                                else:
                                    logging.warning(f"⚠️ Обнаружена пауза из-за ошибки (код: {error_reason})!")
                                    reason_text = get_error_reason_text(error_reason)
                                    msg = (
                                        f"⚠️ <b>Печать приостановлена из-за ошибки!</b>\n"
                                        f"🖨️ Файл: <code>{current_file}</code>\n"
                                        f"🔍 Причина: <b>{reason_text}</b>\n"
                                        f"🛠️ Проверьте принтер и устраните проблему."
                                    )
                                    await send_telegram_message(msg)

                            # 0 или 9 = Завершение печати
                            if is_printing and current_status in (0, 9) and last_status in (13, 5, 6):
                                logging.info("🎉 Печать завершена!")
                                msg = (
                                    f"✅ <b>Печать успешно завершена!</b>\n"
                                    f"🖨️ Файл: <code>{current_file}</code>\n"
                                    f"🎉 Можно забирать деталь."
                                )
                                await send_telegram_message(msg)
                                is_printing = False
                                
                            last_status = current_status
                            
                    except json.JSONDecodeError:
                        pass

        except websockets.exceptions.ConnectionClosedError as e:
            logging.warning(f"⚠️ Соединение закрыто: {e}. Переподключение через 5 сек...")
            await asyncio.sleep(5)
        except Exception as e:
            logging.error(f"❌ Критическая ошибка: {e}. Переподключение через 5 сек...")
            await asyncio.sleep(5)

if __name__ == "__main__":
    if not TG_TOKEN or not TG_CHAT_ID:
        logging.error("Не заданы TG_BOT_TOKEN или TG_CHAT_ID!")
        exit(1)
    asyncio.run(monitor_printer())
