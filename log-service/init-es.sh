#!/usr/bin/env bash
set -e

ES_URL=${ES_URL:-http://localhost:9201}

echo "=== Waiting for Elasticsearch at $ES_URL ..."
# proste czekanie aż ES odpowie
until curl -s "$ES_URL/_cluster/health" >/dev/null 2>&1; do
  printf '.'
  sleep 2
done
echo
echo "Elasticsearch is up."

echo "=== 1) Create ingest pipeline (standardize-fields) ==="
curl -s -X PUT "$ES_URL/_ingest/pipeline/standardize-fields" \
  -H 'Content-Type: application/json' \
  -d '{
    "description": "Rename common fields to standard ones",
    "processors": [
      { "rename": { "field": "name", "target_field": "title", "ignore_missing": true } },
      { "rename": { "field": "text", "target_field": "description", "ignore_missing": true } }
    ]
  }' >/dev/null
echo "Pipeline created."

echo "=== 2) Create index: products ==="
curl -s -X PUT "$ES_URL/products" \
  -H 'Content-Type: application/json' \
  -d '{
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0
    },
    "mappings": {
      "properties": {
        "organisation_id": { "type": "keyword" },
        "title":          { "type": "text" },
        "description":    { "type": "text" },
        "category":       { "type": "keyword" },
        "price":          { "type": "float" },
        "created_at":     { "type": "date" }
      }
    }
  }' >/dev/null
echo "products created."

echo "=== 3) Create index: messages ==="
curl -s -X PUT "$ES_URL/messages" \
  -H 'Content-Type: application/json' \
  -d '{
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0
    },
    "mappings": {
      "properties": {
        "organisation_id": { "type": "keyword" },
        "project_id":      { "type": "keyword" },
        "title":           { "type": "text" },
        "body":            { "type": "text" },
        "created_at":      { "type": "date" }
      }
    }
  }' >/dev/null
echo "messages created."

echo "=== 4) Create index: transactions-2025 ==="
curl -s -X PUT "$ES_URL/transactions-2025" \
  -H 'Content-Type: application/json' \
  -d '{
    "settings": {
      "number_of_shards": 1,
      "number_of_replicas": 0
    },
    "mappings": {
      "properties": {
        "organisation_id": { "type": "keyword" },
        "document_number": { "type": "keyword" },
        "client_name":     { "type": "text" },
        "amount":          { "type": "float" },
        "currency":        { "type": "keyword" },
        "date":            { "type": "date" },
        "description":     { "type": "text" }
      }
    }
  }' >/dev/null
echo "transactions-2025 created."

echo "=== 5) Bulk sample data: products ==="
curl -s -X POST "$ES_URL/_bulk?pipeline=standardize-fields&refresh=true" \
  -H 'Content-Type: application/x-ndjson' <<'NDJSON' >/dev/null
{"index":{"_index":"products","_id":"1"}}
{"organisation_id":"org-1","name":"Robo Connector ERP","text":"Modular ERP, BPM, MES and AI-first workflows.","category":"software","price":199,"created_at":"2025-11-11T10:00:00Z"}
{"index":{"_index":"products","_id":"2"}}
{"organisation_id":"org-1","name":"FlowBeacon AI","text":"AI automation and orchestration layer.","category":"software","price":149,"created_at":"2025-11-11T10:05:00Z"}
{"index":{"_index":"products","_id":"3"}}
{"organisation_id":"org-2","name":"AccordFlow e-sign","text":"E-signature and document workflows.","category":"service","price":49,"created_at":"2025-11-11T10:10:00Z"}
{"index":{"_index":"products","_id":"4"}}
{"organisation_id":"org-1","name":"Atlas OCR","text":"OCR/document parsing connected to Robo Connector.","category":"service","price":59,"created_at":"2025-11-11T10:12:00Z"}
NDJSON
echo "products filled."

echo "=== 6) Bulk sample data: messages ==="
curl -s -X POST "$ES_URL/_bulk?refresh=true" \
  -H 'Content-Type: application/x-ndjson' <<'NDJSON' >/dev/null
{"index":{"_index":"messages","_id":"m1"}}
{"organisation_id":"org-1","project_id":"p1","title":"Zapytanie o fakturę","body":"Klient pyta o duplikat faktury FV/12/2025.","created_at":"2025-11-11T09:00:00Z"}
{"index":{"_index":"messages","_id":"m2"}}
{"organisation_id":"org-1","project_id":"p1","title":"Status dostawy","body":"Dostawa do magazynu centralnego opóźniona.","created_at":"2025-11-11T09:05:00Z"}
{"index":{"_index":"messages","_id":"m3"}}
{"organisation_id":"org-2","project_id":"p7","title":"Nowy kontrakt","body":"Przesyłam draft umowy dla dostawcy z Chin.","created_at":"2025-11-11T09:07:00Z"}
NDJSON
echo "messages filled."

echo "=== 7) Bulk sample data: transactions-2025 ==="
curl -s -X POST "$ES_URL/_bulk?refresh=true" \
  -H 'Content-Type: application/x-ndjson' <<'NDJSON' >/dev/null
{"index":{"_index":"transactions-2025","_id":"t1"}}
{"organisation_id":"org-1","document_number":"FV/12/2025","client_name":"ACME Sp. z o.o.","amount":1200.50,"currency":"PLN","date":"2025-11-10","description":"Faktura za usługi AI"}
{"index":{"_index":"transactions-2025","_id":"t2"}}
{"organisation_id":"org-1","document_number":"FV/13/2025","client_name":"Beta Logistics","amount":880.00,"currency":"PLN","date":"2025-11-11","description":"Dostawa i konfiguracja Robo Assistant"}
{"index":{"_index":"transactions-2025","_id":"t3"}}
{"organisation_id":"org-2","document_number":"FV/77/2025","client_name":"Green School","amount":540.00,"currency":"PLN","date":"2025-11-09","description":"Obsługa stołówki szkolnej"}
NDJSON
echo "transactions filled."

echo "=== 8) Show indices ==="
curl -s "$ES_URL/_cat/indices?v"
echo
echo "Done ✅"
