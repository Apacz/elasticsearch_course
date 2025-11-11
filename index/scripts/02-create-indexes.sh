#!/usr/bin/env bash
ES_URL=${ES_URL:-http://localhost:9201}

# pipeline
curl -s -X PUT "$ES_URL/_ingest/pipeline/standardize-fields" \
  -H 'Content-Type: application/json' \
  -d '{
    "description": "Rename common fields to standard ones",
    "processors": [
      { "rename": { "field": "name", "target_field": "title", "ignore_missing": true } },
      { "rename": { "field": "text", "target_field": "description", "ignore_missing": true } }
    ]
  }' >/dev/null
echo "pipeline created"

# products
curl -s -X PUT "$ES_URL/products" \
  -H 'Content-Type: application/json' \
  -d '{
    "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
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
echo "products index created"

# messages
curl -s -X PUT "$ES_URL/messages" \
  -H 'Content-Type: application/json' \
  -d '{
    "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
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
echo "messages index created"

# transactions
curl -s -X PUT "$ES_URL/transactions-2025" \
  -H 'Content-Type: application/json' \
  -d '{
    "settings": { "number_of_shards": 1, "number_of_replicas": 0 },
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
echo "transactions-2025 index created"
