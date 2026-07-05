# syntax=docker/dockerfile:1
# Projekt 2. Konteneryzacja małej usługi biznesowej

# ─── Etap 1: Obraz bazowy ────────────────────────────────────────────────────
# python:3.12-slim to oficjalny obraz Python oparty na Debianie Bookworm w wersji
# minimalnej. Znacznie mniejszy niż pełny obraz (python:3.12), nie zawiera
# zbędnych narzędzi deweloperskich, co zmniejsza powierzchnię ataku.
FROM python:3.12-slim AS base

# ─── Etap 2: Zmienne środowiskowe konfiguracyjne ─────────────────────────────
# PYTHONDONTWRITEBYTECODE: wyłącza generowanie plików .pyc (cache bajtkodu)
# PYTHONUNBUFFERED: wyłącza buforowanie stdout/stderr — logi widoczne natychmiast
# PIP_NO_CACHE_DIR: pip nie zachowuje pobieranych pakietów — mniejszy obraz
ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    PIP_DISABLE_PIP_VERSION_CHECK=1

# ─── Etap 3: Użytkownik bez uprawnień administracyjnych ──────────────────────
# Uruchamianie procesu aplikacji jako root wewnątrz kontenera jest złą praktyką.
# Tworzymy dedykowanego użytkownika systemowego.
RUN groupadd --gid 1001 appgroup && \
    useradd --uid 1001 --gid appgroup --shell /bin/bash --no-create-home appuser

# ─── Etap 4: Katalog roboczy ─────────────────────────────────────────────────
WORKDIR /app

# ─── Etap 5: Instalacja zależności Python ────────────────────────────────────
# Kopiowanie samego requirements.txt PRZED skopiowaniem kodu aplikacji.
# Dzięki temu ta kosztowna warstwa jest cachowana — przy kolejnych buildach,
# gdy zmieniamy tylko kod aplikacji (nie zależności), Docker/Podman użyje cache.
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# ─── Etap 6: Kod aplikacji ───────────────────────────────────────────────────
COPY app/ ./app/
COPY templates/ ./templates/
COPY static/ ./static/

# ─── Etap 7: Uprawnienia i właściciel plików ─────────────────────────────────
RUN chown -R appuser:appgroup /app

# ─── Etap 8: Przełączenie na niepriwilegowanego użytkownika ──────────────────
USER appuser

# ─── Etap 9: Port i punkt wejścia ────────────────────────────────────────────
# EXPOSE jest deklaratywne — informuje o porcie, ale nie otwiera go automatycznie.
# Port rzeczywiście otwierany jest przez -p w docker run.
EXPOSE 5000

# Healthcheck: Docker/Podman co 30 sekund sprawdza, czy aplikacja odpowiada.
# Jeśli 3 próby z rzędu się nie powiodą — kontener oznaczany jako "unhealthy".
HEALTHCHECK --interval=30s --timeout=5s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:5000/health')"

# Gunicorn jako serwer WSGI — lepszy od wbudowanego serwera deweloperskiego Flask.
# -w 2: dwa procesy robocze
# -b 0.0.0.0:5000: nasłuchiwanie na wszystkich interfejsach, port 5000
CMD ["gunicorn", "-w", "2", "-b", "0.0.0.0:5000", "app.main:app"]
