FROM python:3.12-slim

WORKDIR /app

COPY pyproject.toml .
COPY src/ /app/
COPY supervisord.conf /etc/supervisord.conf

RUN pip install uv && uv pip install --system . && uv pip install --system supervisor

RUN python -c "from transformers import AutoTokenizer, AutoModelForSequenceClassification; AutoTokenizer.from_pretrained('unitary/toxic-bert'); AutoModelForSequenceClassification.from_pretrained('unitary/toxic-bert')"

EXPOSE 5000 50051

CMD ["supervisord", "-c", "/etc/supervisord.conf"]
