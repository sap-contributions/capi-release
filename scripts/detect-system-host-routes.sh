#!/usr/bin/env bash

set -e

api_url=$(cf api | head -n 1 | awk '{ print $3; }')
system_domain="${api_url#https://api.}"
system_hostnames=("api" "proxy" "uaa" "login" "blobstore" "log-cache" "doppler" "log-stream" "credhub" "ssh")
detect_invalid_private_domains=()
for hostname in "${system_hostnames[@]}"; do
  system_component_domain="${hostname}.${system_domain}"
      detect_invalid_private_domains+=( "${system_component_domain}" )
done

echo "Showing hosts, domains, and paths of cf routes using system hosts..." >&2
cf routes | tail -n+3 | awk -v invalid_domains="${detect_invalid_private_domains[*]}" '
{
    split(invalid_domains,list," ")
    for (i=1; i<=NF; i++) {
        f[$i] = i
    }
    for (i in list) {
      if ($(f["domain"]) == list[i]) { print $(f["host"]), $(f["domain"]), $(f["path"]); }
    }
}
' | column -t

