5. Jak tego użyć
   docker compose up --build
   sprawdź Elasticsearch: http://localhost:9201/_cat/indices?v
   wyślij do log-service komendę:
   curl -X POST http://localhost:5000/ingest-file
   to wczyta ./logs/app.log i utworzy index logs-demo.
   podejrzyj w Kibanie → Dev Tools:
   GET logs-demo/_search
   {
   "sort": [
   {"@timestamp": "desc"}
   ]
   }
   możesz też dodać log z zewnątrz:
   curl -X POST http://localhost:5000/logs \
   -H "Content-Type: application/json" \
   -d '{"message":"log from API","level":"DEBUG"}'
   i pobrać:
   curl http://localhost:5000/logs