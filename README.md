# 0. TL;DR — skrótowy opis projektu

Projekt obejmuje pełny proces od środowiska wirtualnego do wdrożenia aplikacji:

- Wirtualizacja środowiska Linux → Debian 13 (VirtualBox)
- Konfiguracja dostępu SSH
- Instalacja i konfiguracja Dockera
- Aplikacja webowa w Pythonie (Flask + HTML)
- Budowa obrazu Docker (docker build)
- Zarządzanie wersjami w Git i GitHub

# 1. Wirtualizacja - workspace

Instalacja Linuxowego **Debiana 13 bez GUI** używając na Windowsie **VirtualBoxa**.
https://www.debian.org/download
Debian stawia na minimializm, jest znakomity do nauki od podstaw.

## 1.1. Brak sudo

Aby zainstalować sudo, trzeba przelogować się na **roota**, gdyż domyślnie logujemy się na stworzone konto usera.
```bash
su -
apt update
apt install sudo
usermod -aG user_name sudo 
```
Aby wyjść z zalogowanego roota należy wcisnąć `Ctrl + D`.

# 2. SSH

Podczas instalacji systemu należało zaznaczyć opcję SSH, aby automatycznie zainstalowało wszystkie potrzebne pakiety do połączenia zdalnego.
Jeśli używamy VirtualBoxa do wirtualizacji należy w ustawieniach sieci zmienić typ sieci na mostkowaną (bridget), aby mieć możliwość połączenia zdalnego przez SSH.

## 2.1. Sprawdzenie SSH oraz IP
```bash
sudo systemctl status ssh
ip addr
```
## 2.2 Połączenie SSH
```bash
ssh user_name@server_ip
```
Po wpisaniu hasła na konto usera powinniśmy być połączeni zdalnie, co znacznie ułatwi ułatwi kopiowanie niektórych bardziej złożonych komend.

# 3. Instalacja dockera

Komendy, które trzeba wpisać, aby zainstalować pomyślnie dockera na Debianie.
```bash
sudo apt update
sudo apt install -y ca-certificates curl gnupg lsb-release

sudo install -m 0755 -d /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

sudo chmod a+r /etc/apt/keyrings/docker.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt update

sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

sudo systemctl enable --now docker

sudo usermod -aG docker $USER

newgrp docker
```
## 3.1. Analiza i weryfikacja

`sudo apt install -y ca-certificates curl gnupg lsb-release`
- ca-certificates - bezpieczne łączenie z HTTPS
- curl - pobieranie plików z internetu
- gnupg - sprawdzanie podpisów cyfrowych
- lsb-release - wykrywanie wersji systemu
- -y - automatyczne odpowiadanie "tak" na pytania
| Cecha                                           | `curl`                        | `wget`                    |
| ----------------------------------------------- | ----------------------------- | ------------------------- |
| Główne zastosowanie                             | Pobieranie i wysyłanie danych | Pobieranie plików         |
| Pobieranie plików                               | ✅ Tak                         | ✅ Tak                     |
| Zapisuje plik automatycznie                     | ❌ Nie (domyślnie)             | ✅ Tak                     |
| Wyświetla dane w terminalu                      | ✅ Tak (domyślnie)             | ❌ Nie                     |
| Praca z API (GET, POST, PUT, DELETE)            | ✅ Bardzo dobra                | ⚠️ Ograniczona            |
| Przekazywanie danych do innych programów (`\|`) | ✅ Bardzo wygodne              | ✅ Możliwe                 |
| Wznawianie pobierania                           | ✅ Tak                         | ✅ Tak                     |
| Pobieranie całych stron WWW                     | ⚠️ Ograniczone                | ✅ Tak (`--mirror`)        |
| Najczęstsze użycie                              | API, skrypty, instalatory     | Pobieranie plików i stron |
***
`sudo install -m 0755 -d /etc/apt/keyrings`
- tworzenie folderu na klucze podpisów
- -d - utwórz katalog
- -m 0755 - ustaw prawa dostępu
| Pakiet/komenda                         | Potrzebne do instalacji Dockera? | Potrzebne do codziennego używania Dockera/Compose? |
| -------------------------------------- | -------------------------------- | -------------------------------------------------- |
| `ca-certificates`                      | ✅ Tak                            | ❌ Nie                                              |
| `curl`                                 | ✅ Tak (pobranie klucza)          | ❌ Nie (czasem przydaje się do testowania API)      |
| `gnupg`                                | ✅ Tak (weryfikacja klucza)       | ❌ Nie                                              |
| `lsb-release`                          | ✅ Tak (wykrycie wersji Debiana)  | ❌ Nie                                              |
| `install -m 0755 -d /etc/apt/keyrings` | ✅ Tak                            | ❌ Nie                                              |
***
`curl -fsSL https://download.docker.com/linux/debian/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg`
- pobieranie oficjalnego klucza dockera i zamiana go na format binarny (docker.gpg), dzięki temu system ufa pakietom dockera
- -fsSL - fail if fail, shortcut (no extra info), Show info if fail, foLLow redirections 
***
`echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/debian $(. /etc/os-release && echo $VERSION_CODENAME) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null` 
- dodawanie oficjalnego repozytorium dockera, od teraz apt pobiera dockera z jego strony
- signed-by - używanie klucza
- tee - zapisanie do pliku

