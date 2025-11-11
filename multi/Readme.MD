4. Komendy do prezentacji (Kibana → Dev Tools)
1. sprawdź klaster
   GET _cluster/health
   GET _cat/indices?v
   GET products/_search
2. pokaż, że działa wyszukiwanie tekstowe
   GET products/_search
   {
   "query": {
   "multi_match": {
   "query": "workflow",
   "fields": ["title^3", "description"]
   }
   }
   }
3. pokaż filtrowanie po organisation_id – to, co mówiłeś o spójnych polach
   GET products/_search
   {
   "query": {
   "bool": {
   "filter": [
   { "term": { "organisation_id": "org-1" } }
   ],
   "must": [
   { "match": { "description": "AI" } }
   ]
   }
   }
   }
4. pokaż, że można dodać nowy dokument i pipeline go przerobi
   PUT products/_doc/5?pipeline=standardize-fields
   {
   "organisation_id": "org-3",
   "name": "Robo Assistant",
   "text": "Robot OS and device orchestration.",
   "category": "hardware",
   "price": 299.0,
   "created_at": "2025-11-11T10:30:00Z"
   }
   I potem:
   GET products/_source/5
   zobaczysz title zamiast name.
   Jak tego użyć na szkoleniu
   docker compose up -d
   otwierasz Kibana: http://localhost:5601
   (opcjonalnie) na host: bash init-es.sh
   w Kibanie → Dev Tools → pokazujesz wyszukiwanie, filtrowanie, i że pipeline robi standaryzację