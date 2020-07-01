#!/usr/bin/env bash

ROUTES=$(cf curl /v3/routes | jq '.resources[].url')
prefix="https://api."
api_url=$(cf api | head -n 1 | awk '{ print $3; }')
system_domain="${api_url#https://api.}"
system_hostnames=("api" "proxy" "uaa" "login" "blobstore" "log-cache" "doppler" "log-stream" "credhub")
for hostname in "${system_hostnames[@]}"; do
  malicious_route="${hostname}.${system_domain}"
  for route in "${ROUTES[@]}"; do
    if [ "$route" = "$malicious_route" ]; then
      echo "Malicious route found: ${route}"
    fi
  done
done

