#!/bin/bash
FILE=$LOGFILE
WORKING_DIR=$(pwd)
ENV_FILE=$WORKING_DIR/.env.json

if [ -z "$FILE" ]; then # check if there is an environment - if not export default one
    export LOGFILE=$WORKING_DIR/log.txt
    if [ ! -f "$LOGFILE" ]; then # if logfile does not exit create one.
        touch $LOGFILE
    fi
    FILE=$LOGFILE
fi

if ! command -v jq &> /dev/null; then
    msg="jq is not installed, please install jq"
    echo $(date +"%FT%H:%M:%S%z | $msg") >> $FILE
    exit 1
fi

if [ ! -f "$ENV_FILE" ]; then
    msg="No environment file found please create a .env.json file specifying token, zone and domain"
    echo $(date +"%FT%H:%M:%S%z | $msg") >> $FILE
    exit 1
fi

token=$(jq -r .token .env.json)
zoneId=$(jq -r .zoneId .env.json)
domain=$(jq -r .domain .env.json)

newIp=$(curl -s https://api.ipify.org)

dns_record=$(curl -s -X GET \
     -H "Authorization: Bearer $token" \
     -H "Content-Type: application/json" \
     "https://api.cloudflare.com/client/v4/zones/$zoneId/dns_records?name=$domain")

dns_record_id=$(echo $dns_record | jq -r '.result[0].id')

dns_record_ip=$(echo $dns_record | jq -r '.result[0].content')

if [ -z "$dns_record_ip" ] || [[ "$dns_record_ip" == "null" ]]; then
    msg="No ip found from Cloudflare"
    echo $(date +"%FT%H:%M:%S%z | $msg") >> $FILE
    exit 1
fi

echo $(date +"%FT%H:%M:%S%z | Cloudflare ip is: $dns_record_ip") >> $FILE
echo $(date +"%FT%H:%M:%S%z | Your ip is: $newIp") >> $FILE
if [[ "$dns_record_ip" != "$newIp" ]]; then
     echo $(date +"%FT%H:%M:%S%z | Your ip has changed") >> $FILE
     echo $(date +"%FT%H:%M:%S%z | Requesting ip change in cloudflare") >> $FILE
     success=$(curl -s -X PUT \
                    -H "Authorization: Bearer $token" \
                    -H "Content-Type: application/json" \
                    --data '{"type":"A","name":"'$domain'","content":"'$newIp'"}' \
                    "https://api.cloudflare.com/client/v4/zones/$zoneId/dns_records/$dns_record_id" \
                    | jq -r '.success')
     echo $(date +"%FT%H:%M:%S%z | Success: $success") >> $FILE
fi
