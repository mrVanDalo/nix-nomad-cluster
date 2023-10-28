#!/usr/bin/env bash

API_TOKEN=$(pass development/hetzner.com/api-token)
export API_TOKEN

curl \
  -H "Authorization: Bearer $API_TOKEN" \
  'https://api.hetzner.cloud/v1/pricing' >pricing_raw.json

# shellcheck disable=SC2002
cat pricing_raw.json |
  jq '.pricing.server_types[] | {name, price : .prices[] | select(.location == "fsn1") | .price_monthly.net }' |
  jq --slurp . >pricing.json
