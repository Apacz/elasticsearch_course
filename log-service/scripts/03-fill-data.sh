#!/usr/bin/env bash
ES_URL=${ES_URL:-http://localhost:9201}

echo "Fill products..."
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
echo "products done."

echo "Fill messages..."
curl -s -X POST "$ES_URL/_bulk?refresh=true" \
  -H 'Content-Type: application/x-ndjson' <<'NDJSON' >/dev/null
{"index":{"_index":"messages","_id":"m1"}}
{"organisation_id":"org-1","project_id":"p1","title":"Zapytanie o fakturę","body":"Klient pyta o duplikat faktury FV/12/2025.","created_at":"2025-11-11T09:00:00Z"}
{"index":{"_index":"messages","_id":"m2"}}
{"organisation_id":"org-1","project_id":"p1","title":"Status dostawy","body":"Dostawa do magazynu centralnego opóźniona.","created_at":"2025-11-11T09:05:00Z"}
{"index":{"_index":"messages","_id":"m3"}}
{"organisation_id":"org-2","project_id":"p7","title":"Nowy kontrakt","body":"Przesyłam draft umowy dla dostawcy z Chin.","created_at":"2025-11-11T09:07:00Z"}
NDJSON
echo "messages done."

echo "Fill transactions..."
curl -s -X POST "$ES_URL/_bulk?refresh=true" \
  -H 'Content-Type: application/x-ndjson' <<'NDJSON' >/dev/null
{"index":{"_index":"transactions-2025","_id":"t1"}}
{"organisation_id":"org-1","document_number":"FV/12/2025","client_name":"ACME Sp. z o.o.","amount":1200.50,"currency":"PLN","date":"2025-11-10","description":"Faktura za usługi AI"}
{"index":{"_index":"transactions-2025","_id":"t2"}}
{"organisation_id":"org-1","document_number":"FV/13/2025","client_name":"Beta Logistics","amount":880.00,"currency":"PLN","date":"2025-11-11","description":"Dostawa i konfiguracja Robo Assistant"}
{"index":{"_index":"transactions-2025","_id":"t3"}}
{"organisation_id":"org-2","document_number":"FV/77/2025","client_name":"Green School","amount":540.00,"currency":"PLN","date":"2025-11-09","description":"Obsługa stołówki szkolnej"}
NDJSON
echo "transactions done."

echo "All data loaded ✅"
