<?php

require __DIR__ . '/vendor/autoload.php';

use Elastic\Elasticsearch\ClientBuilder;

// 1. build client
$client = ClientBuilder::create()
    ->setHosts(['http://localhost:9200']) // change if needed
    ->build();

// simple params
$indexPattern = 'logs-*'; // e.g. filebeat / elastic-agent / your log index
$searchTerm   = $argv[1] ?? 'error'; // allow: php log_search.php "timeout"

// 2. build query
$params = [
    'index' => $indexPattern,
    'body'  => [
        'size' => 20,  // show 20 newest hits
        'sort' => [
            ['@timestamp' => ['order' => 'desc']]
        ],
        'query' => [
            'bool' => [
                'must' => [
                    [
                        'multi_match' => [
                            'query'  => $searchTerm,
                            'fields' => ['message', 'log', 'error', 'kubernetes.*', 'host.*'],
                            'type'   => 'best_fields'
                        ]
                    ]
                ],
                'filter' => [
                    // last 24h
                    [
                        'range' => [
                            '@timestamp' => [
                                'gte' => 'now-24h',
                                'lte' => 'now'
                            ]
                        ]
                    ]
                ]
            ]
        ],
        // 3. add small aggregation – count logs per level
        'aggs' => [
            'by_level' => [
                'terms' => [
                    'field' => 'log.level.keyword', // adjust to your log field
                    'size'  => 10
                ]
            ]
        ]
    ]
];

try {
    $response = $client->search($params);
} catch (\Exception $e) {
    echo "Search failed: " . $e->getMessage() . PHP_EOL;
    exit(1);
}

// 4. print results
$hits = $response['hits']['hits'] ?? [];
$aggs = $response['aggregations']['by_level']['buckets'] ?? [];

echo "=== Elasticsearch log search ===" . PHP_EOL;
echo "Query: {$searchTerm}" . PHP_EOL;
echo "Found: " . ($response['hits']['total']['value'] ?? count($hits)) . " documents" . PHP_EOL . PHP_EOL;

echo "Top 20 hits:" . PHP_EOL;
foreach ($hits as $hit) {
    $src = $hit['_source'] ?? [];
    $ts  = $src['@timestamp'] ?? '-';
    $lvl = $src['log']['level'] ?? ($src['level'] ?? '-');
    $msg = $src['message'] ?? json_encode($src);
    echo "[$ts] [$lvl] $msg" . PHP_EOL;
}

echo PHP_EOL . "Logs per level (aggregation):" . PHP_EOL;
foreach ($aggs as $bucket) {
    echo "- {$bucket['key']}: {$bucket['doc_count']}" . PHP_EOL;
}
