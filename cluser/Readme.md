2. Jak to pokazać w Kibanie (Dev Tools)
   Po docker compose up -d:
   wejdź do Kibany: http://localhost:5601
   w Dev Tools wklej:
   GET _cluster/health?pretty
   GET _cat/nodes?v
   powinno pokazać 3 nody.
   teraz utwórz index z repliką, żeby było co rozrzucać:
   PUT demo-index
   {
   "settings": {
   "number_of_shards": 3,
   "number_of_replicas": 1
   }
   }
   podejrzyj rozkład:
   GET _cat/shards/demo-index?v
   Tu właśnie będzie ładnie widać:
   3 primaries (p)
   3 replicas (r)
   na różnych node’ach (es01 / es02 / es03)
   To jest moment “o, faktycznie multi-node”.
3. Pokazanie odporności
   Możesz na prezentacji:
   zatrzymać jeden node:
   docker stop es03
   i potem w Dev Tools:
   GET _cluster/health?pretty
   GET _cat/shards/demo-index?v
   Zobaczysz żółty klaster (brakuje replik), ale nadal działa – bo zostają primaries na innych nodach.
   Potem:
   docker start es03
   i chwilę później klaster wróci do zielonego.
   To jest fajny “wow” dla ludzi.