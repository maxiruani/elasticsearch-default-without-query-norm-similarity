#!/bin/sh

curl -s -XDELETE "http://localhost:9200/test_index"

curl -s -XPOST "http://localhost:9200/test_index" -d '
{
  "settings": {
    "index": {
      "number_of_shards": 1,
      "number_of_replicas": 0
    },
    "similarity": {
      "defaultWithoutQueryNormSimilarity": {
        "type": "default-without-query-norm-similarity"
      }
    }
  }
}
'

curl -XPUT 'localhost:9200/test_index/test_type/_mapping' -d '
{
  "test_type": {
    "properties": {
      "field1": {
        "type": "string",
        "analyzer": "standard",
        "norms": {
          "enabled": false
        }
      },
      "field2": {
        "type": "string",
        "analyzer": "standard",
        "similarity": "defaultWithoutQueryNormSimilarity",
        "norms": {
          "enabled": false
        }
      }
    }
  }
}
'

curl -s -XPUT "localhost:9200/test_index/test_type/1" -d '
{"field1" : "customer service representative", "field2" : "customer service representative"}
'

curl -s -XPUT "localhost:9200/test_index/test_type/2" -d '
{"field1" : "customer service", "field2" : "customer service"}
'

curl -s -XPUT "localhost:9200/test_index/test_type/3" -d '
{"field1" : "customer support", "field2" : "customer support"}
'

curl -s -XPOST "http://localhost:9200/test_index/_refresh"

echo
echo
echo 'Default: expecting to match all with integer scores'

curl -s "localhost:9200/test_index/test_type/_search?pretty=true" -d '
{
  "explain": false,
  "query": {
    "match": {
      "field1": {
        "query": "customer service representative",
        "operator": "or"
      }
    }
  }
}
'

echo
echo
echo 'Custom: expecting to match all with integer scores'

curl -s "localhost:9200/test_index/test_type/_search?pretty=true" -d '
{
  "explain": false,
  "query": {
    "match": {
      "field2": {
        "query": "customer service representative",
        "operator": "or"
      }
    }
  }
}
'

echo
echo
echo 'Custom: explain highest score'

curl -s "localhost:9200/test_index/test_type/_search?pretty=true" -d '
{
  "explain": true,
  "from": 0,
  "size": 1,
  "query": {
    "match": {
      "field2": {
        "query": "customer service representative",
        "operator": "or"
      }
    }
  }
}
'