#!/bin/bash
FILE=$LOGFILE
WORKING_DIR=$(pwd)
ENV_FILE=$WORKING_DIR/.env.json

if ! command -v jq &> /dev/null; then
    msg="jq is not installed, please install jq"
    echo $msg >> $FILE
    exit 1
fi


if [ -z "$FILE" ]; then # check if there is an environment - if not export default one
    export LOGFILE=$WORKING_DIR/log.txt
    if [ ! -f "$LOGFILE" ]; then # if logfile does not exit create one.
        touch $LOGFILE
    fi
    FILE=$LOGFILE
fi

if [ ! -f "$ENV_FILE" ]; then
    msg="No environment file found please create a .env.json file specifying mail, key, zone and domain"
    echo $msg >> $FILE
    exit 1
fi



mail=$(jq .mail .env.json)
key=$(jq .key .env.json)
zone=$(jq .zone .env.json)
domain=$(jq .domain .env.json)

newIp=$(curl -s https://api.ipify.org)

zone=$(curl -s -X GET \
     -H "X-Auth-Email:$mail" \
     -H "X-Auth-Key:$key" \
     -H "Content-Type: application/json" \
     "https://api.cloudflare.com/client/v4/zones?name=$zone" | jq -r '.result[0].id')

dns_record=$(curl -s -X GET \
     -H "X-Auth-Email:$mail" \
     -H "X-Auth-Key:$key" \
     -H "Content-Type: application/json" \
     "https://api.cloudflare.com/client/v4/zones/$zone/dns_records?name=$domain")

dns_record_id=$(echo $dns_record | jq -r '.result[0].id')

dns_record_ip=$(echo $dns_record | jq -r '.result[0].content')

echo "Cloudflare ip is: $dns_record_ip" >> $FILE
echo "Your ip is: $newIp " >> $FILE

if [[ "$dns_record_ip" != "$newIp" ]]; then
     echo "Your ip has changed" >> $FILE
     echo "Requesting ip change in cloudflare" >> $FILE
     success=$(curl -s -X PUT \
                    -H "X-Auth-Email:$mail" \
                    -H "X-Auth-Key:$key" \
                    -H "Content-Type: application/json" \
                    --data '{"type":"A","name":"'$domain'","content":"'$newIp'"}' \
                    "https://api.cloudflare.com/client/v4/zones/$zone/dns_records/$dns_record_id" \
                    | jq -r '.success')
     echo "Success: $success" >> $FILE
fi
