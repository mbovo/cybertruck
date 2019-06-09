#!/bin/bash

for port in 80 443
do
    node_port=$(kubectl get service -n {{currentAddon.namespace}} {{ currentAddon.vars.releaseName | default('default') }}-nginx-ingress-controller -o=jsonpath="{.spec.ports[?(@.port == ${port})].nodePort}")

    did=$(docker ps | grep ingress-kind-proxy-${port} )
    if [ -z "$did" ]; then 
      docker run -d --name ingress-kind-proxy-${port} \
        --publish {{ currentAddon.vars.publishAddr | default('127.0.0.1') }}:${port}:${port} \
        --link {{ cluster.name }}-control-plane:target \
        alpine/socat -dd \
        tcp-listen:${port},fork,reuseaddr tcp-connect:target:${node_port}
    else
      echo "Proxy for port ${port} already exists: $did"
    fi
done
