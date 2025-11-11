#!/usr/bin/env bash
set -e

ES_URL=${ES_URL:-http://localhost:9200}

echo "1) Create ingest pipeline (standardize fields)…"
curl -s -X PUT "$ES_URL/_ingest/pipeline/standardize-fields" \
  -H 'Content-Type: application/json' \
  -d '{
    "description": "Rename common fields to standard ones",
    "processors": [
      { "rename": { "field": "name", "target_field": "title", "ignore_missing": true } },
      { "rename": { "field": "text", "target_field": "description", "ignore_missing": true } }
    ]
  }' | jq .

echo "2) Create index with mapping…"
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
  }' | jq .

echo "3) Bulk sample data…"
curl -s -X POST "$ES_URL/_bulk?pipeline=standardize-fields&refresh=true" \
  -H 'Content-Type: application/x-ndjson' \
  --data-binary @data/products.jsonl | jq .

echo "Done."
