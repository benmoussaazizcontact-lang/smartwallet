FROM python:3.12-slim
WORKDIR /app
RUN useradd --create-home --uid 10001 appuser
COPY requirements-serve.txt .
RUN pip install --no-cache-dir -r requirements-serve.txt
COPY smartwallet_ml ./smartwallet_ml
COPY artifacts ./artifacts
RUN chown -R appuser:appuser /app
USER appuser
ENV PORT=8080
EXPOSE 8080
HEALTHCHECK --interval=30s --timeout=5s --start-period=25s --retries=3 \
  CMD python -c "import os,urllib.request; urllib.request.urlopen('http://127.0.0.1:'+os.environ.get('PORT','8080')+'/health')"
CMD ["python", "-m", "smartwallet_ml.serve"]