| Komenda                                                      | Czy potrzebna? | Po co?                                                 |
| ------------------------------------------------------------ | -------------- | ------------------------------------------------------ |
| `sudo apt update`                                            | ✅ Tak          | Odświeża listę pakietów.                               |
| `sudo apt install -y ca-certificates curl gnupg lsb-release` | ✅ Tak          | Instaluje narzędzia potrzebne do dodania repozytorium. |
| `sudo install -m 0755 -d /etc/apt/keyrings`                  | ✅ Tak          | Tworzy katalog na klucz GPG.                           |
| `curl ... \| sudo gpg --dearmor ...`                         | ✅ Tak          | Pobiera i zapisuje klucz repozytorium Dockera.         |
| `sudo chmod a+r ...`                                         | ✅ Tak          | Pozwala APT odczytać klucz.                            |
| `echo ... \| sudo tee ...`                                   | ✅ Tak          | Dodaje repozytorium Dockera do APT.                    |
***
`sudo apt install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin`
- docker-ce - silnik dockera
- docker-ce-cli - komendy `docker`
- container.io - kontenery
- docker-buildx-plugin - nowoczesnie budowanie obrazów
- docker-compose-plugin - uruchamianie wielu kontenerów z pliku compose
***
```bash
docker version
docker run --rm hello-world
```
# 4. Konteneryzacja usługi webowej
```bash
# Utwórz katalog projektu
mkdir ~/projekty/projekt-02-kontener
cd ~/projekty/projekt-02-kontener

# Struktura katalogów
mkdir -p app templates static
```

## 4.1. Aplikacja Python/Flask

