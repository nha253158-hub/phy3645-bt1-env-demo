# Demo image: Python 3.12 tren Debian slim + requests, chay app.py
FROM python:3.12-slim

WORKDIR /app

# Cai dependency truoc de tan dung layer cache khi chi sua code
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY app.py .

CMD ["python", "app.py"]
