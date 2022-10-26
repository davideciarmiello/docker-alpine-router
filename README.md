
# [alpine-router](https://github.com/davideciarmiello/docker-alpine-router)

This is a docker image of Alpine with router redirect features

## Features:
- **Routes and forwarding**: Allow to create a port forwarding rules, allowing the other clients of the vpn, to connect to the ports of the docker host.


## Usage
Here are some example snippets to help you get started creating a container.

### docker-compose (recommended,  [click here for more info](https://docs.linuxserver.io/general/docker-compose))

```yaml
---
version: "2.1"
services:
  alpine-router:
    image: davideciarmi/alpine-router
    cap_add:
      - NET_ADMIN
    privileged: true
    environment:
      #- DEBUG=true	
      #SETTINGS ROUTING - FORWARDING:
      - HOST_ROUTES=192.168.99.0/24  #Create a route to 192.168.99.0/24, because i have a ip 172.17.0.2, and after a VPN, i can't redirect ports to ip 192.168.99.1.
      #redirect ports below to this host, VPNIP:3389 -> 192.168.99.1:3389
      - PORT_FORWARD_HOST=192.168.99.1
      - PORT_FORWARD_PORTS=5900,3389      
    restart: unless-stopped
```



