FROM python:3.11-slim
WORKDIR /app

RUN pip install --no-cache-dir websockets "httpx[socks]"

COPY main.py .
CMD ["python", "main.py"]
