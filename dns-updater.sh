#!/bin/bash
mail=<Your mail address>
key=<Your API key>

zone=<Cloudflare zone>
domain=<Domain name>

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

echo "Cloudflare ip is: " $dns_record_ip
echo "Your ip is: " $newIp

if [ $dns_record_ip != $newIp ]
    then
        echo "Your ip has changed"
        echo "Requesting ip change in cloudflare"
        success=$(curl -s -X PUT \
                     -H "X-Auth-Email:$mail" \
                     -H "X-Auth-Key:$key" \
                     -H "Content-Type: application/json" \
                     --data '{"type":"A","name":"'$domain'","content":"'$newIp'"}' \
                     "https://api.cloudflare.com/client/v4/zones/$zone/dns_records/$dns_record_id" \
                     | jq -r '.success')
        echo "Success: " $success
fi
