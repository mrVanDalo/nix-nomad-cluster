#!/usr/bin/env bash

export API_TOKEN=$(pass development/hetzner.com/api-token)

curl \
  -H "Authorization: Bearer $API_TOKEN" \
  'https://api.hetzner.cloud/v1/pricing' >pricing_raw.json

cat pricing_raw.json |
  jq '.pricing.server_types[] | {name, price : .prices[] | select(.location == "fsn1") | .price_monthly.net }' |
  jq --slurp . >pricing.json
