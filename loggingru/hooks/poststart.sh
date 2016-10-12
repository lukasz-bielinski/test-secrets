###poststart
sleep 60
apk add --update curl bash jq
echo "Starting poststart hook"



  curl -X PUT  -d '{
    "transient": {
      "cluster.routing.allocation.enable": "all"
    }
  }' "http://$ELASTICSEARCH_HOST:9200/_cluster/settings" --connect-timeout 1 -m 2


/bin/bash /hooks/reallocate.sh
exit 0
#
