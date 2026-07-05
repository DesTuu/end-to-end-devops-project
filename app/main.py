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
# Komentarz
