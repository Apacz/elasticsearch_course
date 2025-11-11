import os
import time
from datetime import datetime
from flask import Flask, request, jsonify
import requests

app = Flask(__name__)

ES_URL = os.environ.get("ES_URL", "http://localhost:9200")
LOG_FILE = os.environ.get("LOG_FILE", "/logs/app.log")
LOG_INDEX = os.environ.get("LOG_INDEX", "logs-demo")


def ensure_index():
    # prosty mapping z @timestamp
    r = requests.get(f"{ES_URL}/{LOG_INDEX}")
    if r.status_code == 404:
        requests.put(
            f"{ES_URL}/{LOG_INDEX}",
            json={
                "settings": {
                    "number_of_shards": 1,
                    "number_of_replicas": 0
                },
                "mappings": {
                    "properties": {
                        "@timestamp": {"type": "date"},
                        "message": {"type": "text"},
                        "level": {"type": "keyword"},
                        "source": {"type": "keyword"}
                    }
                },
            },
        )


@app.route("/ingest-file", methods=["POST"])
def ingest_file():
    """
    Wczytuje LOG_FILE linia po linii i wrzuca do ES.
    Format pliku może być prosty: "2025-11-11 10:00:01 INFO something happened"
    """
    ensure_index()

    if not os.path.exists(LOG_FILE):
        return jsonify({"error": f"log file {LOG_FILE} not found"}), 404

    bulk_lines = []
    with open(LOG_FILE, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if not line:
                continue

            # bardzo prosty parser: ts level msg
            # spróbujmy rozdzielić po pierwszych 3 polach
            # jeśli się nie uda, zapisujemy całą linię jako message
            ts = datetime.utcnow().isoformat() + "Z"
            level = "INFO"
            msg = line

            parts = line.split(" ", 3)
            if len(parts) >= 4:
                # przykład: 2025-11-11 10:00:01 INFO message...
                ts = f"{parts[0]}T{parts[1]}Z"
                level = parts[2]
                msg = parts[3]

            # bulk meta
            bulk_lines.append('{ "index": { "_index": "' + LOG_INDEX + '" } }')
            bulk_lines.append(
                f'{{"@timestamp":"{ts}","level":"{level}","message":{json_escape(msg)},"source":"file"}}'
            )

    if not bulk_lines:
        return jsonify({"status": "no lines"}), 200

    payload = "\n".join(bulk_lines) + "\n"
    r = requests.post(
        f"{ES_URL}/_bulk?refresh=true",
        data=payload.encode("utf-8"),
        headers={"Content-Type": "application/x-ndjson"},
    )
    return jsonify({"status": "ok", "es": r.json()})


def json_escape(s: str) -> str:
    # bardzo prosty escape do JSON string
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


@app.route("/logs", methods=["POST"])
def add_log():
    """
    Dodaj pojedynczy log (JSON) → ES
    {
      "message": "hello",
      "level": "INFO"
    }
    """
    ensure_index()
    data = request.json or {}
    doc = {
        "@timestamp": datetime.utcnow().isoformat() + "Z",
        "message": data.get("message", ""),
        "level": data.get("level", "INFO"),
        "source": data.get("source", "api"),
    }
    r = requests.post(f"{ES_URL}/{LOG_INDEX}/_doc", json=doc)
    return jsonify(r.json()), r.status_code


@app.route("/logs", methods=["GET"])
def get_logs():
    """
    Pobierz ostatnie 20 logów
    """
    ensure_index()
    q = {
        "size": 20,
        "sort": [{"@timestamp": {"order": "desc"}}],
        "query": {"match_all": {}},
    }
    r = requests.post(f"{ES_URL}/{LOG_INDEX}/_search", json=q)
    return jsonify(r.json())


if __name__ == "__main__":
    # poczekaj chwilę aż ES wstanie, bo startujemy razem z nim
    time.sleep(3)
    ensure_index()
    app.run(host="0.0.0.0", port=5000)
