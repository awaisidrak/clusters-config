#!/bin/bash

# Config
API_TOKEN="nrR8iFelW7rCGjbEdRcN27IDneBzZ7ck"
DOMAIN="idrakai.com"  # Replace with your domain

# API Call to list zones and extract ID for your domain
ZONE_ID=$(curl -s -X GET "https://dns.hetzner.com/api/v1/zones" \
    -H "Auth-API-Token: $API_TOKEN" | \
    jq -r ".zones[] | select(.name==\"$DOMAIN\") | .id")

if [ -n "$ZONE_ID" ]; then
    echo "Zone ID for $DOMAIN is: $ZONE_ID"
else
    echo "Zone not found for domain: $DOMAIN"
fi


