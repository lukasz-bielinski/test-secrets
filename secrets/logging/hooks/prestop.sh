#/bin/bash
###prestop hook
#

#wait until green


##install curl
# installed in poststart
# apk add --update curl bash

echo "Starting prestop hook"
esStatus=$(curl $ELASTICSEARCH_HOST:9200/_cat/health | awk '{print $4}')

echo
echo "initial status at $(date) is $esStatus"
echo ""

if [ -z "$esStatus" ]; then

  echo ""
  echo "There is no ES status"
  echo ""

else

      while [ "$esStatus" != "green" ]
      do
        echo ""
      	echo "Es status at $(date) is $esStatus"
        echo ""
        sleep 10
        esStatus=$(curl $ELASTICSEARCH_HOST:9200/_cat/health | awk '{print $4}')
        echo "try to reallocate UNASSIGNED shards, because $esStatus status"
            ##rerouting UNASSIGNED shards
            IFS=$'\n'
            declare -a dataPodList=($(curl -XGET http://$ELASTICSEARCH_HOST:9200/_cat/nodes |grep ' d ' | awk '{b=$8" "$9" "$10" "$11;   print b}'))
            for NODE in "${dataPodList[@]}"
            do
                 echo ""
                 echo "rerouting shards on node $NODE"
                 echo ""
                 echo ${#dataPodList[@]}
                 NODE1=$(echo $NODE | xargs)
                 NODE=$NODE1
                 IFS=$'\n'
                 for line in $(curl -s $ELASTICSEARCH_HOST:9200/_cat/shards | fgrep UNASSIGNED); do
                   INDEX=$(echo $line | (awk '{print $1}'))
                   SHARD=$(echo $line | (awk '{print $2}'))
                   curl -XPOST $ELASTICSEARCH_HOST:9200/_cluster/reroute -d '{
                      "commands": [
                         {
                             "allocate": {
                                 "index": "'$INDEX'",
                                 "shard": '$SHARD',
                                 "node": "'$NODE'",
                                 "allow_primary": true
                           }
                         }
                     ]
                   }' | jq .
                 done
            done

      done


      curl -X PUT  -d '{
        "transient": {
          "cluster.routing.allocation.enable": "none"
        }
      }' "http://$ELASTICSEARCH_HOST:9200/_cluster/settings" --connect-timeout 1 -m 2


    curl -X POST  "http://$ELASTICSEARCH_HOST:9200/_flush/synced" --connect-timeout 5 -m 60

fi
exit 0
