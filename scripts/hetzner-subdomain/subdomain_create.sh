#!/bin/bash

# Configuration
API_TOKEN="nrR8iFelW7rCGjbEdRcN27IDneBzZ7ck"
ZONE_ID="dZ8xhcE6qJ3bFtpgjL85jT"
SUBDOMAIN="subdomain"
ROOT_DOMAIN="idrakai.com"
FULL_DOMAIN="$SUBDOMAIN.$ROOT_DOMAIN"
NEW_IP="195.201.6.177"

# Step 1: Get Existing A Record ID
RECORD_ID=$(curl -s -X GET "https://dns.hetzner.com/api/v1/records?zone_id=$ZONE_ID" \
    -H "Auth-API-Token: $API_TOKEN" | jq -r ".records[] | select(.name==\"$SUBDOMAIN\" and .type==\"A\") | .id")

# Step 2: If Record Exists, Update; Otherwise, Create a New One
if [ -n "$RECORD_ID" ]; then
    echo "Updating A record for $FULL_DOMAIN..."
    curl -X PUT "https://dns.hetzner.com/api/v1/records/$RECORD_ID" \
        -H "Auth-API-Token: $API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"value\":\"$NEW_IP\",\"ttl\":3600,\"type\":\"A\",\"name\":\"$SUBDOMAIN\",\"zone_id\":\"$ZONE_ID\"}"
    echo "A record for $FULL_DOMAIN updated successfully to $NEW_IP."
else
    echo "No existing A record found. Creating a new A record for $FULL_DOMAIN..."
    curl -X POST "https://dns.hetzner.com/api/v1/records" \
        -H "Auth-API-Token: $API_TOKEN" \
        -H "Content-Type: application/json" \
        -d "{\"value\":\"$NEW_IP\",\"ttl\":3600,\"type\":\"A\",\"name\":\"$SUBDOMAIN\",\"zone_id\":\"$ZONE_ID\"}"
    echo "New A record for $FULL_DOMAIN created successfully pointing to $NEW_IP."
fi

