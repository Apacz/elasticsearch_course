#!/usr/bin/env bash
ES_URL=${ES_URL:-http://localhost:9201}

echo "Cluster health:"
curl -s "$ES_URL/_cluster/health?pretty"

echo
echo "Nodes:"
curl -s "$ES_URL/_cat/nodes?v"

echo
echo "Indices:"
curl -s "$ES_URL/_cat/indices?v"