Utwórz plik `app/main.py`:
```python
"""
Panel wewnętrzny — przykładowa usługa webowa
Projekt 2. Konteneryzacja małej usługi biznesowej
DevOps & Virtualization Lab — WSKZ
"""

import os
import datetime
import platform
import socket
from flask import Flask, render_template, jsonify

app = Flask(__name__, template_folder="../templates", static_folder="../static")

# Konfiguracja przez zmienne środowiskowe
APP_NAME = os.getenv("APP_NAME", "Panel Wewnętrzny")
APP_ENV = os.getenv("APP_ENV", "development")
APP_VERSION = os.getenv("APP_VERSION", "1.0.0")

@app.route("/")
def index():
    info = {
        "app_name": APP_NAME,
        "version": APP_VERSION,
        "environment": APP_ENV,
        "hostname": socket.gethostname(),
        "python_version": platform.python_version(),
        "platform": platform.system(),
        "timestamp": datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"),
    }
    return render_template("index.html", **info)

@app.route("/health")
def health():
    """Endpoint sprawdzenia stanu aplikacji — używany przez load balancery i orchestratory."""
    return jsonify({
        "status": "ok",
        "version": APP_VERSION,
        "environment": APP_ENV,
        "timestamp": datetime.datetime.utcnow().isoformat() + "Z"
    }), 200

@app.route("/api/info")
def api_info():
    """Punkt końcowy API zwracający informacje o środowisku uruchomieniowym."""
    return jsonify({
        "app_name": APP_NAME,
        "version": APP_VERSION,
        "environment": APP_ENV,
        "hostname": socket.gethostname(),
        "python": platform.python_version(),
    })

if __name__ == "__main__":
    port = int(os.getenv("PORT", 5000))
    debug = APP_ENV == "development"
    app.run(host="0.0.0.0", port=port, debug=debug)
```
## 4.2. Utwórz plik `templates/index.html`:
```html
<!DOCTYPE html>
<html lang="pl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{{ app_name }}</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", sans-serif;
            background: #0f172a;
            color: #e2e8f0;
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            padding: 2rem;
        }
        .card {
            background: #1e293b;
            border: 1px solid #334155;
            border-radius: 12px;
            padding: 2.5rem;
            max-width: 640px;
            width: 100%;
        }
        h1 { font-size: 1.5rem; color: #38bdf8; margin-bottom: 0.5rem; }
        .badge {
            display: inline-block;
            padding: 0.2rem 0.7rem;
            border-radius: 99px;
            font-size: 0.75rem;
            font-weight: 600;
            margin-bottom: 1.5rem;
        }
        .badge-dev { background: #854d0e; color: #fef08a; }
        .badge-prod { background: #14532d; color: #86efac; }
        table { width: 100%; border-collapse: collapse; }
        td { padding: 0.6rem 0; border-bottom: 1px solid #334155; }
        td:first-child { color: #94a3b8; width: 40%; }
        td:last-child { font-family: monospace; color: #f1f5f9; }
        .footer { margin-top: 1.5rem; font-size: 0.8rem; color: #64748b; text-align: center; }
    </style>
</head>
<body>
    <div class="card">
        <h1>{{ app_name }}</h1>
        <span class="badge {{ 'badge-prod' if environment == 'production' else 'badge-dev' }}">
            {{ environment }}
        </span>
        <table>
            <tr><td>Wersja</td><td>{{ version }}</td></tr>
            <tr><td>Hostname kontenera</td><td>{{ hostname }}</td></tr>
            <tr><td>Python</td><td>{{ python_version }}</td></tr>
            <tr><td>System (kontener)</td><td>{{ platform }}</td></tr>
            <tr><td>Czas serwera</td><td>{{ timestamp }}</td></tr>
        </table>
        <div class="footer">
            DevOps & Virtualization Lab — WSKZ |
            <a href="/health" style="color:#38bdf8">/health</a> ·
            <a href="/api/info" style="color:#38bdf8">/api/info</a>
        </div>
    </div>
</body>
</html>
```

## 4.3. Utwórz plik `requirements.txt`:
```plaintext
flask==3.1.0
gunicorn==22.0.0
```
## 4.4. Dockerfile: definicja obrazu

Utwórz plik `Dockerfile` w katalogu głównym projektu:
```dockerfile
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
```
## 4.5. Utwórz plik `.dockerignore`:
```plaintext
# .dockerignore — pliki wykluczone z kontekstu budowania
# (analogicznie do .gitignore)

.git
.gitignore
__pycache__
*.pyc
*.pyo
*.pyd
.Python
.env
.env.*
*.env
venv/
.venv/
env/
*.egg-info/
dist/
build/
.pytest_cache/
.mypy_cache/
.coverage
htmlcov/
*.log
README.md
docker-compose*.yml
```
## 4.6. Budowanie obrazu
```bash
# Budowanie obrazu z tagiem
docker build -t firma/panel-wewnetrzny:1.0 .
```
Dodatkowe:
```bash
# Szczegółowy widok procesu budowania (BuildKit output)
docker build --progress=plain -t firma/panel-wewnetrzny:1.0 .

# Analiza zbudowanego obrazu
docker images firma/panel-wewnetrzny

# Szczegółowe informacje o warstwach
docker history firma/panel-wewnetrzny:1.0

# Inspekcja metadanych obrazu
docker inspect firma/panel-wewnetrzny:1.0 | head -80

# Analiza warstw i ich rozmiarów (narzędzie zewnętrzne dive — Arch: pacman -S dive)
# dive firma/panel-wewnetrzny:1.0
```
## 4.7. Uruchamianie i testowanie
```bash
# Uruchomienie w trybie interaktywnym (widać logi, Ctrl+C zatrzymuje)
docker run --rm \
  -p 5000:5000 \
  --name panel-test \
  firma/panel-wewnetrzny:1.0
```
```bash
# Uruchomienie w tle (daemon mode) ze zmiennymi środowiskowymi
docker run -d \
  -p 5000:5000 \
  --name panel-dev \
  -e APP_NAME="Panel Wewnętrzny — Dev" \
  -e APP_ENV="development" \
  -e APP_VERSION="1.0.0" \
  firma/panel-wewnetrzny:1.0
``` 
```bash
# Weryfikacja działania
docker ps
curl http://localhost:5000
curl http://localhost:5000/health
curl http://localhost:5000/api/info | python3 -m json.tool
```
```bash
# Monitorowanie działającego kontenera
docker logs panel-dev           # Logi (stdout/stderr aplikacji)
docker logs -f panel-dev        # Logi w trybie follow (na żywo)
docker stats panel-dev          # Zużycie CPU i RAM w czasie rzeczywistym
docker top panel-dev            # Lista procesów wewnątrz kontenera
docker inspect panel-dev        # Pełne metadane uruchomionego kontenera
```
```bash
# Wejście do uruchomionego kontenera (diagnostyka)
docker exec -it panel-dev bash
docker exec
# Wewnątrz kontenera
whoami                  # powinno zwrócić: appuser (nie root!)
ls -la /app
ps aux                  # lista procesów (tylko gunicorn)
cat /etc/os-release     # wersja systemu w kontenerze
exit
```
## 4.8. Wolumeny: trwałe przechowywanie danych

