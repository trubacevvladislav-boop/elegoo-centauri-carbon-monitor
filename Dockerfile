FROM python:3.11-slim

WORKDIR /app

RUN pip install --no-cache-dir websockets httpx

COPY main.py .

CMD ["python", "main.py"]
