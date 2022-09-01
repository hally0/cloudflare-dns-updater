# Cloudflare-dns-updater

This script updates the correct address of one domain through the Cloudflare API. Use your domain as a dynamic domain!

# Usage

Create a .env.json and specify variables

```
{
    "token": "token",
    "zoneId": "zone",
    "domain": "domain"
}
```

## Change the properties variables

- token
  - https://support.cloudflare.com/hc/en-us/articles/200167836-Managing-API-Tokens-and-Keys - Use the edit zone template with read and edit
- zoneId
  - Listen in overview for domain
- domain
  - foo.example.com || example.com

## Run the script

This script is meant to run trough cron jobs. You can use this tool: https://crontab.guru to find a suitable time to run the job.

# Requirements:

- jq
  - https://stedolan.github.io/jq/
- curl