Kontener jest niemutowalny — wszelkie zmiany wewnątrz znikają po jego usunięciu. Wolumeny rozwiązują ten problem dla danych, które muszą przeżyć cykl życia kontenera (bazy danych, pliki użytkownika, logi).
```bash
# Named volume — zarządzany przez Docker/Podman
docker volume create panel-dane

# Uruchomienie kontenera z podłączonym wolumenem
docker run -d \
  -p 5000:5000 \
  --name panel-prod \
  -v panel-dane:/app/data \
  -e APP_ENV="production" \
  firma/panel-wewnetrzny:1.0

# Informacje o wolumenie (lokalizacja na dysku hosta)
docker volume inspect panel-dane

# Lista wolumenów
docker volume ls

# Bind mount — montowanie katalogu hosta (przydatne przy deweloperowaniu)
docker run -d \
  -p 5001:5000 \
  --name panel-bindmount \
  -v $(pwd)/app:/app/app:ro \
  firma/panel-wewnetrzny:1.0
# :ro = read-only; kontener nie może modyfikować plików hosta
```
## 4.9. Demonstracja warstw i cachowania
```bash
# Pierwsza budowa — wszystkie warstwy od podstaw
time docker build -t firma/panel-wewnetrzny:1.0 .

# Zmiana wyłącznie kodu aplikacji (np. zmień treść w app/main.py)
# — nie dotykamy requirements.txt
echo "# Komentarz" >> app/main.py

# Ponowna budowa — warstwy 1–5 z cache, tylko 6+ przebudowane
time docker build -t firma/panel-wewnetrzny:1.1 .

# Porównanie czasów — różnica wynika z cachowania warstw zależności
```
## 4.10. Kilka przydatnych komend Dockera

* `docker --version` – wersja Dockera
* `docker ps` – uruchomione kontenery
* `docker ps -a` – wszystkie kontenery
* `docker images` – obrazy
* `docker pull nazwa` – pobierz obraz
* `docker run ...` – uruchom kontener
* `docker stop ID` – zatrzymaj kontener
* `docker start ID` – uruchom ponownie
* `docker rm ID` – usuń kontener
* `docker rmi obraz` – usuń obraz
* `docker compose up -d` – uruchom projekt z pliku Compose
* `docker compose down` – zatrzymaj projekt

# 5. Git

- stworzenie repo
- opcjonalne stworzenie pliku .gitignore
- `git init`
- `git add .`
- `git commit -m "nazwa"`

## 5.1 Logowanie do githuba bez GUI

- `sudo apt install gh`
- `gh auth login`

## 5.2 Upload na githuba

- `git remote set-url origin https://github.com/DesTuu/DevOps.py.git`
- `git branch -M main`
- `git push -u origin main`